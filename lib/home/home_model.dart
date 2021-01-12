import 'dart:collection';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextphotos/database/database.dart';
import 'package:nextphotos/database/photo.dart';
import 'package:nextphotos/nextcloud/map_photo.dart';
import 'package:nextphotos/search/search_location.dart';
import 'package:quiver/collection.dart';
import 'package:sqflite/sqflite.dart';

import '../client.dart';

class HomeModel extends ChangeNotifier {
  final List<Photo> _photos = [];

  UnmodifiableListView<Photo> get photos => UnmodifiableListView(_photos);

  Future<List<SearchLocation>> listLocations() async {
    final Database db = await Connection.database;

    var results = await db.rawQuery(
        'SELECT COUNT(*) AS count, l.name, l.lat, l.lng FROM locations l LEFT JOIN photos p ON l.id = p.location_id GROUP BY l.id');

    return results.map((e) {
      return SearchLocation(e['count'], e['name'], e['lat'], e['lng']);
    }).toList();
  }

  Future<List<String>> listPhotoIds() async {
    final Database db = await Connection.database;

    var result = await db.rawQuery('SELECT id FROM photos ORDER BY modified_at DESC');

    return result.map((e) => e['id'] as String).toList();
  }

  Future<Photo> getPhoto(String id) async {
    final Database db = await Connection.database;

    var result = await db.query('photos', where: 'id = ?', whereArgs: [id]);

    return Photo(
      id: result.first['id'],
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(result.first['modified_at']),
      name: result.first['name'],
      path: result.first['path'],
      scannedAt: DateTime.fromMillisecondsSinceEpoch(result.first['scanned_at']),
    );
  }

  Future<void> clearOldPhotos(DateTime scannedAt) async {
    final Database db = await Connection.database;

    var count = await db.delete('photos', where: 'scanned_at < ?', whereArgs: [scannedAt.millisecondsSinceEpoch]);

    log('Cleared up $count old photos');
  }

  Future<void> insertPhotos(Iterable<Photo> photos) async {
    final Database db = await Connection.database;

    Batch batch = db.batch();

    for (var photo in photos) {
      batch.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);

    log('Inserted ${photos.length} photos');
  }

  Future<void> updatePhotosWithLocations(Iterable<NextcloudMapPhoto> photos) async {
    final Database db = await Connection.database;

    Batch batch = db.batch();

    var locations = Multimap<String, int>();

    for (var photo in photos) {
      var approxLat = photo.lat.toStringAsFixed(2);
      var approxLng = photo.lng.toStringAsFixed(2);

      locations.add('$approxLat,$approxLng', photo.id);

      // TODO: Stop using path as an identifier and use fileId everywhere
      batch.rawUpdate('UPDATE photos SET lat = ?, lng = ? WHERE id = ?', [photo.lat, photo.lng, photo.id]);
      // TODO: Fix this inconsistent path bollocks
    }

    await batch.commit(noResult: true);

    log('Updated ${photos.length} photos with locations');

    locations.forEachKey((key, values) async {
      var coordinates = key.split(',');

      var approxLat = num.parse(coordinates[0]);
      var approxLng = num.parse(coordinates[1]);

      var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(approxLat, approxLng));

      for (var address in addresses) {
        if (address.locality != null) {
          db.rawInsert('INSERT OR IGNORE INTO locations (lat, lng, name, country) VALUES (?, ?, ?, ?)',
              [address.coordinates.latitude, address.coordinates.longitude, address.locality, address.countryCode]);

          var result = await db.rawQuery('SELECT id FROM locations WHERE lat = ? AND lng = ?',
              [address.coordinates.latitude, address.coordinates.longitude]);

          var photoParameters = List<String>.generate(photos.length, (index) => '?').join(', ');

          await db.rawUpdate(
              'UPDATE photos SET location_id = ? WHERE id IN ($photoParameters)', [result.first['id'], ...values]);

          break;
        }
      }
    });
  }

  void refreshPhotos(hostname, username, password) async {
    var otherClient = CustomClient('https://$hostname', username, password);

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
    var limit = 250;
    var offset = 0;
    var total = 0;

    var scannedAt = DateTime.now();

    while (hasMore) {
      log('Loading offset $offset');

      var result = await otherClient.search('/files/$username', limit, offset, propFilters, props: props);

      var photos = result.map((f) => Photo(
          id: f.getOtherProp('fileid', 'http://owncloud.org/ns'),
          modifiedAt: f.lastModified,
          name: f.name,
          path: f.path,
          scannedAt: scannedAt));

      await insertPhotos(photos);

      offset = offset + limit;
      total = total + photos.length;

      // _photos.addAll(photos);

      notifyListeners();

      if (result.length < limit) {
        hasMore = false;
      }
    }

    log('Loading complete with ${total} items');
    log('Clearing old items');

    await clearOldPhotos(scannedAt);

    notifyListeners();

    // Load the map data for any photos we have
    var a = await otherClient.photos();

    await updatePhotosWithLocations(a);
  }
}