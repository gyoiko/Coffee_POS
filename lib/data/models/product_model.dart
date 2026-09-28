class ProductModel {
  final int? id;
  final int categoryId;
  final String name;
  final int price;
  final bool isAvailable;

  ProductModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'category_id': categoryId,
      'name': name,
      'price': price,
      'is_available': isAvailable ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      price: map['price'] as int,
      isAvailable: (map['is_available'] as int) == 1,
    );
  }
}