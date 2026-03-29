import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../core/widgets/app_section_card.dart';
import '../../../core/widgets/variant_picker_sheet.dart';
import 'stock_in_controllers.dart';

class StockInScreen extends ConsumerWidget {
  const StockInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(stockInHistoryControllerProvider);
    final controller = ref.read(stockInHistoryControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stok Masuk',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Catat barang masuk dan pantau snapshot stok setelah input.',
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => const _CreateStockInSheet(),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Input Stok'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat stok masuk',
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
                    child: Center(child: Text('Belum ada riwayat stok masuk.')),
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
                          title: Text(item.variant),
                          subtitle: Text(
                            '${item.qty} unit • ${AppFormatters.rupiah(item.buyPrice)} • ${item.createdAt == null ? '-' : AppFormatters.dateTime.format(item.createdAt!)}',
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Stok akhir'),
                              Text(
                                '${item.stockAfter}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
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
                    'Riwayat stok gagal dimuat',
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

class _CreateStockInSheet extends ConsumerStatefulWidget {
  const _CreateStockInSheet();

  @override
  ConsumerState<_CreateStockInSheet> createState() => _CreateStockInSheetState();
}

class _CreateStockInSheetState extends ConsumerState<_CreateStockInSheet> {
  late final TextEditingController _qtyController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
    _buyPriceController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _buyPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(stockInDraftControllerProvider);
    final controller = ref.read(stockInDraftControllerProvider.notifier);

    ref.listen(stockInDraftControllerProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input stok masuk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showVariantPickerSheet(
                  context,
                  inStockOnly: false,
                  title: 'Cari varian untuk stok masuk',
                );
                if (selected != null) {
                  controller.selectVariant(selected);
                }
              },
              icon: const Icon(Icons.search_rounded),
              label: Text(
                draft.selectedVariant?.displayName ?? 'Pilih varian',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Qty'),
              onChanged: controller.updateQty,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _buyPriceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Harga beli'),
              onChanged: controller.updateBuyPrice,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan'),
              onChanged: controller.updateNote,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: draft.isSubmitting
                    ? null
                    : () async {
                        final result = await controller.submit();
                        if (result != null) {
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Stok masuk berhasil dicatat. Stok setelah input: ${result.stockAfter}',
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
                    : const Text('Simpan Stok Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
