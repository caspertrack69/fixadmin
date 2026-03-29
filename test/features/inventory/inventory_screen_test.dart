import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixadmin/core/providers/app_providers.dart';
import 'package:fixadmin/features/inventory/data/inventory_repository.dart';
import 'package:fixadmin/features/inventory/models/inventory_models.dart';
import 'package:fixadmin/features/inventory/presentation/inventory_screen.dart';

void main() {
  testWidgets('renders inventory search result and formatted price', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            _FakeInventoryRepository(_sampleTree),
          ),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'OLED');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Grade A (OLED)'), findsOneWidget);
    expect(find.text('Rp 2.500.000'), findsOneWidget);
    expect(find.text('Tersedia 3'), findsOneWidget);
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
