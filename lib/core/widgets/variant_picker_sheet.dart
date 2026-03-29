import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../features/transactions/models/transaction_models.dart';
import '../formatters/app_formatters.dart';
import '../providers/app_providers.dart';
import 'app_section_card.dart';

Future<SearchVariantResult?> showVariantPickerSheet(
  BuildContext context, {
  required bool inStockOnly,
  String title = 'Cari varian',
}) {
  return showModalBottomSheet<SearchVariantResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return VariantPickerSheet(title: title, inStockOnly: inStockOnly);
    },
  );
}

class VariantPickerSheet extends ConsumerStatefulWidget {
  const VariantPickerSheet({
    super.key,
    required this.title,
    required this.inStockOnly,
  });

  final String title;
  final bool inStockOnly;

  @override
  ConsumerState<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends ConsumerState<VariantPickerSheet> {
  late final TextEditingController _queryController;
  Timer? _debounce;
  bool _isLoading = false;
  String? _error;
  String _lastQuery = '';
  List<SearchVariantResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          AppTheme.headerDark.withValues(alpha: 0.88),
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
                          widget.title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.inStockOnly
                              ? 'Pilih varian yang stoknya tersedia untuk checkout aktif.'
                              : 'Telusuri semua varian untuk pengecekan inventaris.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeaderChip(
                              label: widget.inStockOnly
                                  ? 'Hanya stok tersedia'
                                  : 'Semua varian',
                              tone: widget.inStockOnly
                                  ? AppTheme.success
                                  : AppTheme.info,
                            ),
                            const _HeaderChip(
                              label: 'Cari kategori, model, part, atau grade',
                              tone: AppTheme.warmPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _queryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ketik minimal 2 karakter...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: _onQueryChanged,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _buildBody(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: AppSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_tethering_error_rounded,
                size: 36,
                color: AppTheme.warmAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Pencarian gagal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _lastQuery.length >= 2
                    ? () => _search(_lastQuery)
                    : null,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_queryController.text.trim().length < 2) {
      return const _PickerInfoState(
        key: ValueKey('hint'),
        icon: Icons.manage_search_rounded,
        title: 'Mulai pencarian',
        message:
            'Masukkan minimal 2 karakter untuk menampilkan varian yang cocok.',
      );
    }
    if (_results.isEmpty) {
      return const _PickerInfoState(
        key: ValueKey('empty'),
        icon: Icons.inventory_2_outlined,
        title: 'Varian tidak ditemukan',
        message:
            'Coba kata kunci lain yang lebih spesifik pada kategori, model, part, atau grade.',
      );
    }

    return ListView.separated(
      key: const ValueKey('results'),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _results[index];
        return AppSectionCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).pop(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VariantAvatar(item: item),
                  const SizedBox(width: 14),
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
                          '${item.category} / ${item.model}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.part} / ${item.grade}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ResultPill(
                              label: AppFormatters.rupiah(item.sellPrice),
                              background: AppTheme.warmPrimary.withValues(
                                alpha: 0.12,
                              ),
                              foreground: AppTheme.warmPrimary,
                            ),
                            _ResultPill(
                              label: item.currentStock > 0
                                  ? 'Stok ${item.currentStock}'
                                  : 'Stok kosong',
                              background: item.currentStock > 0
                                  ? AppTheme.success.withValues(alpha: 0.12)
                                  : AppTheme.warmAccent.withValues(alpha: 0.12),
                              foreground: item.currentStock > 0
                                  ? AppTheme.success
                                  : AppTheme.warmAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      final query = value.trim();
      if (query.length < 2) {
        setState(() {
          _results = const [];
          _error = null;
          _isLoading = false;
          _lastQuery = query;
        });
        return;
      }
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastQuery = query;
    });

    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final response = await repo.searchVariants(
        query: query,
        inStock: widget.inStockOnly ? true : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _results = response.data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _isLoading = false;
      });
    }
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _PickerInfoState extends StatelessWidget {
  const _PickerInfoState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppSectionCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.backgroundCard,
              child: Icon(icon, color: AppTheme.headerDark),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _VariantAvatar extends StatelessWidget {
  const _VariantAvatar({required this.item});

  final SearchVariantResult item;

  @override
  Widget build(BuildContext context) {
    final photoUrl = item.photoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 64,
        height: 64,
        color: AppTheme.backgroundCard,
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.phone_android_rounded,
                    color: AppTheme.headerDark,
                  );
                },
              )
            : const Icon(
                Icons.phone_android_rounded,
                color: AppTheme.headerDark,
              ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({
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
