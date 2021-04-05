import 'package:sqflite/sqflite.dart';

class Connection {
  static Future<Database> readOnly() async {
    return openDatabase('nextphotos.db', readOnly: true, singleInstance: false);
  }

  static Future<Database> writable() async {
    return openDatabase('nextphotos.db');
  }

  void migrate() async {
    openDatabase('nextphotos.db', version: 1, onCreate: (db, version) async {
      final migrations = [
        'CREATE TABLE photos (id TEXT PRIMARY KEY, name TEXT, path TEXT, modified_at INTEGER, scanned_at INTEGER)',
        'ALTER TABLE photos ADD COLUMN lat DOUBLE',
        'ALTER TABLE photos ADD COLUMN lng DOUBLE',
        'CREATE TABLE locations (lat DOUBLE, lng DOUBLE, name TEXT, country TEXT)',
        'DROP TABLE locations',
        'CREATE TABLE locations (id INTEGER PRIMARY KEY, lat DOUBLE, lng DOUBLE, name TEXT, country TEXT)',
        'CREATE UNIQUE INDEX uk_locations_lat_lng ON locations (lat, lng)',
        'ALTER TABLE photos ADD COLUMN location_id INTEGER',
      ];

      for (var migration in migrations) {
        await db.execute(migration);
      }
    });
  }
}
