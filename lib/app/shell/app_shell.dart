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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ShellAppBar(
              session: widget.session,
              activeLabel: _labelForTab(_selectedTab),
              onProfileTap: _showProfileSheet,
            ),
            Expanded(
              child: IndexedStack(index: pageIndex, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ShellBottomNavigation(
        visibleTabs: visibleTabs,
        selectedTab: _selectedTab,
        labelForTab: _labelForTab,
        iconForTab: _iconForTab,
        onSelected: (tab) {
          setState(() {
            _selectedTab = tab;
          });
        },
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

class _ShellAppBar extends StatelessWidget {
  const _ShellAppBar({
    required this.session,
    required this.activeLabel,
    required this.onProfileTap,
  });

  final AuthSession session;
  final String activeLabel;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.headerDark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kasirfix',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$activeLabel - ${AppFormatters.headerDate.format(DateTime.now())}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ProfileButton(session: session, onTap: onProfileTap),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.session, required this.onTap});

  final AuthSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.headerDark,
                child: Text(
                  session.user.name.characters.first.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: AppTheme.headerDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                session.user.role.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBottomNavigation extends StatelessWidget {
  const _ShellBottomNavigation({
    required this.visibleTabs,
    required this.selectedTab,
    required this.labelForTab,
    required this.iconForTab,
    required this.onSelected,
  });

  final List<ShellTab> visibleTabs;
  final ShellTab selectedTab;
  final String Function(ShellTab tab) labelForTab;
  final IconData Function(ShellTab tab) iconForTab;
  final ValueChanged<ShellTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: visibleTabs
                  .map(
                    (tab) => Expanded(
                      child: _ShellNavItem(
                        icon: iconForTab(tab),
                        label: labelForTab(tab),
                        selected: tab == selectedTab,
                        onTap: () => onSelected(tab),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 42,
                width: selected ? 56 : 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.headerDark
                      : AppTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppTheme.headerDark
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  size: selected ? 22 : 20,
                ),
              ),
              const SizedBox(height: 7),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                  color: selected
                      ? AppTheme.headerDark
                      : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
