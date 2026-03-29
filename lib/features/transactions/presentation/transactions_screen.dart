import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/formatters/app_formatters.dart';
import '../../../core/widgets/app_section_card.dart';
import '../../../core/widgets/variant_picker_sheet.dart';
import '../models/transaction_models.dart';
import 'transaction_controllers.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _TransactionsHeader(),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(children: [_CheckoutTab(), _HistoryTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutTab extends ConsumerStatefulWidget {
  const _CheckoutTab();

  @override
  ConsumerState<_CheckoutTab> createState() => _CheckoutTabState();
}

class _CheckoutTabState extends ConsumerState<_CheckoutTab> {
  late final TextEditingController _paidAmountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _paidAmountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(transactionDraftControllerProvider);
    final controller = ref.read(transactionDraftControllerProvider.notifier);

    ref.listen(transactionDraftControllerProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final hero = _CheckoutHeroCard(
          itemCount: draft.items.length,
          totalAmount: draft.totalAmount,
          paidAmount: draft.paidAmount,
          changeAmount: draft.changeAmount,
          hasItems: draft.items.isNotEmpty,
          onAddItem: () => _pickVariant(controller),
          onSetExactAmount: () {
            _paidAmountController.text = '${draft.totalAmount}';
            controller.setPaidAmountValue(draft.totalAmount);
          },
          onClearDraft: () {
            _paidAmountController.clear();
            _noteController.clear();
            controller.clearDraft();
          },
        );

        final cartPanel = _CartPanel(
          items: draft.items,
          onAddItem: () => _pickVariant(controller),
        );

        final paymentPanel = _PaymentPanel(
          draft: draft,
          paidAmountController: _paidAmountController,
          noteController: _noteController,
          onPaidChanged: controller.updatePaidAmount,
          onNoteChanged: controller.updateNote,
          onSetExactAmount: () {
            _paidAmountController.text = '${draft.totalAmount}';
            controller.setPaidAmountValue(draft.totalAmount);
          },
          onSubmit: () async {
            final receipt = await controller.submit();
            if (receipt != null) {
              if (!context.mounted) {
                return;
              }
              _paidAmountController.clear();
              _noteController.clear();
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionReceiptScreen(detail: receipt),
                ),
              );
            }
          },
        );

        if (!isWide) {
          return ListView(
            children: [
              hero,
              const SizedBox(height: 16),
              cartPanel,
              const SizedBox(height: 16),
              paymentPanel,
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              hero,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: cartPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: paymentPanel),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVariant(TransactionDraftController controller) async {
    final selected = await showVariantPickerSheet(
      context,
      inStockOnly: true,
      title: 'Cari varian untuk checkout',
    );
    if (selected != null) {
      controller.addVariant(selected);
    }
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.headerDark,
                  AppTheme.headerDark.withValues(alpha: 0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POS Kasir',
                  style: textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bangun transaksi cepat: cari varian, atur kuantitas, tetapkan harga, lalu checkout tanpa bolak-balik menu.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.warmPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: [
                  Tab(text: 'Checkout'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutHeroCard extends StatelessWidget {
  const _CheckoutHeroCard({
    required this.itemCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.hasItems,
    required this.onAddItem,
    required this.onSetExactAmount,
    required this.onClearDraft,
  });

  final int itemCount;
  final int totalAmount;
  final int paidAmount;
  final int changeAmount;
  final bool hasItems;
  final VoidCallback onAddItem;
  final VoidCallback onSetExactAmount;
  final VoidCallback onClearDraft;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.warmPrimary.withValues(alpha: 0.16),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checkout aktif',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Semua aksi utama untuk kasir diletakkan di satu area: tambah item, uang pas, dan reset transaksi.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeroMetric(
                  label: 'Item',
                  value: '$itemCount',
                  tone: AppTheme.headerDark,
                ),
                _HeroMetric(
                  label: 'Total',
                  value: AppFormatters.rupiah(totalAmount),
                  tone: AppTheme.warmPrimary,
                ),
                _HeroMetric(
                  label: 'Bayar',
                  value: AppFormatters.rupiah(paidAmount),
                  tone: AppTheme.info,
                ),
                _HeroMetric(
                  label: 'Kembalian',
                  value: AppFormatters.rupiah(changeAmount),
                  tone: changeAmount < 0
                      ? AppTheme.warmAccent
                      : AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Tambah Item'),
                ),
                OutlinedButton.icon(
                  onPressed: hasItems ? onSetExactAmount : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Uang Pas'),
                ),
                OutlinedButton.icon(
                  onPressed: hasItems ? onClearDraft : null,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('Kosongkan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.items, required this.onAddItem});

  final List<CartItemDraft> items;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keranjang',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items.isEmpty
                          ? 'Belum ada item yang siap dijual.'
                          : '${items.length} item sedang disiapkan untuk checkout.',
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Cari Varian'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _EmptyCartState(onAddItem: onAddItem)
          else
            Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CartItemCard(item: item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({required this.onAddItem});

  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.warmPrimary.withValues(alpha: 0.14),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: AppTheme.warmPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keranjang masih kosong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai dengan mencari varian dari katalog yang stoknya tersedia.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Tambah Varian'),
          ),
        ],
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.draft,
    required this.paidAmountController,
    required this.noteController,
    required this.onPaidChanged,
    required this.onNoteChanged,
    required this.onSetExactAmount,
    required this.onSubmit,
  });

  final TransactionDraftState draft;
  final TextEditingController paidAmountController;
  final TextEditingController noteController;
  final ValueChanged<String> onPaidChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onSetExactAmount;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.headerDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.rupiah(draft.totalAmount),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: paidAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Nominal bayar',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  onChanged: onPaidChanged,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: draft.items.isEmpty ? null : onSetExactAmount,
                  icon: const Icon(Icons.price_check_outlined),
                  label: const Text('Isi Uang Pas'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan transaksi',
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  ),
                  onChanged: onNoteChanged,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Total',
                        value: AppFormatters.rupiah(draft.totalAmount),
                      ),
                      _SummaryRow(
                        label: 'Bayar',
                        value: AppFormatters.rupiah(draft.paidAmount),
                      ),
                      _SummaryRow(
                        label: 'Kembalian',
                        value: AppFormatters.rupiah(draft.changeAmount),
                        valueColor: draft.changeAmount < 0
                            ? AppTheme.warmAccent
                            : AppTheme.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: draft.isSubmitting ? null : onSubmit,
                    icon: draft.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.receipt_long_rounded),
                    label: Text(
                      draft.isSubmitting ? 'Memproses...' : 'Checkout Sekarang',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({required this.item});

  final CartItemDraft item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(transactionDraftControllerProvider.notifier);
    final stockTone = item.currentStock > 0
        ? AppTheme.success
        : AppTheme.warmAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.warmPrimary.withValues(alpha: 0.14),
                foregroundColor: AppTheme.warmPrimary,
                child: const Icon(Icons.devices_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          label: 'Stok ${item.currentStock}',
                          background: stockTone.withValues(alpha: 0.12),
                          foreground: stockTone,
                        ),
                        _Pill(
                          label:
                              'Harga ${AppFormatters.rupiah(item.sellPrice)}',
                          background: AppTheme.headerDark.withValues(
                            alpha: 0.08,
                          ),
                          foreground: AppTheme.headerDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.removeItem(item.variantId),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _QtyStepper(
                qty: item.qty,
                onDecrease: () => controller.decreaseQty(item.variantId),
                onIncrease: () => controller.increaseQty(item.variantId),
              ),
              OutlinedButton.icon(
                onPressed: () => _showPriceEditor(context, controller, item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah Harga'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Subtotal ${AppFormatters.rupiah(item.subtotal)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPriceEditor(
    BuildContext context,
    TransactionDraftController controller,
    CartItemDraft item,
  ) async {
    final textController = TextEditingController(text: '${item.sellPrice}');
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah harga jual'),
          content: TextFormField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Harga jual'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.updateSellPrice(
                  item.variantId,
                  int.tryParse(textController.text) ?? item.sellPrice,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
            visualDensity: VisualDensity.compact,
          ),
          Text('$qty', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HistoryTabLegacy extends ConsumerWidget {
  const _HistoryTabLegacy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(transactionHistoryControllerProvider);
    final controller = ref.read(transactionHistoryControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        children: [
          AppSectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat transaksi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Buka detail transaksi sebelumnya dan pantau transaksi per tanggal.',
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      await controller.setDate(
                        AppFormatters.apiDate.format(picked),
                      );
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Filter Tanggal'),
                ),
                OutlinedButton(
                  onPressed: () => controller.setDate(null),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          history.when(
            data: (data) {
              if (data.items.isEmpty) {
                return const AppSectionCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('Belum ada transaksi.')),
                  ),
                );
              }

              return Column(
                children: [
                  ...data.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSectionCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.transactionCode),
                          subtitle: Text(
                            '${item.itemCount} item • ${item.createdAt == null ? '-' : AppFormatters.dateTime.format(item.createdAt!)}',
                          ),
                          trailing: Text(
                            AppFormatters.rupiah(item.totalAmount),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TransactionDetailScreen(
                                  transactionId: item.transactionId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (data.hasMore)
                    OutlinedButton(
                      onPressed: data.isLoadingMore
                          ? null
                          : controller.loadMore,
                      child: data.isLoadingMore
                          ? const CircularProgressIndicator()
                          : const Text('Muat lagi'),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat gagal dimuat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.refresh,
                    child: const Text('Coba lagi'),
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

class TransactionReceiptScreenLegacy extends StatelessWidget {
  const TransactionReceiptScreenLegacy({super.key, required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk Transaksi')),
      body: _ReceiptBody(detail: detail),
    );
  }
}

class TransactionDetailScreenLegacy extends ConsumerWidget {
  const TransactionDetailScreenLegacy({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transactionDetailProvider(transactionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: detail.when(
        data: (value) => _ReceiptBody(detail: value),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

// ignore: unused_element
class _ReceiptBodyLegacy extends StatelessWidget {
  const _ReceiptBodyLegacy({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.transactionCode,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Kasir: ${detail.kasir}'),
              Text(
                detail.createdAt == null
                    ? '-'
                    : AppFormatters.dateTime.format(detail.createdAt!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...detail.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.displayName),
                  subtitle: Text(
                    '${item.qty} x ${AppFormatters.rupiah(item.sellPrice)}',
                  ),
                  trailing: Text(AppFormatters.rupiah(item.subtotal)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            children: [
              _SummaryRow(
                label: 'Total',
                value: AppFormatters.rupiah(detail.totalAmount),
              ),
              _SummaryRow(
                label: 'Bayar',
                value: AppFormatters.rupiah(detail.paidAmount),
              ),
              _SummaryRow(
                label: 'Kembalian',
                value: AppFormatters.rupiah(detail.changeAmount),
              ),
              if (detail.note != null && detail.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Catatan: ${detail.note}'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _SummaryRowLegacy extends StatelessWidget {
  const _SummaryRowLegacy({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(transactionHistoryControllerProvider);
    final controller = ref.read(transactionHistoryControllerProvider.notifier);
    final selectedDate = history.asData?.value.selectedDate;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        children: [
          AppSectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat transaksi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buka ulang transaksi yang sudah selesai tanpa mengganggu checkout aktif.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      await controller.setDate(
                        AppFormatters.apiDate.format(picked),
                      );
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Filter Tanggal'),
                ),
                if (selectedDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Tanggal $selectedDate',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                OutlinedButton(
                  onPressed: () => controller.setDate(null),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          history.when(
            data: (data) {
              if (data.items.isEmpty) {
                return const AppSectionCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('Belum ada transaksi.')),
                  ),
                );
              }

              return Column(
                children: [
                  ...data.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSectionCard(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TransactionDetailScreen(
                                  transactionId: item.transactionId,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppTheme.warmPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppTheme.warmPrimary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.transactionCode,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.createdAt == null
                                            ? '${item.itemCount} item'
                                            : '${item.itemCount} item - ${AppFormatters.dateTime.format(item.createdAt!)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.rupiah(item.totalAmount),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.headerDark,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Buka detail',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (data.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: OutlinedButton.icon(
                        onPressed: data.isLoadingMore
                            ? null
                            : controller.loadMore,
                        icon: data.isLoadingMore
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more_rounded),
                        label: Text(
                          data.isLoadingMore ? 'Memuat...' : 'Muat lagi',
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat gagal dimuat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.refresh,
                    child: const Text('Coba lagi'),
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

class TransactionReceiptScreen extends StatelessWidget {
  const TransactionReceiptScreen({super.key, required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk Transaksi')),
      body: _ReceiptBody(detail: detail),
    );
  }
}

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transactionDetailProvider(transactionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: detail.when(
        data: (value) => _ReceiptBody(detail: value),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.headerDark,
                  AppTheme.headerDark.withValues(alpha: 0.86),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.transactionCode,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kasir: ${detail.kasir}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  detail.createdAt == null
                      ? '-'
                      : AppFormatters.dateTime.format(detail.createdAt!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item transaksi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...detail.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.headerDark.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.headerDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.qty} x ${AppFormatters.rupiah(item.sellPrice)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppFormatters.rupiah(item.subtotal),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.headerDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            children: [
              _SummaryRow(
                label: 'Total',
                value: AppFormatters.rupiah(detail.totalAmount),
              ),
              _SummaryRow(
                label: 'Bayar',
                value: AppFormatters.rupiah(detail.paidAmount),
              ),
              _SummaryRow(
                label: 'Kembalian',
                value: AppFormatters.rupiah(detail.changeAmount),
                valueColor: detail.changeAmount < 0
                    ? AppTheme.warmAccent
                    : AppTheme.success,
              ),
              if (detail.note != null && detail.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Catatan: ${detail.note}'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
