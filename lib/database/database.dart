import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration_plan/migration/sql.dart';
import 'package:sqflite_migration_plan/sqflite_migration_plan.dart';

class Connection {
  static Future<Database> readOnly() async {
    return openDatabase('nextphotos.db', readOnly: true, singleInstance: false);
  }

  static Future<Database> writable() async {
    return openDatabase('nextphotos.db');
  }

  void migrate() async {
    MigrationPlan myMigrationPlan = MigrationPlan({
      2: [
        SqlMigration('CREATE TABLE photos (id TEXT PRIMARY KEY, name TEXT, path TEXT, favourite INTEGER DEFAULT false, modified_at INTEGER, scanned_at INTEGER)', reverseSql: 'DROP TABLE photos')
      ],
      3: [
        SqlMigration('ALTER TABLE photos ADD COLUMN download_path TEXT NULL')
      ],
      4: [
        SqlMigration('CREATE TABLE locations (id INTEGER PRIMARY KEY, name TEXT NOT NULL, lat REAL NOT NULL, lng REAL NOT NULL)')
      ],
      5: [
        SqlMigration('ALTER TABLE photos ADD COLUMN location_id INTEGER NULL REFERENCES locations (id) ON DELETE SET NULL')
      ],
      6: [
        SqlMigration('ALTER TABLE photos ADD COLUMN lat REAL NULL'),
        SqlMigration('ALTER TABLE photos ADD COLUMN lng REAL NULL'),
      ]
    });

    await openDatabase('nextphotos.db',
        version: 6,
        onUpgrade: myMigrationPlan,
        onCreate: myMigrationPlan,
        onDowngrade: myMigrationPlan
    );

    log('Finished migrating database');
  }
}
