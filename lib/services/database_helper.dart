import 'package:firebase_core/firebase_core.dart';
import 'package:rememberme/services/authService.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../model/user_data.dart';
import '/model/image_data.dart';
import 'package:sqflite_common/sqlite_api.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static DatabaseFactory? _databaseFactory;
  static Database? _database;

  // Firebase initialization
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<User?> getUserData() async {
    final db = await database;
    final localuser = await AuthService().getCurrentEmailFromSharedPreferences();
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [localuser],
    );
    ;
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    _databaseFactory = databaseFactoryFfi;
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'image_sync.db');

    // Initialize the databaseFactory if not already initialized
    if (_databaseFactory == null) {
      sqfliteFfiInit();
    }

    final database = await openDatabase(dbPath, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE images(
          id TEXT PRIMARY KEY,
          userId TEXT,
          title TEXT,
          description TEXT,
          category TEXT,
          imageData BLOB
        )
      ''');

      await db.execute('''
        CREATE TABLE users(
          id TEXT PRIMARY KEY,
          email TEXT,
          password TEXT,
          lastSyncTime TEXT,
          pin TEXT
        )
      ''');
    });
    // Check if the 'pin' column exists in the users table
    final columnList = await database.rawQuery('PRAGMA table_info(users)');
    final columnNames = columnList.map((column) => column['name']).toList();
    if (!columnNames.contains('pin')) {
      await database.execute('ALTER TABLE users ADD COLUMN pin TEXT');
    }
    final columnListI = await database.rawQuery('PRAGMA table_info(images)');
    final columnNamesI = columnListI.map((column) => column['name']).toList();
    if (!columnNamesI.contains('category')) {
      await database.execute('ALTER TABLE images ADD COLUMN category TEXT');
    }

    return database;
  }

  Future<void> insertUserData(List<User> users) async {
    final db = await database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> updateUserData(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<ImageData>> getImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('images');
    return List.generate(
      maps.length,
      (index) => ImageData.fromDatabase(maps[index]),
    );
  }

  Future<void> insertImage(ImageData image) async {
    final db = await database;
    await db.insert(
      'images',
      image.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("image uploaded");
  }

  Future<void> updateImage(ImageData image) async {
    final db = await database;
    await db.update(
      'images',
      image.toDatabase(),
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }

  Future<void> deleteImage(String imageId) async {
    final db = await database;
    await db.delete(
      'images',
      where: 'id = ?',
      whereArgs: [imageId],
    );
  }

  Future<List<ImageData>> getUserImages(String? userId) async {
    String userID = await AuthService().getUserIdFromSharedPreferences();
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'images',
      where: 'userId = ?',
      whereArgs: [userID],
    );
    return List.generate(
      maps.length,
      (index) => ImageData.fromDatabase(maps[index]),
    );
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> setUserPin(String userId, String pin) async {
    final db = await database;
    await db.update(
      'users',
      {'pin': pin},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
