import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../inventory/presentation/inventory_controller.dart';
import '../../transactions/models/transaction_models.dart';
import '../models/stock_in_models.dart';

final stockInDraftControllerProvider =
    NotifierProvider<StockInDraftController, StockInDraftState>(
      StockInDraftController.new,
    );

class StockInDraftController extends Notifier<StockInDraftState> {
  @override
  StockInDraftState build() => const StockInDraftState();

  void selectVariant(SearchVariantResult variant) {
    state = state.copyWith(selectedVariant: variant, clearError: true);
  }

  void updateQty(String value) {
    state = state.copyWith(
      qty: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      clearError: true,
    );
  }

  void updateBuyPrice(String value) {
    state = state.copyWith(
      buyPrice: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      clearError: true,
    );
  }

  void updateNote(String value) {
    state = state.copyWith(note: value, clearError: true);
  }

  Future<StockInLog?> submit() async {
    if (state.selectedVariant == null) {
      state = state.copyWith(errorMessage: 'Pilih varian terlebih dahulu.');
      return null;
    }
    if (state.qty <= 0 || state.buyPrice <= 0) {
      state = state.copyWith(
        errorMessage: 'Qty dan harga beli harus lebih besar dari nol.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await ref
          .read(stockInRepositoryProvider)
          .createStockIn(
            StockInPayload(
              variantId: state.selectedVariant!.variantId,
              qty: state.qty,
              buyPrice: state.buyPrice,
              note: state.note.trim().isEmpty ? null : state.note.trim(),
            ),
          );
      ref.invalidate(stockInHistoryControllerProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(inventoryControllerProvider);
      state = const StockInDraftState();
      return result;
    } on ApiException catch (exception) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: exception.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Input stok gagal. Coba lagi.',
      );
      return null;
    }
  }
}

final stockInHistoryControllerProvider =
    AsyncNotifierProvider<StockInHistoryController, StockInHistoryState>(
      StockInHistoryController.new,
    );

class StockInHistoryController extends AsyncNotifier<StockInHistoryState> {
  @override
  FutureOr<StockInHistoryState> build() async {
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
        .read(stockInRepositoryProvider)
        .listStockIn(date: current.selectedDate, page: nextPage);
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...response.data],
        meta: response.meta,
        isLoadingMore: false,
      ),
    );
  }

  Future<StockInHistoryState> _loadPage({String? date}) async {
    final response = await ref
        .read(stockInRepositoryProvider)
        .listStockIn(date: date);
    return StockInHistoryState(
      items: response.data,
      meta: response.meta,
      selectedDate: date,
    );
  }
}
