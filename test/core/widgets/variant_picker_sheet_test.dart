import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasirfix/core/models/paged_response.dart';
import 'package:kasirfix/core/providers/app_providers.dart';
import 'package:kasirfix/core/widgets/variant_picker_sheet.dart';
import 'package:kasirfix/features/inventory/data/inventory_repository.dart';
import 'package:kasirfix/features/inventory/models/inventory_models.dart';
import 'package:kasirfix/features/transactions/data/transactions_repository.dart';
import 'package:kasirfix/features/transactions/models/transaction_models.dart';

void main() {
  testWidgets('shows in-stock catalog variants immediately for POS picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            _FakeInventoryRepository(_sampleTree),
          ),
          transactionsRepositoryProvider.overrideWithValue(
            _FakeTransactionsRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: VariantPickerSheet(
              title: 'Cari varian untuk checkout',
              inStockOnly: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('iPhone - iPhone 15 Pro Max - LCD - Grade A'),
      findsOneWidget,
    );
    expect(
      find.text('iPhone - iPhone 15 Pro Max - LCD - Grade B'),
      findsNothing,
    );
    expect(find.text('Rp 2.500.000'), findsOneWidget);
  });
}

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository(this._tree);

  final List<Category> _tree;

  @override
  Future<List<Category>> fetchCatalogTree() async => _tree;
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

const _sampleTree = [
  Category(
    id: 1,
    name: 'iPhone',
    models: [
      DeviceModel(
        id: 11,
        name: 'iPhone 15 Pro Max',
        parts: [
          Part(
            id: 21,
            name: 'LCD',
            variants: [
              Variant(
                id: 31,
                name: 'Grade A',
                sellPrice: 2500000,
                currentStock: 3,
                minStock: 1,
              ),
              Variant(
                id: 32,
                name: 'Grade B',
                sellPrice: 1800000,
                currentStock: 0,
                minStock: 1,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
