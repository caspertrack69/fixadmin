import '../../../core/models/paged_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../models/transaction_models.dart';

abstract class TransactionsRepository {
  Future<PagedResponse<SearchVariantResult>> searchVariants({
    required String query,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  });

  Future<PagedResponse<TransactionHistoryItem>> listTransactions({
    String? date,
    int page = 1,
    int perPage = 20,
  });

  Future<TransactionDetail> createTransaction({
    required List<TransactionPayloadItem> items,
    required int paidAmount,
    String? note,
  });

  Future<TransactionDetail> getTransactionDetail(int transactionId);
}

class ApiTransactionsRepository implements TransactionsRepository {
  ApiTransactionsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<PagedResponse<SearchVariantResult>> searchVariants({
    required String query,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  }) {
    return _apiClient.getPagedList<SearchVariantResult>(
      ApiPaths.variantsSearch,
      queryParameters: {
        'q': query,
        'in_stock': inStock == null ? null : (inStock ? 1 : 0),
        'page': page,
        'per_page': perPage,
      }..removeWhere((key, value) => value == null),
      parser: SearchVariantResult.fromJson,
    );
  }

  @override
  Future<PagedResponse<TransactionHistoryItem>> listTransactions({
    String? date,
    int page = 1,
    int perPage = 20,
  }) {
    return _apiClient.getPagedList<TransactionHistoryItem>(
      ApiPaths.transactions,
      queryParameters: {'date': date, 'page': page, 'per_page': perPage}
        ..removeWhere((key, value) => value == null),
      parser: TransactionHistoryItem.fromJson,
    );
  }

  @override
  Future<TransactionDetail> createTransaction({
    required List<TransactionPayloadItem> items,
    required int paidAmount,
    String? note,
  }) {
    return _apiClient.postObject<TransactionDetail>(
      ApiPaths.transactions,
      body: {
        'items': items.map((item) => item.toJson()).toList(),
        'paid_amount': paidAmount,
        'note': note,
      },
      parser: TransactionDetail.fromJson,
    );
  }

  @override
  Future<TransactionDetail> getTransactionDetail(int transactionId) {
    return _apiClient.getObject<TransactionDetail>(
      ApiPaths.transactionDetail(transactionId),
      parser: TransactionDetail.fromJson,
    );
  }
}
