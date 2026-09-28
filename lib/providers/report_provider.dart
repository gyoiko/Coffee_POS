import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

enum ReportFilterMode { daily, monthly }

class ReportProvider with ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  bool _isLoading = false;
  ReportFilterMode _filterMode = ReportFilterMode.monthly;
  DateTime _selectedDate = DateTime.now();

  Map<String, dynamic> _summary = {
    'total_transactions': 0,
    'total_revenue': 0,
    'total_cash': 0,
    'total_qris': 0,
  };

  List<Map<String, dynamic>> _topProducts = [];
  List<TransactionModel> _transactions = [];

  bool get isLoading => _isLoading;
  ReportFilterMode get filterMode => _filterMode;
  DateTime get selectedDate => _selectedDate;
  Map<String, dynamic> get summary => _summary;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<TransactionModel> get transactions => _transactions;

  void setFilterMode(ReportFilterMode mode) {
    _filterMode = mode;
    fetchReport();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchReport();
  }

  String get _currentDatePattern {
    if (_filterMode == ReportFilterMode.daily) {
      return '${DateFormat('yyyy-MM-dd').format(_selectedDate)}%';
    } else {
      return '${DateFormat('yyyy-MM').format(_selectedDate)}%';
    }
  }

  Future<void> fetchReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pattern = _currentDatePattern;
      _summary = await _repository.getSummary(pattern);
      _topProducts = await _repository.getTopSellingProducts(pattern);
      _transactions = await _repository.getTransactions(pattern);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching report: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportToCSV() async {
    try {
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'Kode Transaksi',
        'Tanggal',
        'Metode Pembayaran',
        'Produk',
        'Harga',
        'Qty',
        'Subtotal',
        'Total Transaksi'
      ]);

      for (var tx in _transactions) {
        final txDate = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt);
        if (tx.items != null && tx.items!.isNotEmpty) {
          for (var i = 0; i < tx.items!.length; i++) {
            var item = tx.items![i];
            rows.add([
              i == 0 ? tx.transactionCode : '',
              i == 0 ? txDate : '',
              i == 0 ? tx.paymentMethod : '',
              item.productName,
              item.price,
              item.qty,
              item.subtotal,
              i == 0 ? tx.totalAmount : ''
            ]);
          }
        } else {
          rows.add([
            tx.transactionCode,
            txDate,
            tx.paymentMethod,
            '-', '-', '-', '-',
            tx.totalAmount
          ]);
        }
      }

      String csv = rows.map((row) => row.map((item) => '"${item.toString().replaceAll('"', '""')}"').join(',')).join('\n');

      final directory = await getApplicationDocumentsDirectory();
      final modeStr = _filterMode == ReportFilterMode.daily ? 'Harian' : 'Bulanan';
      final dateStr = _filterMode == ReportFilterMode.daily 
          ? DateFormat('yyyy-MM-dd').format(_selectedDate)
          : DateFormat('yyyy-MM').format(_selectedDate);
      
      final path = '${directory.path}/Laporan_Penjualan_${modeStr}_$dateStr.csv';
      final file = File(path);
      await file.writeAsString(csv);
      
      return path;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting CSV: $e');
      }
      return null;
    }
  }
}