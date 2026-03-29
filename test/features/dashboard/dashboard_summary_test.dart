import 'package:flutter_test/flutter_test.dart';
import 'package:fixadmin/features/dashboard/models/dashboard_summary.dart';

void main() {
  test('parses numeric dashboard fields when backend sends strings', () {
    final summary = DashboardSummary.fromJson({
      'today': {
        'date': '2026-03-29',
        'total_transactions': '5',
        'total_revenue': '1500000',
      },
      'permissions': {
        'can_input_stock': '1',
      },
      'low_stock_alert': [
        {
          'variant_id': '3',
          'display_name': 'iPhone - LCD - Grade A',
          'current_stock': '1',
          'min_stock': '3',
        },
      ],
    });

    expect(summary.today.totalTransactions, 5);
    expect(summary.today.totalRevenue, 1500000);
    expect(summary.permissions.canInputStock, isTrue);
    expect(summary.lowStockAlerts.first.variantId, 3);
    expect(summary.lowStockAlerts.first.currentStock, 1);
    expect(summary.lowStockAlerts.first.minStock, 3);
  });
}
