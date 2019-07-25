import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class DatabaseProvider {
  DatabaseProvider(){
    database;
  }

  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;

    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "GoPointRoutes.db");
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
          await db.execute("CREATE TABLE routes ("
              "name TEXT PRIMARY KEY,"
              "originLatitude REAL,"
              "originLongitude REAL,"
              "destinyLatitude REAL,"
              "destinyLongitude REAL"
              ")");
          await db.execute("CREATE TABLE points ("
              "name TEXT PRIMARY KEY,"
              "latitude REAL,"
              "longitude REAL"
              ")");
        });
  }
}