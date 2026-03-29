import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/formatters/app_formatters.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_section_card.dart';
import '../../inventory/models/inventory_models.dart';
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
  static const double _cartBarHeight = 64;

  late final TextEditingController _queryController;
  Timer? _debounce;
  bool _isBootstrapping = true;
  bool _isSearching = false;
  String? _searchError;
  String _lastQuery = '';
  List<SearchVariantResult> _catalogVariants = const [];
  List<SearchVariantResult> _visibleVariants = const [];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _queryController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    unawaited(_loadCatalogVariants());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
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

    return Stack(
      children: [
        Column(
          children: [
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Produk POS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Cari produk, part, model, atau kategori...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _queryController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _queryController.clear();
                                _applyLocalSearch('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    onChanged: _onQueryChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildProductsSection(
                context: context,
                controller: controller,
                hasCartBar: draft.items.isNotEmpty,
              ),
            ),
          ],
        ),
        if (draft.items.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CheckoutCartBottomBar(
              itemCount: draft.items.length,
              total: draft.totalAmount,
              onTap: _openCheckoutSheet,
            ),
          ),
      ],
    );
  }

  Widget _buildProductsSection({
    required BuildContext context,
    required TransactionDraftController controller,
    required bool hasCartBar,
  }) {
    if (_isBootstrapping) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null && _visibleVariants.isEmpty) {
      return AppSectionCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_tethering_error_rounded,
              size: 34,
              color: AppTheme.warmAccent,
            ),
            const SizedBox(height: 10),
            Text(
              'Produk gagal dimuat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(_searchError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retrySearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (_visibleVariants.isEmpty) {
      return const AppSectionCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Produk tidak ditemukan.')),
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.only(
            bottom: hasCartBar ? _cartBarHeight + 28 : 8,
          ),
          itemCount: _visibleVariants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _visibleVariants[index];
            return _PosVariantCard(
              item: item,
              onAdd: () {
                controller.addVariant(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.grade} ditambahkan')),
                );
              },
            );
          },
        ),
        if (_isSearching)
          const Positioned(
            top: 10,
            right: 10,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Future<void> _openCheckoutSheet() async {
    final receipt = await showModalBottomSheet<TransactionDetail>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CheckoutCartSheet(),
    );

    if (receipt == null || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionReceiptScreen(detail: receipt),
      ),
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      final query = value.trim();
      _lastQuery = query;
      if (query.length < 2) {
        _applyLocalSearch(query);
        return;
      }
      unawaited(_searchRemote(query));
    });
  }

  Future<void> _loadCatalogVariants() async {
    try {
      final tree = await ref
          .read(inventoryRepositoryProvider)
          .fetchCatalogTree();
      if (!mounted) {
        return;
      }
      final flattened = _flattenTree(tree)
        ..retainWhere((item) => item.currentStock > 0);

      setState(() {
        _catalogVariants = flattened;
        _visibleVariants = _sortForDisplay(flattened).take(60).toList();
        _isBootstrapping = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrapping = false;
        _searchError = '$error';
      });
    }
  }

  List<SearchVariantResult> _flattenTree(List<Category> categories) {
    final variants = <SearchVariantResult>[];
    for (final category in categories) {
      for (final model in category.models) {
        for (final part in model.parts) {
          for (final variant in part.variants) {
            variants.add(
              SearchVariantResult.fromCatalogNode(
                variantId: variant.id,
                category: category.name,
                model: model.name,
                part: part.name,
                grade: variant.name,
                sellPrice: variant.sellPrice,
                currentStock: variant.currentStock,
                photoUrl: variant.photoUrl,
              ),
            );
          }
        }
      }
    }
    return variants;
  }

  void _applyLocalSearch(String query) {
    final normalized = query.toLowerCase().trim();
    final filtered = _catalogVariants.where((item) {
      if (item.currentStock <= 0) {
        return false;
      }
      if (normalized.isEmpty) {
        return true;
      }
      return item.displayName.toLowerCase().contains(normalized) ||
          item.category.toLowerCase().contains(normalized) ||
          item.model.toLowerCase().contains(normalized) ||
          item.part.toLowerCase().contains(normalized) ||
          item.grade.toLowerCase().contains(normalized);
    }).toList();

    setState(() {
      _searchError = null;
      _isSearching = false;
      final sorted = _sortForDisplay(filtered);
      _visibleVariants = normalized.isEmpty ? sorted.take(60).toList() : sorted;
    });
  }

  Future<void> _searchRemote(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final response = await ref
          .read(transactionsRepositoryProvider)
          .searchVariants(query: query, inStock: true);
      if (!mounted) {
        return;
      }

      final normalized = query.toLowerCase();
      final local = _catalogVariants.where((item) {
        return item.displayName.toLowerCase().contains(normalized) ||
            item.category.toLowerCase().contains(normalized) ||
            item.model.toLowerCase().contains(normalized) ||
            item.part.toLowerCase().contains(normalized) ||
            item.grade.toLowerCase().contains(normalized);
      });
      final merged = _mergeSearchResults(response.data, local.toList());
      setState(() {
        _visibleVariants = _sortForDisplay(merged);
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final normalized = query.toLowerCase();
      final fallback = _catalogVariants.where((item) {
        return item.displayName.toLowerCase().contains(normalized) ||
            item.category.toLowerCase().contains(normalized) ||
            item.model.toLowerCase().contains(normalized) ||
            item.part.toLowerCase().contains(normalized) ||
            item.grade.toLowerCase().contains(normalized);
      }).toList();
      setState(() {
        _visibleVariants = _sortForDisplay(fallback);
        _searchError = fallback.isEmpty ? '$error' : null;
        _isSearching = false;
      });
    }
  }

  List<SearchVariantResult> _mergeSearchResults(
    List<SearchVariantResult> remote,
    List<SearchVariantResult> local,
  ) {
    final seen = <int>{};
    final merged = <SearchVariantResult>[];

    for (final item in [...remote, ...local]) {
      if (item.currentStock <= 0) {
        continue;
      }
      if (seen.add(item.variantId)) {
        merged.add(item);
      }
    }
    return merged;
  }

  List<SearchVariantResult> _sortForDisplay(List<SearchVariantResult> items) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final stockCompare = right.currentStock.compareTo(left.currentStock);
      if (stockCompare != 0) {
        return stockCompare;
      }
      return left.displayName.compareTo(right.displayName);
    });
    return sorted;
  }

  void _retrySearch() {
    if (_lastQuery.length >= 2) {
      unawaited(_searchRemote(_lastQuery));
      return;
    }
    unawaited(_loadCatalogVariants());
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
                  'Transaksi POS',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
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
                  Tab(text: 'POS'),
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

class _PosVariantCard extends StatelessWidget {
  const _PosVariantCard({required this.item, required this.onAdd});

  final SearchVariantResult item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.warmPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stok: ${item.currentStock}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'HARGA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.rupiah(item.sellPrice),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC8A733),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutCartBottomBar extends StatelessWidget {
  const _CheckoutCartBottomBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  final int itemCount;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFC8A733),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Lihat Keranjang ($itemCount)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.rupiah(total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutCartSheet extends ConsumerStatefulWidget {
  const _CheckoutCartSheet();

  @override
  ConsumerState<_CheckoutCartSheet> createState() => _CheckoutCartSheetState();
}

class _CheckoutCartSheetState extends ConsumerState<_CheckoutCartSheet> {
  late final TextEditingController _paidAmountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(transactionDraftControllerProvider);
    _paidAmountController = TextEditingController(
      text: draft.paidAmount == 0 ? '' : '${draft.paidAmount}',
    );
    _noteController = TextEditingController(text: draft.note);
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _CartPanel(
                items: draft.items,
                onAddItem: () => Navigator.of(context).pop(),
                addLabel: 'Kembali ke POS',
              ),
              const SizedBox(height: 16),
              _PaymentPanel(
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
                  if (receipt == null || !context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(receipt);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.items,
    required this.onAddItem,
    this.addLabel = 'Cari Varian',
  });

  final List<CartItemDraft> items;
  final VoidCallback onAddItem;
  final String addLabel;

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
                label: Text(addLabel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _EmptyCartState(onAddItem: onAddItem, addLabel: addLabel)
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
  const _EmptyCartState({
    required this.onAddItem,
    this.addLabel = 'Tambah Varian',
  });

  final VoidCallback onAddItem;
  final String addLabel;

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
            label: Text(addLabel),
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

class TransactionReceiptScreen extends ConsumerWidget {
  const TransactionReceiptScreen({super.key, required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        actions: [_ReceiptPrintButton(detail: detail, autoTrigger: true)],
      ),
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
    final currentDetail = detail.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: currentDetail == null
            ? null
            : [_ReceiptPrintButton(detail: currentDetail)],
      ),
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

class _ReceiptPrintButton extends ConsumerStatefulWidget {
  const _ReceiptPrintButton({required this.detail, this.autoTrigger = false});

  final TransactionDetail detail;
  final bool autoTrigger;

  @override
  ConsumerState<_ReceiptPrintButton> createState() =>
      _ReceiptPrintButtonState();
}

class _ReceiptPrintButtonState extends ConsumerState<_ReceiptPrintButton> {
  bool _isPrinting = false;
  bool _didAutoTrigger = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoTrigger && !_didAutoTrigger) {
        _didAutoTrigger = true;
        _print(autoMode: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cetak',
      onPressed: _isPrinting ? null : () => _print(),
      icon: _isPrinting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print_outlined),
    );
  }

  Future<void> _print({bool autoMode = false}) async {
    if (_isPrinting) {
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final settings = await ref.read(printerSettingsStoreProvider).read();
      if (autoMode && !settings.autoPrintAfterCheckout) {
        return;
      }
      if (settings.selectedPrinter == null) {
        if (!autoMode && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atur printer dulu di menu Printer & Struk.'),
            ),
          );
        }
        return;
      }

      await ref
          .read(printerServiceProvider)
          .printReceipt(detail: widget.detail, settings: settings);

      if (!mounted || autoMode) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Struk sedang dicetak.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }
}
