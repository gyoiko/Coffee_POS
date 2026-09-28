import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import 'cart_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  bool _isProcessing = false;
  String _paymentMethod = 'CASH'; // 'CASH' atau 'QRIS'
  int _cashAmount = 0;
  TransactionModel? _lastTransaction;

  bool get isProcessing => _isProcessing;
  String get paymentMethod => _paymentMethod;
  int get cashAmount => _cashAmount;
  TransactionModel? get lastTransaction => _lastTransaction;

  // Hitung Kembalian (Cash)
  int calculateChange(int totalAmount) {
    if (_paymentMethod == 'QRIS') return 0;
    final change = _cashAmount - totalAmount;
    return change > 0 ? change : 0;
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setCashAmount(int amount) {
    _cashAmount = amount;
    notifyListeners();
  }

  // Format Kode Transaksi Unik: TRX-YYYYMMDD-HHMMSS
  String _generateTransactionCode() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd-HHmmss');
    return 'TRX-${formatter.format(now)}';
  }

  // Proses Simpan Transaksi ke Database
  Future<bool> processCheckout(List<CartItem> cartItems, int totalAmount) async {
    if (cartItems.isEmpty) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final code = _generateTransactionCode();

      final transaction = TransactionModel(
        transactionCode: code,
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        createdAt: now,
      );

      final items = cartItems.map((cart) => cart.toTransactionItem()).toList();

      final transactionId = await _repository.createTransaction(transaction, items);

      // Simpan riwayat transaksi terakhir untuk kebutuhan cetak struk
      _lastTransaction = TransactionModel(
        id: transactionId,
        transactionCode: code,
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        createdAt: now,
        items: items,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void resetPayment() {
    _paymentMethod = 'CASH';
    _cashAmount = 0;
    notifyListeners();
  }
}