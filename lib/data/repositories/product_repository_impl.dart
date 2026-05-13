import '../../core/errors/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource remoteDatasource;
  final ProductLocalDatasource localDatasource;

  ProductRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  // Read 
  @override
  Future<List<Product>> getProducts() async {
    if (await localDatasource.hasData) {
      final local = await localDatasource.getAllProducts();
      return local.map((m) => m.toEntity()).toList();
    }

    try {
      final models = await remoteDatasource.getProducts();
      await localDatasource.insertAll(models);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<Product?> getProductById(int id) async {
    final local = await localDatasource.getProductById(id);
    return local?.toEntity();
  }

  //  Create 
  @override
  Future<Product> createProduct(Product product) async {
    final localProduct = product.copyWith(isLocal: true);

    try {
      final remoteModel = await remoteDatasource
          .createProduct(ProductModel.fromEntity(localProduct));
      final localModel = ProductModel(
        id: remoteModel.id,
        title: remoteModel.title,
        price: remoteModel.price,
        thumbnail: remoteModel.thumbnail,
        description: remoteModel.description,
        category: remoteModel.category,
        rating: remoteModel.rating,
        stock: remoteModel.stock,
        isLocal: true,
      );
      final localId = await localDatasource.insertProduct(localModel);
      return localModel.toEntity().copyWith(id: localId);
    } catch (_) {
      final localId = await localDatasource
          .insertProduct(ProductModel.fromEntity(localProduct));
      return localProduct.copyWith(id: localId);
    }
  }

  // Update
  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final remoteModel = await remoteDatasource
          .updateProduct(ProductModel.fromEntity(product));
      final merged = ProductModel(
        id: remoteModel.id,
        title: remoteModel.title,
        price: remoteModel.price,
        thumbnail: remoteModel.thumbnail,
        description: remoteModel.description,
        category: remoteModel.category,
        rating: remoteModel.rating,
        stock: remoteModel.stock,
        isLocal: product.isLocal,
      );
      await localDatasource.updateProduct(merged);
      return merged.toEntity();
    } catch (_) {
      final model = ProductModel.fromEntity(product);
      await localDatasource.updateProduct(model);
      return product;
    }
  }

  // Delete
  @override
  Future<void> deleteProduct(int id) async {
    try {
      await remoteDatasource.deleteProduct(id);
    } catch (_) {}
    await localDatasource.deleteProduct(id);
  }

  // Sync 
  @override
  Future<void> syncProducts() async {
    final models = await remoteDatasource.getProducts();
    await localDatasource.clearAll();
    await localDatasource.insertAll(models);
  }
}