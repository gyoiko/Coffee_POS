import '../../core/database/db_helper.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- CATEGORIES ---

  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  // --- PRODUCTS ---

  Future<List<ProductModel>> getAllProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}