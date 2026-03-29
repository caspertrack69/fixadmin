import '../../../core/models/paged_response.dart';
import '../../../core/network/api_client.dart';
import '../models/stock_in_models.dart';

abstract class StockInRepository {
  Future<PagedResponse<StockInLog>> listStockIn({
    String? date,
    int page = 1,
    int perPage = 20,
  });

  Future<StockInLog> createStockIn(StockInPayload payload);
}

class ApiStockInRepository implements StockInRepository {
  ApiStockInRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<PagedResponse<StockInLog>> listStockIn({
    String? date,
    int page = 1,
    int perPage = 20,
  }) {
    return _apiClient.getPagedList<StockInLog>(
      '/stock/in',
      queryParameters: {
        'date': date,
        'page': page,
        'per_page': perPage,
      }..removeWhere((key, value) => value == null),
      parser: StockInLog.fromJson,
    );
  }

  @override
  Future<StockInLog> createStockIn(StockInPayload payload) {
    return _apiClient.postObject<StockInLog>(
      '/stock/in',
      body: payload.toJson(),
      parser: StockInLog.fromJson,
    );
  }
}
