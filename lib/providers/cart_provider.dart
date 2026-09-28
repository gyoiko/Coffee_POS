import 'package:flutter/foundation.dart';
import '../data/models/product_model.dart';
import '../data/models/transaction_item_model.dart';

class CartItem {
  final ProductModel product;
  int qty;
  String? notes;

  CartItem({
    required this.product,
    this.qty = 1,
    this.notes,
  });

  int get subtotal => product.price * qty;

  TransactionItemModel toTransactionItem() {
    return TransactionItemModel(
      productName: product.name,
      price: product.price,
      qty: qty,
      subtotal: subtotal,
      notes: notes,
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.qty);
  }

  // Tambahkan produk ke keranjang
  void addToCart(ProductModel product, {String? notes}) {
    // Cek apakah produk dengan ID dan catatan yang sama sudah ada di keranjang
    final index = _items.indexWhere(
      (item) => item.product.id == product.id && item.notes == notes,
    );

    if (index >= 0) {
      _items[index].qty++;
    } else {
      _items.add(CartItem(product: product, qty: 1, notes: notes));
    }
    notifyListeners();
  }

  // Tambah Qty +1
  void incrementQty(int index) {
    _items[index].qty++;
    notifyListeners();
  }

  // Kurangi Qty -1 (jika 1 lalu dikurangi, hapus dari keranjang)
  void decrementQty(int index) {
    if (_items[index].qty > 1) {
      _items[index].qty--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  // Hapus item dari keranjang
  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  // Update Catatan (Notes) Item
  void updateNotes(int index, String? newNotes) {
    _items[index].notes = newNotes;
    notifyListeners();
  }

  // Kosongkan Keranjang
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}