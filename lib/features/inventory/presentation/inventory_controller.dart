import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../models/inventory_models.dart';

class InventoryState {
  const InventoryState({
    required this.rawTree,
    this.query = '',
    this.openCategoryIds = const <int>{},
    this.openModelIds = const <int>{},
    this.openPartIds = const <int>{},
  });

  final List<Category> rawTree;
  final String query;
  final Set<int> openCategoryIds;
  final Set<int> openModelIds;
  final Set<int> openPartIds;

  List<Category> get filteredTree => _filterTree(rawTree, query);

  InventoryState copyWith({
    List<Category>? rawTree,
    String? query,
    Set<int>? openCategoryIds,
    Set<int>? openModelIds,
    Set<int>? openPartIds,
  }) {
    return InventoryState(
      rawTree: rawTree ?? this.rawTree,
      query: query ?? this.query,
      openCategoryIds: openCategoryIds ?? this.openCategoryIds,
      openModelIds: openModelIds ?? this.openModelIds,
      openPartIds: openPartIds ?? this.openPartIds,
    );
  }

  static List<Category> _filterTree(List<Category> tree, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return tree;
    }

    final filtered = <Category>[];
    for (final category in tree) {
      final matchedModels = <DeviceModel>[];
      for (final model in category.models) {
        final matchedParts = <Part>[];
        for (final part in model.parts) {
          final matchedVariants = part.variants.where((variant) {
            return variant.name.toLowerCase().contains(normalized);
          }).toList();

          final partMatch = part.name.toLowerCase().contains(normalized);
          if (partMatch || matchedVariants.isNotEmpty) {
            matchedParts.add(
              part.copyWith(
                variants: partMatch ? part.variants : matchedVariants,
              ),
            );
          }
        }

        final modelMatch = model.name.toLowerCase().contains(normalized);
        if (modelMatch || matchedParts.isNotEmpty) {
          matchedModels.add(
            model.copyWith(parts: modelMatch ? model.parts : matchedParts),
          );
        }
      }

      final categoryMatch = category.name.toLowerCase().contains(normalized);
      if (categoryMatch || matchedModels.isNotEmpty) {
        filtered.add(
          category.copyWith(
            models: categoryMatch ? category.models : matchedModels,
          ),
        );
      }
    }

    return filtered;
  }
}

final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, InventoryState>(
      InventoryController.new,
    );

class InventoryController extends AsyncNotifier<InventoryState> {
  @override
  FutureOr<InventoryState> build() async {
    final tree = await ref.read(inventoryRepositoryProvider).fetchCatalogTree();
    return InventoryState(rawTree: tree);
  }

  void search(String value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final next = current.copyWith(query: value);
    if (value.trim().isEmpty) {
      state = AsyncData(next);
      return;
    }

    state = AsyncData(
      next.copyWith(
        openCategoryIds: _collectCategoryIds(next.filteredTree),
        openModelIds: _collectModelIds(next.filteredTree),
        openPartIds: _collectPartIds(next.filteredTree),
      ),
    );
  }

  void toggleCategory(int id) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final updated = Set<int>.from(current.openCategoryIds);
    if (!updated.add(id)) {
      updated.remove(id);
    }
    state = AsyncData(current.copyWith(openCategoryIds: updated));
  }

  void toggleModel(int id) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final updated = Set<int>.from(current.openModelIds);
    if (!updated.add(id)) {
      updated.remove(id);
    }
    state = AsyncData(current.copyWith(openModelIds: updated));
  }

  void togglePart(int id) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final updated = Set<int>.from(current.openPartIds);
    if (!updated.add(id)) {
      updated.remove(id);
    }
    state = AsyncData(current.copyWith(openPartIds: updated));
  }

  void expandAll() {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final source = current.query.trim().isEmpty
        ? current.rawTree
        : current.filteredTree;
    state = AsyncData(
      current.copyWith(
        openCategoryIds: _collectCategoryIds(source),
        openModelIds: _collectModelIds(source),
        openPartIds: _collectPartIds(source),
      ),
    );
  }

  void collapseAll() {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        openCategoryIds: <int>{},
        openModelIds: <int>{},
        openPartIds: <int>{},
      ),
    );
  }

  Set<int> _collectCategoryIds(List<Category> tree) {
    return tree.map((category) => category.id).toSet();
  }

  Set<int> _collectModelIds(List<Category> tree) {
    return tree
        .expand((category) => category.models)
        .map((model) => model.id)
        .toSet();
  }

  Set<int> _collectPartIds(List<Category> tree) {
    return tree
        .expand((category) => category.models)
        .expand((model) => model.parts)
        .map((part) => part.id)
        .toSet();
  }
}
