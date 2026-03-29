import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/formatters/app_formatters.dart';
import '../../features/auth/models/auth_session.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/printer/presentation/printer_settings_screen.dart';
import '../../features/stock_in/presentation/stock_in_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';

enum ShellTab { dashboard, inventory, transactions, stockIn }

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.session});

  final AuthSession session;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ShellTab _selectedTab = ShellTab.dashboard;

  List<ShellTab> get _visibleTabs {
    return [
      ShellTab.dashboard,
      ShellTab.inventory,
      ShellTab.transactions,
      if (widget.session.user.canInputStock) ShellTab.stockIn,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visibleTabs = _visibleTabs;
    if (!visibleTabs.contains(_selectedTab)) {
      _selectedTab = ShellTab.dashboard;
    }

    final pageIndex = visibleTabs.indexOf(_selectedTab);
    final pages = visibleTabs.map(_buildPage).toList();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.headerDate.format(DateTime.now()),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kasirfix',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mode aktif: ${_labelForTab(_selectedTab)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _showProfileSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            child: Text(
                              widget.session.user.name.characters.first,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.session.user.name,
                                style: textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.session.user.role.toUpperCase(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(index: pageIndex, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 74,
          indicatorColor: AppTheme.headerDark,
          backgroundColor: Colors.white,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: AppTheme.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final base = textTheme.labelMedium;
            if (states.contains(WidgetState.selected)) {
              return base?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              );
            }
            return base?.copyWith(color: AppTheme.textSecondary);
          }),
        ),
        child: NavigationBar(
          selectedIndex: pageIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedTab = visibleTabs[index];
            });
          },
          destinations: visibleTabs
              .map(
                (tab) => NavigationDestination(
                  icon: Icon(_iconForTab(tab)),
                  selectedIcon: Icon(_iconForTab(tab)),
                  label: _labelForTab(tab),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPage(ShellTab tab) {
    return switch (tab) {
      ShellTab.dashboard => const DashboardScreen(),
      ShellTab.inventory => const InventoryScreen(),
      ShellTab.transactions => const TransactionsScreen(),
      ShellTab.stockIn => const StockInScreen(),
    };
  }

  IconData _iconForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.dashboard => Icons.dashboard_outlined,
      ShellTab.inventory => Icons.inventory_2_outlined,
      ShellTab.transactions => Icons.receipt_long_outlined,
      ShellTab.stockIn => Icons.inventory_outlined,
    };
  }

  String _labelForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.dashboard => 'Dashboard',
      ShellTab.inventory => 'Inventaris',
      ShellTab.transactions => 'Transaksi',
      ShellTab.stockIn => 'Stok Masuk',
    };
  }

  Future<void> _showProfileSheet() async {
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.session.user.name, style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.session.user.email),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: Text(widget.session.user.role.toUpperCase()),
                subtitle: Text(
                  widget.session.user.canInputStock
                      ? 'Memiliki akses stok masuk'
                      : 'Tanpa akses stok masuk',
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_outlined),
                title: const Text('Printer & Struk'),
                subtitle: const Text('Atur printer dan format cetak'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Navigator.of(this.context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrinterSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await ref.read(sessionControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
