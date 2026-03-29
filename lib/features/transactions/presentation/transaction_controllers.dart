import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../inventory/presentation/inventory_controller.dart';
import '../models/transaction_models.dart';

class TransactionDraftState {
  const TransactionDraftState({
    this.items = const <CartItemDraft>[],
    this.paidAmount = 0,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.fieldErrors,
  });

  final List<CartItemDraft> items;
  final int paidAmount;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;
  final FieldErrors? fieldErrors;

  int get totalAmount {
    return items.fold<int>(0, (sum, item) => sum + item.subtotal);
  }

  int get changeAmount => paidAmount - totalAmount;

  TransactionDraftState copyWith({
    List<CartItemDraft>? items,
    int? paidAmount,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    FieldErrors? fieldErrors,
    bool clearErrors = false,
  }) {
    return TransactionDraftState(
      items: items ?? this.items,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : errorMessage ?? this.errorMessage,
      fieldErrors: clearErrors ? null : fieldErrors ?? this.fieldErrors,
    );
  }
}

final transactionDraftControllerProvider =
    NotifierProvider<TransactionDraftController, TransactionDraftState>(
      TransactionDraftController.new,
    );

class TransactionDraftController extends Notifier<TransactionDraftState> {
  @override
  TransactionDraftState build() => const TransactionDraftState();

  void addVariant(SearchVariantResult variant) {
    final items = [...state.items];
    final index = items.indexWhere(
      (item) => item.variantId == variant.variantId,
    );
    if (index == -1) {
      items.add(CartItemDraft.fromSearch(variant));
    } else {
      final current = items[index];
      final nextQty = (current.qty + 1).clamp(1, current.currentStock);
      items[index] = current.copyWith(qty: nextQty);
    }
    state = state.copyWith(items: items, clearErrors: true);
  }

  void removeItem(int variantId) {
    state = state.copyWith(
      items: state.items.where((item) => item.variantId != variantId).toList(),
      clearErrors: true,
    );
  }

  void increaseQty(int variantId) {
    _updateItem(variantId, (item) {
      return item.copyWith(qty: (item.qty + 1).clamp(1, item.currentStock));
    });
  }

  void decreaseQty(int variantId) {
    _updateItem(variantId, (item) {
      return item.copyWith(qty: (item.qty - 1).clamp(1, item.currentStock));
    });
  }

  void updateSellPrice(int variantId, int sellPrice) {
    _updateItem(variantId, (item) {
      return item.copyWith(sellPrice: sellPrice);
    });
  }

  void updatePaidAmount(String value) {
    state = state.copyWith(
      paidAmount: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
    );
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
  }

  void setPaidAmountValue(int value) {
    state = state.copyWith(paidAmount: value < 0 ? 0 : value);
  }

  void clearDraft() {
    state = const TransactionDraftState();
  }

  Future<TransactionDetail?> submit() async {
    if (state.items.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Tambahkan minimal satu varian ke keranjang.',
      );
      return null;
    }

    if (state.paidAmount < state.totalAmount) {
      state = state.copyWith(
        errorMessage: 'Nominal bayar kurang dari total transaksi.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearErrors: true);

    try {
      final result = await ref
          .read(transactionsRepositoryProvider)
          .createTransaction(
            items: state.items
                .map(
                  (item) => TransactionPayloadItem(
                    variantId: item.variantId,
                    qty: item.qty,
                    sellPrice: item.sellPrice,
                  ),
                )
                .toList(),
            paidAmount: state.paidAmount,
            note: state.note.trim().isEmpty ? null : state.note.trim(),
          );

      ref.invalidate(transactionHistoryControllerProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(inventoryControllerProvider);
      state = const TransactionDraftState();
      return result;
    } on ApiException catch (exception) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: exception.message,
        fieldErrors: exception.fieldErrors,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Checkout gagal. Coba lagi sebentar.',
      );
      return null;
    }
  }

  void _updateItem(
    int variantId,
    CartItemDraft Function(CartItemDraft item) transform,
  ) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.variantId == variantId);
    if (index == -1) {
      return;
    }
    items[index] = transform(items[index]);
    state = state.copyWith(items: items, clearErrors: true);
  }
}

final transactionHistoryControllerProvider =
    AsyncNotifierProvider<
      TransactionHistoryController,
      TransactionHistoryState
    >(TransactionHistoryController.new);

class TransactionHistoryController
    extends AsyncNotifier<TransactionHistoryState> {
  @override
  FutureOr<TransactionHistoryState> build() async {
    return _loadPage();
  }

  Future<void> refresh() async {
    final selectedDate = state.asData?.value.selectedDate;
    state = const AsyncLoading();
    state = AsyncData(await _loadPage(date: selectedDate));
  }

  Future<void> setDate(String? date) async {
    state = const AsyncLoading();
    state = AsyncData(await _loadPage(date: date));
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.meta.currentPage + 1;
    final response = await ref
        .read(transactionsRepositoryProvider)
        .listTransactions(date: current.selectedDate, page: nextPage);

    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...response.data],
        meta: response.meta,
        isLoadingMore: false,
      ),
    );
  }

  Future<TransactionHistoryState> _loadPage({String? date}) async {
    final response = await ref
        .read(transactionsRepositoryProvider)
        .listTransactions(date: date);
    return TransactionHistoryState(
      items: response.data,
      meta: response.meta,
      selectedDate: date,
    );
  }
}

final transactionDetailProvider = FutureProvider.family<TransactionDetail, int>(
  (ref, transactionId) {
    return ref
        .watch(transactionsRepositoryProvider)
        .getTransactionDetail(transactionId);
  },
);
