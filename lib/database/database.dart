import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration/sqflite_migration.dart';

class Connection {
  static Future<Database> database;

  void connect() async {
    if (database == null) {
      final initialScript = [
        'CREATE TABLE photos (id TEXT PRIMARY KEY, name TEXT, path TEXT, modified_at INTEGER, scanned_at INTEGER)',
      ];

      final migrations = [
        'ALTER TABLE photos ADD COLUMN lat DOUBLE',
        'ALTER TABLE photos ADD COLUMN lng DOUBLE',
        'CREATE TABLE locations (lat DOUBLE, lng DOUBLE, name TEXT, country TEXT)',
        'DROP TABLE locations',
        'CREATE TABLE locations (id INTEGER PRIMARY KEY, lat DOUBLE, lng DOUBLE, name TEXT, country TEXT)',
        'CREATE UNIQUE INDEX uk_locations_lat_lng ON locations (lat, lng)',
        'ALTER TABLE photos ADD COLUMN location_id INTEGER',
      ];

      final config = MigrationConfig(initializationScript: initialScript, migrationScripts: migrations);
      final path = join(await getDatabasesPath(), 'nextphotos.db');

      database = openDatabaseWithMigration(path, config);
    }

    // database = openDatabase(
    //     join(await getDatabasesPath(), 'nextphotos.db'),
    //     onCreate: (db, version) {
    //       return db.execute(
    //           'CREATE TABLE photos (id TEXT PRIMARY KEY, name TEXT, path TEXT, modified_at INTEGER, scanned_at INTEGER)');
    //     },
    //     onUpgrade: (db, oldVersion, newVersion) {
    //       db.execute('ALTER TABLE photos ADD COLUMN IF NOT EXISTS ')
    //     },
    //     version: 1
    // );
  }
}
