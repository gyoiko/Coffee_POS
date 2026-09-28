import 'transaction_item_model.dart';

class TransactionModel {
  final int? id;
  final String transactionCode;
  final int totalAmount;
  final String paymentMethod; // 'CASH' atau 'QRIS'
  final DateTime createdAt;
  final List<TransactionItemModel>? items;

  TransactionModel({
    this.id,
    required this.transactionCode,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {List<TransactionItemModel>? items}) {
    return TransactionModel(
      id: map['id'] as int?,
      transactionCode: map['transaction_code'] as String,
      totalAmount: map['total_amount'] as int,
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }
}