import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../models/inventory_models.dart';

abstract class InventoryRepository {
  Future<List<Category>> fetchCatalogTree();
}

class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<Category>> fetchCatalogTree() {
    return _apiClient.getList<Category>(
      ApiPaths.catalogTree,
      parser: Category.fromJson,
    );
  }
}
