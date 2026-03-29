import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../models/printer_settings.dart';

final printerSettingsControllerProvider =
    NotifierProvider<PrinterSettingsController, PrinterSettingsState>(
      PrinterSettingsController.new,
    );

class PrinterSettingsController extends Notifier<PrinterSettingsState> {
  @override
  PrinterSettingsState build() {
    Future<void>.microtask(_hydrate);
    return const PrinterSettingsState();
  }

  Future<void> _hydrate() async {
    final store = ref.read(printerSettingsStoreProvider);
    final service = ref.read(printerServiceProvider);
    final settings = await store.read();
    final connected = await service.isConnected();

    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      isHydrating: false,
      settings: settings,
      isConnected: connected,
      connectedAddress: connected ? settings.selectedPrinter?.address : null,
    );
  }

  Future<void> setTemplate(ReceiptTemplateVariant template) async {
    final settings = state.settings.copyWith(template: template);
    state = state.copyWith(settings: settings);
    await ref.read(printerSettingsStoreProvider).save(settings);
  }

  Future<void> setAutoPrint(bool enabled) async {
    final settings = state.settings.copyWith(autoPrintAfterCheckout: enabled);
    state = state.copyWith(settings: settings);
    await ref.read(printerSettingsStoreProvider).save(settings);
  }

  Future<void> scanBluetoothPrinters() async {
    state = state.copyWith(isScanning: true);

    try {
      final printers = await ref
          .read(printerServiceProvider)
          .scanBluetoothPrinters();
      state = state.copyWith(isScanning: false, discoveredPrinters: printers);
    } catch (error) {
      state = state.copyWith(isScanning: false);
      rethrow;
    }
  }

  Future<void> connectPrinter(SavedBluetoothPrinter printer) async {
    state = state.copyWith(isConnecting: true);

    try {
      await ref.read(printerServiceProvider).connectBluetoothPrinter(printer);
      final settings = state.settings.copyWith(selectedPrinter: printer);
      await ref.read(printerSettingsStoreProvider).save(settings);
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        connectedAddress: printer.address,
        settings: settings,
      );
    } catch (error) {
      state = state.copyWith(isConnecting: false);
      rethrow;
    }
  }

  Future<void> disconnectPrinter() async {
    await ref.read(printerServiceProvider).disconnect();
    state = state.copyWith(isConnected: false, clearConnectedAddress: true);
  }

  Future<void> savePreferredPrinter(SavedBluetoothPrinter printer) async {
    final settings = state.settings.copyWith(selectedPrinter: printer);
    state = state.copyWith(settings: settings);
    await ref.read(printerSettingsStoreProvider).save(settings);
  }

  Future<void> printTestPage() async {
    state = state.copyWith(isPrintingTest: true);

    try {
      await ref
          .read(printerServiceProvider)
          .printTestPage(settings: state.settings);
      state = state.copyWith(isPrintingTest: false, isConnected: true);
    } catch (error) {
      state = state.copyWith(isPrintingTest: false);
      rethrow;
    }
  }
}
