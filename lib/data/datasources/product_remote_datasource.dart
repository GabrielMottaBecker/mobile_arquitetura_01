import '../../core/network/http_client.dart';
import '../models/product_model.dart';

class ProductRemoteDatasource {
  final HttpClient client;

  static const _baseUrl = 'https://dummyjson.com/products';

  ProductRemoteDatasource(this.client);

  Future<List<ProductModel>> getProducts() async {
    final response = await client.get(_baseUrl);
    final data = response.data as Map<String, dynamic>;
    final list = data['products'] as List;
    return list
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await client.get('$_baseUrl/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    final response = await client.post('$_baseUrl/add', product.toJson());
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final response =
        await client.put('$_baseUrl/${product.id}', product.toJson());
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    await client.delete('$_baseUrl/$id');
  }
}
