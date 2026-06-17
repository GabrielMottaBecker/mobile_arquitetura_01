import '../../domain/entities/product.dart';

enum ProductStatus { initial, loading, success, error, unauthorized }

class ProductState {
  final ProductStatus status;
  final List<Product> products;
  final String? errorMessage;
  final bool showOnlyFavorites;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.errorMessage,
    this.showOnlyFavorites = false,
  });

  /// Lista visível, respeitando o filtro de favoritos.
  List<Product> get visibleProducts =>
      showOnlyFavorites ? products.where((p) => p.isFavorite).toList() : products;

  /// Quantidade de produtos favoritados.
  int get favoriteCount => products.where((p) => p.isFavorite).length;

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    String? errorMessage,
    bool? showOnlyFavorites,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage,
      showOnlyFavorites: showOnlyFavorites ?? this.showOnlyFavorites,
    );
  }
}
