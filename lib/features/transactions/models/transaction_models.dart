import '../../../core/models/paged_response.dart';

class SearchVariantResult {
  const SearchVariantResult({
    required this.variantId,
    required this.displayName,
    required this.category,
    required this.model,
    required this.part,
    required this.grade,
    required this.sellPrice,
    required this.currentStock,
    this.photoUrl,
  });

  final int variantId;
  final String displayName;
  final String category;
  final String model;
  final String part;
  final String grade;
  final int sellPrice;
  final int currentStock;
  final String? photoUrl;

  factory SearchVariantResult.fromJson(Map<String, dynamic> json) {
    return SearchVariantResult(
      variantId: (json['variant_id'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String? ?? '-',
      category: json['category'] as String? ?? '-',
      model: json['model'] as String? ?? '-',
      part: json['part'] as String? ?? '-',
      grade: json['grade'] as String? ?? '-',
      sellPrice: (json['sell_price'] as num?)?.toInt() ?? 0,
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class TransactionHistoryItem {
  const TransactionHistoryItem({
    required this.transactionId,
    required this.transactionCode,
    required this.totalAmount,
    required this.itemCount,
    required this.createdAt,
  });

  final int transactionId;
  final String transactionCode;
  final int totalAmount;
  final int itemCount;
  final DateTime? createdAt;

  factory TransactionHistoryItem.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryItem(
      transactionId: (json['transaction_id'] as num?)?.toInt() ?? 0,
      transactionCode: json['transaction_code'] as String? ?? '-',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
    );
  }
}

class TransactionLineItem {
  const TransactionLineItem({
    required this.displayName,
    required this.qty,
    required this.sellPrice,
    required this.subtotal,
  });

  final String displayName;
  final int qty;
  final int sellPrice;
  final int subtotal;

  factory TransactionLineItem.fromJson(Map<String, dynamic> json) {
    return TransactionLineItem(
      displayName: json['display_name'] as String? ?? '-',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sell_price'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class TransactionDetail {
  const TransactionDetail({
    required this.transactionId,
    required this.transactionCode,
    required this.kasir,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.note,
    required this.createdAt,
  });

  final int transactionId;
  final String transactionCode;
  final String kasir;
  final List<TransactionLineItem> items;
  final int totalAmount;
  final int paidAmount;
  final int changeAmount;
  final String? note;
  final DateTime? createdAt;

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return TransactionDetail(
      transactionId: (json['transaction_id'] as num?)?.toInt() ?? 0,
      transactionCode: json['transaction_code'] as String? ?? '-',
      kasir: json['kasir'] as String? ?? '-',
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => TransactionLineItem.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(),
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toInt() ?? 0,
      changeAmount: (json['change_amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
    );
  }
}

class TransactionPayloadItem {
  const TransactionPayloadItem({
    required this.variantId,
    required this.qty,
    required this.sellPrice,
  });

  final int variantId;
  final int qty;
  final int sellPrice;

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'qty': qty,
      'sell_price': sellPrice,
    };
  }
}

class CartItemDraft {
  const CartItemDraft({
    required this.variantId,
    required this.displayName,
    required this.sellPrice,
    required this.currentStock,
    this.photoUrl,
    this.qty = 1,
  });

  final int variantId;
  final String displayName;
  final int sellPrice;
  final int currentStock;
  final String? photoUrl;
  final int qty;

  int get subtotal => qty * sellPrice;

  CartItemDraft copyWith({
    int? sellPrice,
    int? currentStock,
    String? photoUrl,
    int? qty,
  }) {
    return CartItemDraft(
      variantId: variantId,
      displayName: displayName,
      sellPrice: sellPrice ?? this.sellPrice,
      currentStock: currentStock ?? this.currentStock,
      photoUrl: photoUrl ?? this.photoUrl,
      qty: qty ?? this.qty,
    );
  }

  factory CartItemDraft.fromSearch(SearchVariantResult item) {
    return CartItemDraft(
      variantId: item.variantId,
      displayName: item.displayName,
      sellPrice: item.sellPrice,
      currentStock: item.currentStock,
      photoUrl: item.photoUrl,
    );
  }
}

class TransactionHistoryState {
  const TransactionHistoryState({
    required this.items,
    required this.meta,
    this.selectedDate,
    this.isLoadingMore = false,
  });

  final List<TransactionHistoryItem> items;
  final PaginationMeta meta;
  final String? selectedDate;
  final bool isLoadingMore;

  bool get hasMore => meta.hasMore;

  TransactionHistoryState copyWith({
    List<TransactionHistoryItem>? items,
    PaginationMeta? meta,
    String? selectedDate,
    bool? isLoadingMore,
    bool clearDate = false,
  }) {
    return TransactionHistoryState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
