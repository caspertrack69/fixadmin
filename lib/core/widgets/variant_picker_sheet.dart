import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/transactions/models/transaction_models.dart';
import '../formatters/app_formatters.dart';
import '../providers/app_providers.dart';

Future<SearchVariantResult?> showVariantPickerSheet(
  BuildContext context, {
  required bool inStockOnly,
  String title = 'Cari varian',
}) {
  return showModalBottomSheet<SearchVariantResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return VariantPickerSheet(
        title: title,
        inStockOnly: inStockOnly,
      );
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
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                widget.inStockOnly
                    ? 'Menampilkan varian dengan stok tersedia.'
                    : 'Cari semua varian untuk kebutuhan inventaris.',
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
                child: Builder(
                  builder: (context) {
                    if (_isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_error != null) {
                      return Center(child: Text(_error!));
                    }
                    if (_queryController.text.trim().length < 2) {
                      return const Center(
                        child: Text('Masukkan minimal 2 karakter pencarian.'),
                      );
                    }
                    if (_results.isEmpty) {
                      return const Center(
                        child: Text('Varian tidak ditemukan.'),
                      );
                    }

                    return ListView.separated(
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(item.displayName),
                          subtitle: Text(
                            '${AppFormatters.rupiah(item.sellPrice)} • Stok ${item.currentStock}',
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemCount: _results.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
      if (query.length < 2) {
        setState(() {
          _results = const [];
          _error = null;
          _isLoading = false;
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
