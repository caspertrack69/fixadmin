import '../../../core/utils/json_parsers.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.today,
    required this.permissions,
    required this.lowStockAlerts,
  });

  final TodaySummary today;
  final DashboardPermissions permissions;
  final List<LowStockAlert> lowStockAlerts;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawToday = json['today'] as Map<String, dynamic>? ?? const {};
    final rawPermissions =
        json['permissions'] as Map<String, dynamic>? ?? const {};
    final rawAlerts = json['low_stock_alert'] as List? ?? const [];

    return DashboardSummary(
      today: TodaySummary.fromJson(rawToday),
      permissions: DashboardPermissions.fromJson(rawPermissions),
      lowStockAlerts: rawAlerts
          .whereType<Map>()
          .map(
            (item) => LowStockAlert.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(),
    );
  }
}

class TodaySummary {
  const TodaySummary({
    required this.date,
    required this.totalTransactions,
    required this.totalRevenue,
  });

  final String date;
  final int totalTransactions;
  final int totalRevenue;

  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    return TodaySummary(
      date: parseString(json['date']),
      totalTransactions: parseInt(json['total_transactions']),
      totalRevenue: parseInt(json['total_revenue']),
    );
  }
}

class DashboardPermissions {
  const DashboardPermissions({required this.canInputStock});

  final bool canInputStock;

  factory DashboardPermissions.fromJson(Map<String, dynamic> json) {
    return DashboardPermissions(
      canInputStock: parseBool(json['can_input_stock']),
    );
  }
}

class LowStockAlert {
  const LowStockAlert({
    required this.variantId,
    required this.displayName,
    required this.currentStock,
    required this.minStock,
  });

  final int variantId;
  final String displayName;
  final int currentStock;
  final int minStock;

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    return LowStockAlert(
      variantId: parseInt(json['variant_id']),
      displayName: parseString(json['display_name']),
      currentStock: parseInt(json['current_stock']),
      minStock: parseInt(json['min_stock']),
    );
  }
}
