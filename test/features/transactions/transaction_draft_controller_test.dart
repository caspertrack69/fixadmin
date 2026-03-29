import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixadmin/core/models/paged_response.dart';
import 'package:fixadmin/core/providers/app_providers.dart';
import 'package:fixadmin/features/transactions/data/transactions_repository.dart';
import 'package:fixadmin/features/transactions/models/transaction_models.dart';
import 'package:fixadmin/features/transactions/presentation/transaction_controllers.dart';

void main() {
  test('submit exposes loading state and clears draft on success', () async {
    final completer = Completer<TransactionDetail>();
    final container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(
          _FakeTransactionsRepository(completer),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionDraftControllerProvider.notifier);
    notifier.addVariant(
      const SearchVariantResult(
        variantId: 31,
        displayName: 'iPhone - 15 Pro Max - LCD - Grade A',
        category: 'iPhone',
        model: 'iPhone 15 Pro Max',
        part: 'LCD',
        grade: 'Grade A',
        sellPrice: 2500000,
        currentStock: 5,
      ),
    );
    notifier.updatePaidAmount('3000000');

    final pending = notifier.submit();
    expect(
      container.read(transactionDraftControllerProvider).isSubmitting,
      isTrue,
    );

    completer.complete(
      const TransactionDetail(
        transactionId: 1,
        transactionCode: 'TRX-001',
        kasir: 'Kasir',
        items: [
          TransactionLineItem(
            displayName: 'Item',
            qty: 1,
            sellPrice: 2500000,
            subtotal: 2500000,
          ),
        ],
        totalAmount: 2500000,
        paidAmount: 3000000,
        changeAmount: 500000,
        note: null,
        createdAt: null,
      ),
    );

    final result = await pending;
    final state = container.read(transactionDraftControllerProvider);

    expect(result, isNotNull);
    expect(state.items, isEmpty);
    expect(state.isSubmitting, isFalse);
  });
}

class _FakeTransactionsRepository implements TransactionsRepository {
  _FakeTransactionsRepository(this._createCompleter);

  final Completer<TransactionDetail> _createCompleter;

  @override
  Future<TransactionDetail> createTransaction({
    required List<TransactionPayloadItem> items,
    required int paidAmount,
    String? note,
  }) {
    return _createCompleter.future;
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
      meta: PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
      ),
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
      meta: PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
      ),
    );
  }
}
