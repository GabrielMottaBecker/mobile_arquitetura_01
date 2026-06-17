import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_state.dart';
import '../../core/errors/failure.dart';

class ProductViewModel {
  final ProductRepository repository;

  final ValueNotifier<ProductState> state = ValueNotifier(
    const ProductState(),
  );

  ProductViewModel(this.repository);

  // ── Read ────────────────────────────────────────────────────────

  Future<void> loadProducts() async {
    state.value = state.value.copyWith(status: ProductStatus.loading);
    try {
      final products = await repository.getProducts();
      state.value = state.value.copyWith(
        status: ProductStatus.success,
        products: products,
      );
    } on UnauthorizedFailure {
      state.value = state.value.copyWith(
        status: ProductStatus.unauthorized,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> syncProducts() async {
    state.value = state.value.copyWith(status: ProductStatus.loading);
    try {
      await repository.syncProducts();
      final products = await repository.getProducts();
      state.value = state.value.copyWith(
        status: ProductStatus.success,
        products: products,
      );
    } on UnauthorizedFailure {
      state.value = state.value.copyWith(
        status: ProductStatus.unauthorized,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Create ──────────────────────────────────────────────────────

  Future<bool> createProduct(Product product) async {
    try {
      final created = await repository.createProduct(product);
      // Adiciona à lista atual sem precisar recarregar tudo
      final updated = List<Product>.from(state.value.products)..add(created);
      state.value = state.value.copyWith(
        status: ProductStatus.success,
        products: updated,
      );
      return true;
    } on UnauthorizedFailure {
      state.value = state.value.copyWith(
        status: ProductStatus.unauthorized,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      );
    }
    return false;
  }

  // ── Update ──────────────────────────────────────────────────────

  Future<bool> updateProduct(Product product) async {
    try {
      final updated = await repository.updateProduct(product);
      final list = state.value.products
          .map((p) => p.id == updated.id ? updated : p)
          .toList();
      state.value = state.value.copyWith(
        status: ProductStatus.success,
        products: list,
      );
      return true;
    } on UnauthorizedFailure {
      state.value = state.value.copyWith(
        status: ProductStatus.unauthorized,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      );
    }
    return false;
  }

  // ── Delete ──────────────────────────────────────────────────────

  Future<bool> deleteProduct(int id) async {
    try {
      await repository.deleteProduct(id);
      final list = state.value.products.where((p) => p.id != id).toList();
      state.value = state.value.copyWith(
        status: ProductStatus.success,
        products: list,
      );
      return true;
    } on UnauthorizedFailure {
      state.value = state.value.copyWith(
        status: ProductStatus.unauthorized,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      );
    }
    return false;
  }

  // ── Favorites ───────────────────────────────────────────────────

  /// Alterna o estado de favorito do produto com o [id] informado.
  void toggleFavorite(int? id) {
    if (id == null) return;
    final list = state.value.products.map((p) {
      return p.id == id ? p.copyWith(isFavorite: !p.isFavorite) : p;
    }).toList();
    state.value = state.value.copyWith(products: list);
  }

  /// Alterna o filtro "mostrar apenas favoritos".
  void toggleFavoriteFilter() {
    state.value = state.value.copyWith(
      showOnlyFavorites: !state.value.showOnlyFavorites,
    );
  }
}
