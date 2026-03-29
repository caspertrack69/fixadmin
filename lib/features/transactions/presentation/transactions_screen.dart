import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi Kasir',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola checkout dan lihat riwayat transaksi dari akun kasir yang sedang aktif.',
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Checkout'),
                      Tab(text: 'Riwayat'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  _CheckoutTab(),
                  _HistoryTab(),
                ],
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return ListView(
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Keranjang Checkout',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final selected = await showVariantPickerSheet(
                        context,
                        inStockOnly: true,
                        title: 'Cari varian untuk checkout',
                      );
                      if (selected != null) {
                        controller.addVariant(selected);
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Tambah Item'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (draft.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Belum ada item di keranjang.'),
                  ),
                )
              else
                ...draft.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemCard(item: item),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayaran',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal bayar',
                ),
                onChanged: controller.updatePaidAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                ),
                onChanged: controller.updateNote,
              ),
              const SizedBox(height: 16),
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: draft.isSubmitting
                      ? null
                      : () async {
                          final receipt = await controller.submit();
                          if (receipt != null) {
                            if (!context.mounted) {
                              return;
                            }
                            _paidAmountController.clear();
                            _noteController.clear();
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TransactionReceiptScreen(
                                  detail: receipt,
                                ),
                              ),
                            );
                          }
                        },
                  child: draft.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Checkout Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({
    required this.item,
  });

  final CartItemDraft item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(transactionDraftControllerProvider.notifier);

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
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => controller.removeItem(item.variantId),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          Text('Stok tersedia: ${item.currentStock}'),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.decreaseQty(item.variantId),
                icon: const Icon(Icons.remove),
                label: Text('Qty ${item.qty}'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => controller.increaseQty(item.variantId),
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showPriceEditor(context, controller, item),
                child: Text(AppFormatters.rupiah(item.sellPrice)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal: ${AppFormatters.rupiah(item.subtotal)}',
            style: Theme.of(context).textTheme.titleMedium,
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

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(transactionHistoryControllerProvider);
    final controller = ref.read(transactionHistoryControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        children: [
          AppSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Transaksi',
                    style: Theme.of(context).textTheme.titleLarge,
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
                      await controller.setDate(AppFormatters.apiDate.format(picked));
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Filter Tanggal'),
                ),
                const SizedBox(width: 8),
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
                          trailing: Text(AppFormatters.rupiah(item.totalAmount)),
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
                      onPressed: data.isLoadingMore ? null : controller.loadMore,
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

class TransactionReceiptScreen extends StatelessWidget {
  const TransactionReceiptScreen({
    super.key,
    required this.detail,
  });

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
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

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
  const _ReceiptBody({
    required this.detail,
  });

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
              Text(
                'Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...detail.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.displayName),
                  subtitle: Text('${item.qty} x ${AppFormatters.rupiah(item.sellPrice)}'),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
