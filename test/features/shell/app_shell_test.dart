import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasirfix/app/shell/app_shell.dart';
import 'package:kasirfix/core/models/paged_response.dart';
import 'package:kasirfix/core/providers/app_providers.dart';
import 'package:kasirfix/features/auth/models/auth_session.dart';
import 'package:kasirfix/features/auth/models/session_user.dart';
import 'package:kasirfix/features/dashboard/data/dashboard_repository.dart';
import 'package:kasirfix/features/dashboard/models/dashboard_summary.dart';
import 'package:kasirfix/features/inventory/data/inventory_repository.dart';
import 'package:kasirfix/features/inventory/models/inventory_models.dart';
import 'package:kasirfix/features/stock_in/data/stock_in_repository.dart';
import 'package:kasirfix/features/stock_in/models/stock_in_models.dart';
import 'package:kasirfix/features/transactions/data/transactions_repository.dart';
import 'package:kasirfix/features/transactions/models/transaction_models.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('hides stock in tab when session has no stock permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _repoOverrides,
        child: MaterialApp(
          home: AppShell(
            session: AuthSession(
              token: 'token',
              user: const SessionUser(
                id: 1,
                name: 'Kasir',
                email: 'kasir@test.com',
                role: 'kasir',
                canInputStock: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Inventaris'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Stok Masuk'), findsNothing);
  });
}

final _repoOverrides = [
  dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
  inventoryRepositoryProvider.overrideWithValue(_FakeInventoryRepository()),
  transactionsRepositoryProvider.overrideWithValue(
    _FakeTransactionsRepository(),
  ),
  stockInRepositoryProvider.overrideWithValue(_FakeStockInRepository()),
];

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> fetchDashboard() async {
    return const DashboardSummary(
      today: TodaySummary(
        date: '2026-03-29',
        totalTransactions: 0,
        totalRevenue: 0,
      ),
      permissions: DashboardPermissions(canInputStock: false),
      lowStockAlerts: [],
    );
  }
}

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<List<Category>> fetchCatalogTree() async => const [];
}

class _FakeTransactionsRepository implements TransactionsRepository {
  @override
  Future<TransactionDetail> createTransaction({
    required List<TransactionPayloadItem> items,
    required int paidAmount,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionDetail> getTransactionDetail(int transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<PagedResponse<TransactionHistoryItem>> listTransactions({
    String? date,
    int page = 1,
    int perPage = 20,
  }) async {
    return const PagedResponse(
      data: [],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
    );
  }

  @override
  Future<PagedResponse<SearchVariantResult>> searchVariants({
    required String query,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  }) async {
    return const PagedResponse(
      data: [],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
    );
  }
}

class _FakeStockInRepository implements StockInRepository {
  @override
  Future<StockInLog> createStockIn(StockInPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<PagedResponse<StockInLog>> listStockIn({
    String? date,
    int page = 1,
    int perPage = 20,
  }) async {
    return const PagedResponse(
      data: [],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
    );
  }
}
