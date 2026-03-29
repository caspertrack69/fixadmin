import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/config/app_config.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/inventory/data/inventory_repository.dart';
import '../../features/stock_in/data/stock_in_repository.dart';
import '../../features/transactions/data/transactions_repository.dart';
import '../network/api_client.dart';
import '../storage/token_store.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return SecureTokenStore(storage: ref.watch(secureStorageProvider));
});

final sessionCoordinatorProvider = Provider<SessionCoordinator>((ref) {
  return SessionCoordinator();
});

final dioProvider = Provider<Dio>((ref) {
  return buildDio(
    baseUrl: AppConfig.baseUrl,
    tokenStore: ref.watch(tokenStoreProvider),
    coordinator: ref.watch(sessionCoordinatorProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dio: ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    coordinator: ref.watch(sessionCoordinatorProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return ApiDashboardRepository(apiClient: ref.watch(apiClientProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return ApiInventoryRepository(apiClient: ref.watch(apiClientProvider));
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return ApiTransactionsRepository(apiClient: ref.watch(apiClientProvider));
});

final stockInRepositoryProvider = Provider<StockInRepository>((ref) {
  return ApiStockInRepository(apiClient: ref.watch(apiClientProvider));
});
