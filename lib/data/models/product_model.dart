import '../../domain/entities/product.dart';

class ProductModel {
  final int? id;
  final String title;
  final double price;
  final String thumbnail;
  final String description;
  final String category;
  final double rating;
  final int stock;
  final bool isLocal;

  ProductModel({
    this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.description,
    required this.category,
    required this.rating,
    required this.stock,
    this.isLocal = false,
  });

  // JSON da API remota (DummyJSON)

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isLocal: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        'thumbnail': thumbnail,
        'description': description,
        'category': category,
        'stock': stock,
      };

  // SQLite

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      thumbnail: map['thumbnail'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isLocal: (map['isLocal'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'price': price,
        'thumbnail': thumbnail,
        'description': description,
        'category': category,
        'rating': rating,
        'stock': stock,
        'isLocal': isLocal ? 1 : 0,
      };

  // Conversão domínio

  factory ProductModel.fromEntity(Product entity) => ProductModel(
        id: entity.id,
        title: entity.title,
        price: entity.price,
        thumbnail: entity.image,
        description: entity.description,
        category: entity.category,
        rating: entity.ratingRate,
        stock: entity.ratingCount,
        isLocal: entity.isLocal,
      );

  Product toEntity() => Product(
        id: id,
        title: title,
        price: price,
        image: thumbnail,
        description: description,
        category: category,
        ratingRate: rating,
        ratingCount: stock,
        isLocal: isLocal,
      );
}
