import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder_offline/geocoder_offline.dart';
import 'package:http/http.dart' as http;
import 'package:nextcloud/nextcloud.dart';
import 'package:nextphotos/database/database.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/nextcloud/client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sqflite/sqflite.dart';

class HomeModel extends ChangeNotifier {
  String _hostname = '';
  String _username = '';
  String _password = '';
  String _authorization = '';

  String get hostname => _hostname;
  String get username => _username;
  String get password => _password;
  String get authorization => _authorization;

  void setSettings(String hostname, String username, String password, String authorization) {
    _hostname = hostname;
    _username = username;
    _password = password;
    _authorization = authorization;
  }

  static Photo _mapToPhoto(Map<String, Object?> e) {
    return Photo(
      id: e['id'] as String,
      downloadPath: e['download_path'] as String?,
      favourite: e['favourite'] == 1 ? true : false,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(e['modified_at'] as int),
      name: e['name'] as String,
      path: e['path'] as String,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(e['scanned_at'] as int),
    );
  }

  Future<List<Photo>> listFavouritePhotoIds() async {
    final Database db = await Connection.readOnly();

    var result = await db.query('photos', where: 'favourite = ?', whereArgs: [1], orderBy: 'modified_at DESC');

    return result
      .map((e) => _mapToPhoto(e))
      .toList(growable: false);
  }

  Future<List<Photo>> listPhotoIds() async {
    final Database db = await Connection.readOnly();

    var result = await db.query('photos', orderBy: 'modified_at DESC');

    return result
        .map((e) => _mapToPhoto(e))
        .toList(growable: false);
  }

  Future setPhotoDownloadPath(String id, String? downloadPath) async {
    final Database db = await Connection.writable();

    await db.update('photos', {
      'download_path': downloadPath
    }, where: 'id = ?', whereArgs: [id]);

    notifyListeners();
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

    notifyListeners();
  }

  Future<Photo> getPhoto(String id) async {
    final Database db = await Connection.readOnly();

    try {
      var result = await db.query('photos', where: 'id = ?', whereArgs: [id]);

      return _mapToPhoto(result.first);
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

      if (result.length < limit) {
        hasMore = false;
      }

      notifyListeners();
    }

    var totalTime = DateTime.now().difference(scannedAt);

    onMessage('Finished synchronising $total photos in ${totalTime.inSeconds} seconds');
    log('Clearing old items');

    await clearOldPhotos(scannedAt);

    notifyListeners();

    // Sync locations, and match them up to any photos we have
    await syncLocations(otherClient);

    // Finally, sync all the face recognition people and photos
    try {
      await syncPeople(otherClient);
    } catch (e, stackTrace) {
      log('Unable to sync people', error: e, stackTrace: stackTrace);
    }

    log('Finished syncing');
  }

