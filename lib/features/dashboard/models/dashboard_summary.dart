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
      date: json['date'] as String? ?? '-',
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardPermissions {
  const DashboardPermissions({
    required this.canInputStock,
  });

  final bool canInputStock;

  factory DashboardPermissions.fromJson(Map<String, dynamic> json) {
    return DashboardPermissions(
      canInputStock: json['can_input_stock'] as bool? ?? false,
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
      variantId: (json['variant_id'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String? ?? '-',
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      minStock: (json['min_stock'] as num?)?.toInt() ?? 0,
    );
  }
}
