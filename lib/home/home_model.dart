import 'dart:collection';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextphotos/database/database.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:sqflite/sqflite.dart';

import '../nextcloud/client.dart';

class HomeModel extends ChangeNotifier {
  final List<Photo> _photos = [];

  String _hostname = '';
  String _username = '';
  String _password = '';
  String _authorization = '';

  String get hostname => _hostname;
  String get username => _username;
  String get password => _password;
  String get authorization => _authorization;

  UnmodifiableListView<Photo> get photos => UnmodifiableListView(_photos);

  void setSettings(String hostname, String username, String password, String authorization) {
    _hostname = hostname;
    _username = username;
    _password = password;
    _authorization = authorization;
  }

  Future<List<PhotoListItem>> listFavouritePhotoIds() async {
    final Database db = await Connection.readOnly();

    var result = await db.rawQuery('SELECT id, modified_at FROM photos WHERE favourite = true ORDER BY modified_at DESC');

    return result
        .map((e) => PhotoListItem(id: e['id'] as String, modifiedAt: DateTime.fromMillisecondsSinceEpoch(e['modified_at'] as int)))
        .toList();
  }

  Future<List<PhotoListItem>> listPhotoIds() async {
    final Database db = await Connection.readOnly();

    var result = await db.rawQuery('SELECT id, modified_at FROM photos ORDER BY modified_at DESC');

    return result
        .map((e) => PhotoListItem(id: e['id'] as String, modifiedAt: DateTime.fromMillisecondsSinceEpoch(e['modified_at'] as int)))
        .toList();
  }

  Future setPhotoFavourite(String id, String path, bool favourite) async {
    // First, try to set the favourite inside Nextcloud, as we don't currently support offline favourites
    try {
      var client = NextCloudClient.withCredentials(Uri.parse('https://$_hostname'), _username, _password);
      
      await client.webDav.updateProps(path, {
        WebDavProps.ocFavorite: favourite ? '1' : '0'
      });

    } catch (e, stackTrace) {
      log('Unable to set the favourite prop for the photo $id', error: e, stackTrace: stackTrace);
      throw e;
    }

    // Set the favourite inside our local database too
    final Database db = await Connection.writable();

    await db.rawUpdate('UPDATE photos SET favourite = ? WHERE id = ?', [favourite ? 1 : 0, id]);
  }

  Future<Photo> getPhoto(String id) async {
    final Database db = await Connection.readOnly();

    try {
      var result = await db.query('photos', where: 'id = ?', whereArgs: [id]);

      return Photo(
        id: result.first['id'] as String,
        favourite: result.first['favourite'] == 1 ? true : false,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(result.first['modified_at'] as int),
        name: result.first['name'] as String,
        path: result.first['path'] as String,
        scannedAt: DateTime.fromMillisecondsSinceEpoch(result.first['scanned_at'] as int),
      );
    } catch (e, stackTrace) {
      log('Unable to get the photo', error: e, stackTrace: stackTrace);

      throw e;
    }
  }

  Future<void> clearOldPhotos(DateTime scannedAt) async {
    final Database db = await Connection.writable();

    var count = await db.delete('photos', where: 'scanned_at < ?', whereArgs: [scannedAt.millisecondsSinceEpoch]);

    log('Cleared up $count old photos');
  }

  Future<void> insertPhotos(Iterable<Photo> photos) async {
    final Database db = await Connection.writable();

    Batch batch = db.batch();

    for (var photo in photos) {
      batch.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);

    log('Inserted ${photos.length} photos');
  }

  void refreshPhotos(Function(String message) onMessage) async {
    var otherClient = CustomClient('https://$_hostname', _username, _password);

    var propFilters = [
      MapEntry(WebDavProps.davContentType, 'image/png'),
      MapEntry(WebDavProps.davContentType, 'image/jpeg'),
      MapEntry(WebDavProps.davContentType, 'image/heic'),
    ];

    var props = {
      'oc:fileid',
      WebDavProps.davLastModified,
      WebDavProps.ocFavorite,
    };

    var hasMore = true;
    var limit = 1000;
    var offset = 0;
    var total = 0;

    var scannedAt = DateTime.now();

    onMessage('Synchronising photos...');

    while (hasMore) {
      var start = DateTime.now().millisecondsSinceEpoch;

      var result = await otherClient.search('/files/$_username', limit, offset, propFilters, props: props);

      var totalTime = DateTime.now().millisecondsSinceEpoch - start;

      log('Got search result in ${totalTime}ms');

      var photos = result.map((f) => Photo(
          id: f.getOtherProp('fileid', 'http://owncloud.org/ns')!,
          favourite: f.favorite,
          modifiedAt: f.lastModified,
          name: f.name,
          path: f.path,
          scannedAt: scannedAt));

      await insertPhotos(photos);

      offset = offset + limit;
      total = total + photos.length;

      // if (result.length < limit) {
        hasMore = false;
      // }

      onMessage('Synchronised $total photos');
    }

    var totalTime = DateTime.now().difference(scannedAt);

    onMessage('Finished synchronising $total photos in ${totalTime.inSeconds} seconds');
    log('Clearing old items');

    await clearOldPhotos(scannedAt);

    notifyListeners();
  }
}
