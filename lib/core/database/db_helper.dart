import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('coffee_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS transaction_items');
        await db.execute('DROP TABLE IF EXISTS transactions');
        await db.execute('DROP TABLE IF EXISTS products');
        await db.execute('DROP TABLE IF EXISTS categories');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // 1. Table Categories
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType
      )
    ''');

    // 2. Table Products
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        category_id $integerType,
        name $textType,
        price $integerType,
        is_available INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // 3. Table Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        transaction_code $textType,
        total_amount $integerType,
        payment_method $textType,
        created_at $textType
      )
    ''');

    // 4. Table Transaction Items (Detail Transaksi)
    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transaction_id $integerType,
        product_name $textType,
        price $integerType,
        qty $integerType,
        subtotal $integerType,
        notes TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id)
      )
    ''');
    
    // Insert Initial Data (Kategori Default)
    await db.insert('categories', {'name': 'Coffee'});
    await db.insert('categories', {'name': 'Non-Coffee'});
    await db.insert('categories', {'name': 'Snack'});
    
    // Insert Dummy Products agar UI tidak kosong
    await db.insert('products', {
      'category_id': 1,
      'name': 'Kopi Susu Gula Aren',
      'price': 18000,
      'is_available': 1
    });
    await db.insert('products', {
      'category_id': 1,
      'name': 'Americano Ice',
      'price': 15000,
      'is_available': 1
    });
    await db.insert('products', {
      'category_id': 2,
      'name': 'Matcha Latte',
      'price': 22000,
      'is_available': 1
    });
    await db.insert('products', {
      'category_id': 3,
      'name': 'Kentang Goreng',
      'price': 12000,
      'is_available': 1
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
