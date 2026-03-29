import '../utils/json_parsers.dart';

class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: parseInt(json['current_page'], fallback: 1),
      lastPage: parseInt(json['last_page'], fallback: 1),
      perPage: parseInt(json['per_page'], fallback: 20),
      total: parseInt(json['total']),
    );
  }
}

class PagedResponse<T> {
  const PagedResponse({
    required this.data,
    required this.meta,
  });

  final List<T> data;
  final PaginationMeta meta;
}