  Future syncPeople(CustomClient otherClient) async {
    var people = await otherClient.facesPeople();

    final Database db = await Connection.writable();

    var batch = db.batch();

    var peopleFutures = people.map((person) async {
      var id = int.parse(Uri(path: person.thumbUrl).pathSegments[3]);

      batch.insert('people', {
        'id': id,
        'name': person.name,
        'thumb_url': 'https://$_hostname${person.thumbUrl}'
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      var photos = await otherClient.facesPeoplePhotos(person.name);
      for (var photo in photos) {
        var photoId = Uri.parse(photo.thumbUrl).queryParameters['fileId'];

        batch.insert('people_photos', {
          'person_id': id,
          'photo_id': photoId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      log('Inserted face for ${person.name}');
    });

    await Future.wait(peopleFutures);

    await batch.commit();
  }

  Future doMapStuff() async {
    var otherClient = CustomClient('https://$_hostname', _username, _password);

    // Load the map data for any photos we have
    await syncLocations(otherClient);
  }

  Future<File> _downloadFile(String url, String filename) async {
    String dir = (await getApplicationSupportDirectory()).path;
    File file = new File('$dir/$filename');
    if (file.existsSync()) {
      return file;
    }

    http.Client client = new http.Client();
    var req = await client.get(Uri.parse(url));
    var bytes = req.bodyBytes;
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> syncLocations(CustomClient otherClient) async {
    final Database db = await Connection.writable();

    var download = await _downloadFile('https://download.geonames.org/export/dump/cities500.zip', 'cities500.zip');

    log('Geonames have been downloaded');

    var extracted = File(download.parent.path + '/cities500.txt');
    if (!extracted.existsSync()) {
      var archive = ZipDecoder().decodeBytes(download.readAsBytesSync());

      // Extract the contents of the Zip archive to disk.
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(download.parent.path + '/' + filename)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          log('A directory was encountered in the Geonames ZIP, but this wasn\'t expected');
        }
      }
    }

    log('Geonames have been extracted');

    var cities = 'geonameid\tname\tasciiname\talternatenames\tlatitude\tlongitude\tfeature class\tfeature code\tcountry code\tcc2\tadmin1 code\tadmin2 code\tadmin3 code\tadmin4 code\tpopulation\televation\tdem\ttimezone\tmodification date\n' + extracted.readAsStringSync();

    var geocoder = GeocodeData(
        cities,
        'name',
        'country code',
        'latitude',
        'longitude',
        fieldDelimiter: '\t',
        eol: '\n'
    );

    log('Geocoder has been initialized');

    Batch batch = db.batch();

    var photos = await otherClient.photos();

    for (var photo in photos) {
      var locations = geocoder.search(photo.lat, photo.lng);

      var location = locations.first.location;

      var id = Sqflite.firstIntValue(await db.rawQuery('SELECT id FROM locations WHERE lat = ? AND lng = ?', [location.latitude, location.longitude]));
      if (id == null) {
        id = await db.insert('locations', {
          'lat': location.latitude,
          'lng': location.longitude,
          'name': location.featureName,
          'state': location.state
        });
      } else {
        await db.update('locations', {
          'name': location.featureName,
          'state': location.state
        }, where: 'id = ?', whereArgs: [id]);
      }

      batch.update('photos', {
        'location_id': id,
        'lat': photo.lat,
        'lng': photo.lng
      }, where: 'id = ?', whereArgs: [photo.id]);
    }

    await batch.commit(noResult: true);

    // Remove locations with no photos
    var deleted = await db.rawDelete('DELETE FROM locations WHERE id NOT IN (SELECT DISTINCT location_id FROM photos WHERE location_id IS NOT NULL)');

    log('Removed $deleted old locations');

    log('Updated ${photos.length} photos with locations');
  }

  Future<List<Location>> listLocations() async {
    final Database db = await Connection.readOnly();

    var results = await db.rawQuery('SELECT MAX(modified_at), id, name, state, lat, lng, p_id, COUNT(modified_at) AS number_of_photos FROM (SELECT l.id, l.name, l.state, l.lat, l.lng, p.id AS p_id, p.modified_at FROM locations l LEFT JOIN photos p ON p.location_id = l.id) GROUP BY id ORDER BY state, name');

    return (results)
        .map((e) => Location(id: e['id'] as int, name: e['name'] as String, state: e['state'] as String?, lat: e['lat'] as double, lng: e['lng'] as double, coverPhoto: e['p_id'] as String, numberOfPhotos: e['number_of_photos'] as int))
        .toList(growable: false);
  }

  Future<List<Person>> listPeople() async {
    final Database db = await Connection.readOnly();

    var results = await db.rawQuery('SELECT id, name, thumb_url FROM people ORDER BY name');

    return (results)
        .map((e) => Person(id: e['id'] as int, name: e['name'] as String, thumbUrl: e['thumb_url'] as String))
        .toList(growable: false);
  }

  Future<LocationGet> getLocation(int id) async {
    final Database db = await Connection.readOnly();

    var photos = (await db.query('photos', where: 'location_id = ?', whereArgs: [id]))
      .map((e) => _mapToPhoto(e))
      .toList(growable: false);

    return (await db.query('locations', where: 'id = ?', whereArgs: [id]))
        .map((e) => LocationGet(id: e['id'] as int, name: e['name'] as String, photos: photos))
        .first;
  }

  Future<PersonGet> getPerson(int id) async {
    final Database db = await Connection.readOnly();

    var photos = (await db.query('photos', where: 'id IN (SELECT photo_id FROM people_photos WHERE person_id = ?)', whereArgs: [id], orderBy: 'modified_at DESC'))
        .map((e) => _mapToPhoto(e))
        .toList(growable: false);

    return (await db.query('people', where: 'id = ?', whereArgs: [id]))
        .map((e) => PersonGet(id: e['id'] as int, name: e['name'] as String, photos: photos))
        .first;
  }

  Future uploadPhoto(AssetEntity item) async {
    try {
      var file = await item.file;
      if (file == null) {
        return;
      }

      var name = await item.titleAsync;
      var path = '/test/$name';
      var time = '${(item.modifiedDateTime.millisecondsSinceEpoch / 1000).round()}';

      log('About to upload $name');

      // var client = NextCloudClient.withCredentials(Uri.parse('https://$_hostname'), _username, _password, defaultHeaders: {
      //   'X-OC-Mtime': time
      // });
      //
      // await client.webDav.upload(await file.readAsBytes(), path);

      log('Finished uploading $name');
    } catch (e, stackTrace) {
      log('Unable to upload the photo ${item.id}', error: e, stackTrace: stackTrace);
      throw e;
    }
  }
}
