import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Simpan Transaksi & Detail Items dalam 1 DB Transaction (Atomic)
  Future<int> createTransaction(
    TransactionModel transaction,
    List<TransactionItemModel> items,
  ) async {
    final db = await _dbHelper.database;
    int transactionId = 0;

    await db.transaction((txn) async {
      // 1. Insert header transaksi
      transactionId = await txn.insert('transactions', transaction.toMap());

      // 2. Insert tiap item ke transaction_items
      for (var item in items) {
        await txn.insert(
          'transaction_items',
          item.toMap(assignedTransactionId: transactionId),
        );
      }
    });

    return transactionId;
  }

  /// Ambil Rekapan (Total Omset, Total Transaksi, Cash vs QRIS) berdasarkan pattern (Harian/Bulanan)
  Future<Map<String, dynamic>> getSummary(String pattern) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(id) as total_transactions,
        COALESCE(SUM(total_amount), 0) as total_revenue,
        COALESCE(SUM(CASE WHEN payment_method = 'CASH' THEN total_amount ELSE 0 END), 0) as total_cash,
        COALESCE(SUM(CASE WHEN payment_method = 'QRIS' THEN total_amount ELSE 0 END), 0) as total_qris
      FROM transactions
      WHERE created_at LIKE ?
    ''', [pattern]);

    if (result.isNotEmpty) {
      return result.first;
    }

    return {
      'total_transactions': 0,
      'total_revenue': 0,
      'total_cash': 0,
      'total_qris': 0,
    };
  }

  /// Ambil Menu Terlaris (Top Selling) berdasarkan pattern
  Future<List<Map<String, dynamic>>> getTopSellingProducts(String pattern, {int limit = 5}) async {
    final db = await _dbHelper.database;

    return await db.rawQuery('''
      SELECT 
        ti.product_name,
        SUM(ti.qty) as total_qty,
        SUM(ti.subtotal) as total_sales
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at LIKE ?
      GROUP BY ti.product_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [pattern, limit]);
  }

  /// Ambil transaksi beserta itemnya berdasarkan pattern (Harian/Bulanan)
  Future<List<TransactionModel>> getTransactions(String pattern) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      'transactions',
      where: "created_at LIKE ?",
      whereArgs: [pattern],
      orderBy: 'created_at ASC',
    );

    List<TransactionModel> result = [];
    for (var map in maps) {
      final items = await _getTransactionItems(db, map['id'] as int);
      result.add(TransactionModel.fromMap(map, items: items));
    }

    return result;
  }

  // Helper Private: Ambil detail item per transaksi
  Future<List<TransactionItemModel>> _getTransactionItems(Database db, int transactionId) async {
    final maps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((map) => TransactionItemModel.fromMap(map)).toList();
  }
}