import 'package:flutter/foundation.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  ProductProvider() {
    fetchData();
  }

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  bool _isLoading = false;
  int? _selectedCategoryId;

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  int? get selectedCategoryId => _selectedCategoryId;

  Future<void> fetchData() async {
    _isLoading = true;
    // Panggil notifyListeners() secara asinkron agar tidak bentrok dengan proses build UI pertama kali
    Future.microtask(() => notifyListeners());

    try {
      _categories = await _repository.getCategories();
      _products = await _repository.getAllProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    _isLoading = true;
    notifyListeners();

    if (categoryId == null) {
      _products = await _repository.getAllProducts();
    } else {
      _products = await _repository.getProductsByCategory(categoryId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await _repository.insertProduct(product);
    await fetchData(); // Refresh data
  }
}
