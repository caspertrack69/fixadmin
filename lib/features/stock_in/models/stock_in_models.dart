import '../../../core/models/paged_response.dart';
import '../../../core/utils/json_parsers.dart';
import '../../transactions/models/transaction_models.dart';

class StockInLog {
  const StockInLog({
    required this.logId,
    required this.variant,
    required this.qty,
    required this.buyPrice,
    required this.stockAfter,
    required this.note,
    required this.createdBy,
    required this.createdAt,
  });

  final int logId;
  final String variant;
  final int qty;
  final int buyPrice;
  final int stockAfter;
  final String? note;
  final String createdBy;
  final DateTime? createdAt;

  factory StockInLog.fromJson(Map<String, dynamic> json) {
    return StockInLog(
      logId: parseInt(json['log_id']),
      variant: parseString(json['variant']),
      qty: parseInt(json['qty']),
      buyPrice: parseInt(json['buy_price']),
      stockAfter: parseInt(json['stock_after']),
      note: json['note'] == null ? null : parseString(json['note']),
      createdBy: parseString(json['created_by']),
      createdAt: parseDateTime(json['created_at']),
    );
  }
}

class StockInPayload {
  const StockInPayload({
    required this.variantId,
    required this.qty,
    required this.buyPrice,
    this.note,
  });

  final int variantId;
  final int qty;
  final int buyPrice;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'qty': qty,
      'buy_price': buyPrice,
      'note': note,
    };
  }
}

class StockInDraftState {
  const StockInDraftState({
    this.selectedVariant,
    this.qty = 1,
    this.buyPrice = 0,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  final SearchVariantResult? selectedVariant;
  final int qty;
  final int buyPrice;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;

  StockInDraftState copyWith({
    SearchVariantResult? selectedVariant,
    int? qty,
    int? buyPrice,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    bool clearVariant = false,
    bool clearError = false,
  }) {
    return StockInDraftState(
      selectedVariant: clearVariant
          ? null
          : selectedVariant ?? this.selectedVariant,
      qty: qty ?? this.qty,
      buyPrice: buyPrice ?? this.buyPrice,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class StockInHistoryState {
  const StockInHistoryState({
    required this.items,
    required this.meta,
    this.selectedDate,
    this.isLoadingMore = false,
  });

  final List<StockInLog> items;
  final PaginationMeta meta;
  final String? selectedDate;
  final bool isLoadingMore;

  bool get hasMore => meta.hasMore;

  StockInHistoryState copyWith({
    List<StockInLog>? items,
    PaginationMeta? meta,
    String? selectedDate,
    bool? isLoadingMore,
  }) {
    return StockInHistoryState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
