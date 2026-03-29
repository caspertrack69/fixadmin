import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/formatters/app_formatters.dart';
import '../../../core/widgets/app_section_card.dart';
import '../models/inventory_models.dart';
import 'inventory_controller.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryControllerProvider);
    final notifier = ref.read(inventoryControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(inventoryControllerProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            child: Wrap(
              runSpacing: 12,
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 380,
                  child: TextFormField(
                    controller: _searchController,
                    onChanged: notifier.search,
                    decoration: InputDecoration(
                      hintText: 'Cari kategori, model, part, atau varian...',
                      prefixIcon: const Icon(LucideIcons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                notifier.search('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: notifier.expandAll,
                  child: const Text('Buka Semua'),
                ),
                OutlinedButton(
                  onPressed: notifier.collapseAll,
                  child: const Text('Tutup Semua'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          inventory.when(
            data: (data) {
              final items = data.filteredTree;
              if (items.isEmpty) {
                return const AppSectionCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text('Tidak ada item inventaris yang cocok.'),
                    ),
                  ),
                );
              }

              return Column(
                children: items
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CategoryTile(
                          category: category,
                          isOpen: data.openCategoryIds.contains(category.id),
                          openModelIds: data.openModelIds,
                          openPartIds: data.openPartIds,
                          onToggleCategory: () =>
                              notifier.toggleCategory(category.id),
                          onToggleModel: notifier.toggleModel,
                          onTogglePart: notifier.togglePart,
                        ),
                      ),
                    )
                    .toList(),
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
                    'Inventaris gagal dimuat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(inventoryControllerProvider),
                    child: const Text('Muat ulang'),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isOpen,
    required this.openModelIds,
    required this.openPartIds,
    required this.onToggleCategory,
    required this.onToggleModel,
    required this.onTogglePart,
  });

  final Category category;
  final bool isOpen;
  final Set<int> openModelIds;
  final Set<int> openPartIds;
  final VoidCallback onToggleCategory;
  final ValueChanged<int> onToggleModel;
  final ValueChanged<int> onTogglePart;

  @override
  Widget build(BuildContext context) {
    return _AccordionCard(
      isOpen: isOpen,
      onTap: onToggleCategory,
      icon: Icon(
        isOpen ? LucideIcons.folderOpen : LucideIcons.folder,
        color: AppTheme.warmPrimary,
      ),
      title: category.name,
      subtitle: '${category.models.length} model',
      children: category.models
          .map(
            (model) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TreeGuide(
                child: _ModelTile(
                  model: model,
                  isOpen: openModelIds.contains(model.id),
                  openPartIds: openPartIds,
                  onToggleModel: () => onToggleModel(model.id),
                  onTogglePart: onTogglePart,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.model,
    required this.isOpen,
    required this.openPartIds,
    required this.onToggleModel,
    required this.onTogglePart,
  });

  final DeviceModel model;
  final bool isOpen;
  final Set<int> openPartIds;
  final VoidCallback onToggleModel;
  final ValueChanged<int> onTogglePart;

  @override
  Widget build(BuildContext context) {
    return _AccordionCard(
      level: 1,
      isOpen: isOpen,
      onTap: onToggleModel,
      icon: const Icon(LucideIcons.smartphone, color: Color(0xFF4D9688)),
      title: model.name,
      subtitle: '${model.parts.length} part',
      children: model.parts
          .map(
            (part) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TreeGuide(
                child: _PartTile(
                  part: part,
                  isOpen: openPartIds.contains(part.id),
                  onTogglePart: () => onTogglePart(part.id),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.part,
    required this.isOpen,
    required this.onTogglePart,
  });

  final Part part;
  final bool isOpen;
  final VoidCallback onTogglePart;

  @override
  Widget build(BuildContext context) {
    return _AccordionCard(
      level: 2,
      isOpen: isOpen,
      onTap: onTogglePart,
      icon: const Icon(LucideIcons.cpu, color: Color(0xFFDC2626)),
      title: part.name,
      subtitle: '${part.variants.length} varian',
      children: part.variants
          .map(
            (variant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TreeGuide(
                child: _VariantRow(variant: variant),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.onTap,
    required this.children,
    this.level = 0,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool isOpen;
  final VoidCallback onTap;
  final List<Widget> children;
  final int level;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20 - (level * 2));

    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(subtitle),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(LucideIcons.chevronUp),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isOpen
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(children: children),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeGuide extends StatelessWidget {
  const _TreeGuide({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: child,
        ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
  });

  final Variant variant;

  @override
  Widget build(BuildContext context) {
    final statusColor = variant.currentStock > 0
        ? AppTheme.success
        : variant.minStock > 0
            ? AppTheme.warning
            : AppTheme.critical;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 52,
              height: 52,
              child: variant.photoUrl == null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white),
                      child: Icon(LucideIcons.package),
                    )
                  : Image.network(
                      variant.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white),
                          child: Icon(LucideIcons.package),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(AppFormatters.rupiah(variant.sellPrice)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              variant.currentStock > 0
                  ? 'Tersedia ${variant.currentStock}'
                  : 'Kosong',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
