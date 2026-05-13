class Product {
  final int? id;
  final String title;
  final double price;
  final String image;
  final String description;
  final String category;
  final double ratingRate;
  final int ratingCount;

  final bool isLocal;

  final bool isFavorite;

  const Product({
    this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.description,
    required this.category,
    this.ratingRate = 0.0,
    this.ratingCount = 0,
    this.isLocal = false,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      'image': image,
      'description': description,
      'category': category,
      'ratingRate': ratingRate,
      'ratingCount': ratingCount,
      'isLocal': isLocal ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'image': image,
      'description': description,
      'category': category,
    };
  }

  Product copyWith({
    int? id,
    String? title,
    double? price,
    String? image,
    String? description,
    String? category,
    double? ratingRate,
    int? ratingCount,
    bool? isLocal,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      category: category ?? this.category,
      ratingRate: ratingRate ?? this.ratingRate,
      ratingCount: ratingCount ?? this.ratingCount,
      isLocal: isLocal ?? this.isLocal,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
