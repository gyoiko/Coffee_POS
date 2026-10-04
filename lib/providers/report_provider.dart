import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

enum ReportFilterMode { daily, monthly }

class ReportProvider with ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  bool _isLoading = false;
  ReportFilterMode _filterMode = ReportFilterMode.daily;
  DateTime _selectedDate = DateTime.now();

  Map<String, dynamic> _summary = {
    'total_transactions': 0,
    'total_items_sold': 0,
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
    if (_filterMode != mode) {
      _filterMode = mode;
      fetchReport();
    }
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

  Future<String?> exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      String sheetName = 'Laporan Penjualan';
      excel.rename('Sheet1', sheetName);
      Sheet sheetObject = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // Header Informasi Periode Laporan
      final modeStr = _filterMode == ReportFilterMode.daily ? 'Harian' : 'Bulanan';
      final dateStr = _filterMode == ReportFilterMode.daily 
          ? DateFormat('dd MMMM yyyy').format(_selectedDate)
          : DateFormat('MMMM yyyy').format(_selectedDate);

      sheetObject.appendRow([TextCellValue('LAPORAN PENJUALAN ($modeStr)')]);
      sheetObject.appendRow([TextCellValue('Periode: $dateStr')]);
      sheetObject.appendRow([TextCellValue('')]);

      // Ringkasan
      sheetObject.appendRow([
        TextCellValue('Total Transaksi'),
        IntCellValue(_summary['total_transactions'] ?? 0),
      ]);
      sheetObject.appendRow([
        TextCellValue('Total Produk Terjual'),
        IntCellValue(_summary['total_items_sold'] ?? 0),
      ]);
      sheetObject.appendRow([
        TextCellValue('Total Pendapatan'),
        IntCellValue(_summary['total_revenue'] ?? 0),
      ]);
      sheetObject.appendRow([
        TextCellValue('Total Cash'),
        IntCellValue(_summary['total_cash'] ?? 0),
      ]);
      sheetObject.appendRow([
        TextCellValue('Total QRIS'),
        IntCellValue(_summary['total_qris'] ?? 0),
      ]);
      sheetObject.appendRow([TextCellValue('')]);

      // Header Tabel Detail
      sheetObject.appendRow([
        TextCellValue('Kode Transaksi'),
        TextCellValue('Tanggal & Waktu'),
        TextCellValue('Metode Pembayaran'),
        TextCellValue('Nama Produk'),
        TextCellValue('Harga Satuan'),
        TextCellValue('Qty'),
        TextCellValue('Subtotal Item'),
        TextCellValue('Total Bayar Transaksi')
      ]);

      // Data Transaksi
      for (var tx in _transactions) {
        final txDate = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt);
        if (tx.items != null && tx.items!.isNotEmpty) {
          for (var i = 0; i < tx.items!.length; i++) {
            var item = tx.items![i];
            sheetObject.appendRow([
              TextCellValue(tx.transactionCode),
              TextCellValue(txDate),
              TextCellValue(tx.paymentMethod),
              TextCellValue(item.productName),
              IntCellValue(item.price),
              IntCellValue(item.qty),
              IntCellValue(item.subtotal),
              i == 0 ? IntCellValue(tx.totalAmount) : TextCellValue(''),
            ]);
          }
        } else {
          sheetObject.appendRow([
            TextCellValue(tx.transactionCode),
            TextCellValue(txDate),
            TextCellValue(tx.paymentMethod),
            TextCellValue('-'),
            TextCellValue('-'),
            TextCellValue('-'),
            TextCellValue('-'),
            IntCellValue(tx.totalAmount)
          ]);
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileDateStr = _filterMode == ReportFilterMode.daily 
          ? DateFormat('yyyy-MM-dd').format(_selectedDate)
          : DateFormat('yyyy-MM').format(_selectedDate);
      
      final path = '${directory.path}/Laporan_Penjualan_${modeStr}_$fileDateStr.xlsx';
      final file = File(path);
      
      var fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return path;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting Excel: $e');
      }
      return null;
    }
  }
}