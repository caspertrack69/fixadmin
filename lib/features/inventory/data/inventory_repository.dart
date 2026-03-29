import '../../../core/network/api_client.dart';
import '../models/inventory_models.dart';

abstract class InventoryRepository {
  Future<List<Category>> fetchCatalogTree();
}

class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<Category>> fetchCatalogTree() {
    return _apiClient.getList<Category>(
      '/catalog/tree',
      parser: Category.fromJson,
    );
  }
}
