import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_section_card.dart';
import '../models/printer_settings.dart';
import 'printer_settings_controller.dart';

class PrinterSettingsScreen extends ConsumerWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printerSettingsControllerProvider);
    final controller = ref.read(printerSettingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Printer & Struk')),
      body: state.isHydrating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                          'Printer siap pakai',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.settings.selectedPrinter == null
                              ? 'Pilih printer Bluetooth lalu tentukan format struk yang dipakai.'
                              : state.settings.selectedPrinter!.name,
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
                            _StatusPill(
                              label: state.isConnected
                                  ? 'Tersambung'
                                  : 'Belum tersambung',
                              tone: state.isConnected
                                  ? AppTheme.success
                                  : AppTheme.warmAccent,
                            ),
                            _StatusPill(
                              label: state.settings.template.label,
                              tone: AppTheme.warmPrimary,
                            ),
                          ],
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
                        'Format struk',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih format yang paling cocok untuk kertas printer Anda.',
                      ),
                      const SizedBox(height: 16),
                      ...ReceiptTemplateVariant.values.map(
                        (template) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TemplateTile(
                            template: template,
                            selected: state.settings.template == template,
                            onTap: () async {
                              await controller.setTemplate(template);
                            },
                          ),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: state.settings.autoPrintAfterCheckout,
                        onChanged: controller.setAutoPrint,
                        title: const Text('Cetak otomatis setelah checkout'),
                        subtitle: const Text(
                          'Struk akan langsung dicetak saat transaksi berhasil.',
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Printer Bluetooth',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.isScanning
                                ? null
                                : () async {
                                    await _runAction(context, () async {
                                      await controller.scanBluetoothPrinters();
                                      final count = ref
                                          .read(
                                            printerSettingsControllerProvider,
                                          )
                                          .discoveredPrinters
                                          .length;
                                      if (count == 0) {
                                        return 'Tidak ada printer ditemukan.';
                                      }
                                      return '$count printer ditemukan.';
                                    });
                                  },
                            icon: state.isScanning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.bluetooth_searching_rounded),
                            label: Text(
                              state.isScanning ? 'Mencari...' : 'Cari',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.settings.selectedPrinter == null
                            ? 'Belum ada printer yang dipilih.'
                            : 'Printer pilihan: ${state.settings.selectedPrinter!.name}',
                      ),
                      if (state.settings.selectedPrinter != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.print_rounded,
                                color: AppTheme.headerDark,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.settings.selectedPrinter!.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.settings.selectedPrinter!.address,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isConnected)
                                OutlinedButton(
                                  onPressed: () async {
                                    await _runAction(context, () async {
                                      await controller.disconnectPrinter();
                                      return 'Printer diputuskan.';
                                    });
                                  },
                                  child: const Text('Putuskan'),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (state.discoveredPrinters.isEmpty)
                        const Text('Hasil pencarian akan muncul di sini.')
                      else
                        ...state.discoveredPrinters.map(
                          (printer) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PrinterTile(
                              printer: printer,
                              isActive:
                                  state.connectedAddress == printer.address,
                              isSaved:
                                  state.settings.selectedPrinter?.address ==
                                  printer.address,
                              isBusy: state.isConnecting,
                              onConnect: () async {
                                await _runAction(context, () async {
                                  await controller.connectPrinter(printer);
                                  return 'Printer tersambung.';
                                });
                              },
                              onSelectOnly: () async {
                                await _runAction(context, () async {
                                  await controller.savePreferredPrinter(
                                    printer,
                                  );
                                  return 'Printer disimpan.';
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isPrintingTest
                        ? null
                        : () async {
                            await _runAction(context, () async {
                              await controller.printTestPage();
                              return 'Tes cetak dikirim.';
                            });
                          },
                    icon: state.isPrintingTest
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
                      state.isPrintingTest ? 'Mengirim...' : 'Cetak Tes',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<String> Function() action,
  ) async {
    try {
      final message = await action();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

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

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final ReceiptTemplateVariant template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.warmPrimary.withValues(alpha: 0.12)
              : AppTheme.backgroundCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.warmPrimary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(template.description),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppTheme.warmPrimary : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterTile extends StatelessWidget {
  const _PrinterTile({
    required this.printer,
    required this.isActive,
    required this.isSaved,
    required this.isBusy,
    required this.onConnect,
    required this.onSelectOnly,
  });

  final SavedBluetoothPrinter printer;
  final bool isActive;
  final bool isSaved;
  final bool isBusy;
  final Future<void> Function() onConnect;
  final Future<void> Function() onSelectOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bluetooth_rounded, color: AppTheme.headerDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      printer.address,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle_rounded, color: AppTheme.success),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : onConnect,
                icon: const Icon(Icons.print_rounded),
                label: Text(isActive ? 'Tersambung' : 'Sambungkan'),
              ),
              OutlinedButton(
                onPressed: onSelectOnly,
                child: Text(isSaved ? 'Tersimpan' : 'Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
