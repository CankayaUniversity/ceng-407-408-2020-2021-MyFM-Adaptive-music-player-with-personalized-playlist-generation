// import 'dart:io';
// import'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// class DatabaseHelper{
//   static final dbName = 'myDb.db';
//   static final dbVer = 1;
//   static
//   DatabaseHelper._privateConstructor();
//   static final DatabaseHelper db =   Database._privateConstructor();
//   static Database _database;
//   Future<Database> get db async{
//     if(_database != null) return db;
//     _database = await _initiateDb();
//     return _database;
//   }
//   _initiateDb() async{
//     Directory dr = await getApplicationDocumentsDirectory();
//     String path = join(dr.path, dbName);
//     await openDatabase(path, version: dbVer, onCreate: _onc)
//   }
//   Future onCreate(Database db, int version){
//       db.query(
//         '''
//         CREATE TABLE $_tableName $columnId INTEGER PRIMARY KEY,
//         '''
//       );
//   }
// }