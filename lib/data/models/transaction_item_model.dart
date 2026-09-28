class TransactionItemModel {
  final int? id;
  final int? transactionId;
  final String productName;
  final int price;
  final int qty;
  final int subtotal;
  final String? notes;

  TransactionItemModel({
    this.id,
    this.transactionId,
    required this.productName,
    required this.price,
    required this.qty,
    required this.subtotal,
    this.notes,
  });

  Map<String, dynamic> toMap({int? assignedTransactionId}) {
    return {
      'id': id,
      'transaction_id': assignedTransactionId ?? transactionId,
      'product_name': productName,
      'price': price,
      'qty': qty,
      'subtotal': subtotal,
      'notes': notes,
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      productName: map['product_name'] as String,
      price: map['price'] as int,
      qty: map['qty'] as int,
      subtotal: map['subtotal'] as int,
      notes: map['notes'] as String?,
    );
  }
}