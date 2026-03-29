import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_section_card.dart';
import '../models/dashboard_summary.dart';

final dashboardProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchDashboard();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 3 : 2;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          dashboard.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: width >= 900 ? 1.6 : 1.2,
                  children: [
                    _StatCard(
                      title: 'Transaksi Hari Ini',
                      value: '${data.today.totalTransactions}',
                      subtitle: data.today.date,
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _StatCard(
                      title: 'Pendapatan Hari Ini',
                      value: AppFormatters.rupiah(data.today.totalRevenue),
                      subtitle: 'Dari semua transaksi kasir',
                      icon: Icons.trending_up_rounded,
                    ),
                    _StatCard(
                      title: 'Izin Stok',
                      value: data.permissions.canInputStock ? 'Aktif' : 'Nonaktif',
                      subtitle: data.permissions.canInputStock
                          ? 'Kasir dapat input stok'
                          : 'Menu stok masuk disembunyikan',
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert stok menipis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.lowStockAlerts.isEmpty
                            ? 'Belum ada alert stok rendah hari ini.'
                            : 'Varian di bawah batas minimum stok akan muncul di sini.',
                      ),
                      const SizedBox(height: 16),
                      if (data.lowStockAlerts.isEmpty)
                        const _EmptyList(label: 'Belum ada alert inventaris.')
                      else
                        ...data.lowStockAlerts.map(
                          (alert) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.warning_amber_rounded),
                            ),
                            title: Text(alert.displayName),
                            subtitle: Text(
                              'Stok ${alert.currentStock} dari minimum ${alert.minStock}',
                            ),
                            trailing: Text(
                              '${alert.currentStock}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard gagal dimuat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(dashboardProvider),
                    child: const Text('Muat ulang'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(icon),
          ),
          const Spacer(),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(subtitle),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text(label)),
    );
  }
}
