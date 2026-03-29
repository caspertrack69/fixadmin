import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasirfix/core/providers/app_providers.dart';
import 'package:kasirfix/features/inventory/data/inventory_repository.dart';
import 'package:kasirfix/features/inventory/models/inventory_models.dart';
import 'package:kasirfix/features/inventory/presentation/inventory_controller.dart';

void main() {
  test('filters tree and manages expand collapse state', () async {
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          _FakeInventoryRepository(_sampleTree),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(inventoryControllerProvider.future);
    final notifier = container.read(inventoryControllerProvider.notifier);

    notifier.search('oled');
    var state = container.read(inventoryControllerProvider).asData!.value;

    expect(state.filteredTree, hasLength(1));
    expect(
      state.filteredTree.first.models.first.parts.first.variants.first.name,
      'Grade A (OLED)',
    );
    expect(state.openCategoryIds, contains(1));
    expect(state.openModelIds, contains(11));
    expect(state.openPartIds, contains(21));

    notifier.collapseAll();
    state = container.read(inventoryControllerProvider).asData!.value;
    expect(state.openCategoryIds, isEmpty);

    notifier.expandAll();
    state = container.read(inventoryControllerProvider).asData!.value;
    expect(state.openCategoryIds, contains(1));
    expect(state.openModelIds, contains(11));
    expect(state.openPartIds, contains(21));
  });
}

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository(this._tree);

  final List<Category> _tree;

  @override
  Future<List<Category>> fetchCatalogTree() async => _tree;
}

const _sampleTree = [
  Category(
    id: 1,
    name: 'iPhone',
    models: [
      DeviceModel(
        id: 11,
        name: 'iPhone 15 Pro Max',
        parts: [
          Part(
            id: 21,
            name: 'LCD',
            variants: [
              Variant(
                id: 31,
                name: 'Grade A (OLED)',
                sellPrice: 2500000,
                currentStock: 3,
                minStock: 1,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
