import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as escpos;
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer_plus/flutter_thermal_printer_plus.dart';
import 'package:flutter_thermal_printer_plus/platform/thermal_printer_platform.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../transactions/models/transaction_models.dart';
import '../models/printer_settings.dart';

class PrinterOperationException implements Exception {
  const PrinterOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrinterService {
  Future<List<SavedBluetoothPrinter>> scanBluetoothPrinters() async {
    await _requestBluetoothPermissions();
    final devices = await FlutterThermalPrinterPlus.scanBluetoothDevices();
    return devices
        .where((device) => device.address.trim().isNotEmpty)
        .map(
          (device) => SavedBluetoothPrinter(
            name: device.name.trim().isEmpty
                ? 'Printer tanpa nama'
                : device.name,
            address: device.address,
          ),
        )
        .toList();
  }

  Future<void> connectBluetoothPrinter(SavedBluetoothPrinter printer) async {
    await _requestBluetoothPermissions();
    final connected = await FlutterThermalPrinterPlus.connectBluetooth(
      printer.address,
    );
    if (!connected) {
      throw const PrinterOperationException('Printer tidak bisa disambungkan.');
    }
  }

  Future<void> disconnect() async {
    await FlutterThermalPrinterPlus.disconnectBluetooth();
  }

  Future<bool> isConnected() {
    return FlutterThermalPrinterPlus.isConnected();
  }

  Future<void> printReceipt({
    required TransactionDetail detail,
    required PrinterSettings settings,
  }) async {
    final printer = settings.selectedPrinter;
    if (printer == null) {
      throw const PrinterOperationException('Pilih printer terlebih dahulu.');
    }

    await _ensureConnection(printer);
    final bytes = await _buildReceiptBytes(detail: detail, settings: settings);
    final printed = await ThermalPrinterPlatform.printBytes(bytes);
    if (!printed) {
      throw const PrinterOperationException('Struk gagal dicetak.');
    }
  }

  Future<void> printTestPage({required PrinterSettings settings}) async {
    final printer = settings.selectedPrinter;
    if (printer == null) {
      throw const PrinterOperationException('Pilih printer terlebih dahulu.');
    }

    await _ensureConnection(printer);
    final bytes = await _buildTestBytes(settings);
    final printed = await ThermalPrinterPlatform.printBytes(bytes);
    if (!printed) {
      throw const PrinterOperationException('Tes cetak gagal.');
    }
  }

  Future<void> _ensureConnection(SavedBluetoothPrinter printer) async {
    final connected = await FlutterThermalPrinterPlus.isConnected();
    if (!connected) {
      await connectBluetoothPrinter(printer);
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    final permissions = switch (defaultTargetPlatform) {
      TargetPlatform.android => <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ],
      TargetPlatform.iOS => <Permission>[Permission.bluetooth],
      _ => const <Permission>[],
    };

    if (permissions.isEmpty) {
      return;
    }

    final statuses = await permissions.request();
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      throw const PrinterOperationException(
        'Izin Bluetooth diblokir. Aktifkan lagi dari pengaturan aplikasi.',
      );
    }
    if (statuses.values.any((status) => !status.isGranted)) {
      throw const PrinterOperationException('Izin Bluetooth belum aktif.');
    }
  }

  Future<List<int>> _buildReceiptBytes({
    required TransactionDetail detail,
    required PrinterSettings settings,
  }) async {
    final profile = await escpos.CapabilityProfile.load();
    final generator = escpos.Generator(
      _paperSizeFor(settings.template),
      profile,
    );
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        'Kasirfix',
        styles: const escpos.PosStyles(
          align: escpos.PosAlign.center,
          bold: true,
          height: escpos.PosTextSize.size2,
          width: escpos.PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'Struk Pembayaran',
        styles: const escpos.PosStyles(
          align: escpos.PosAlign.center,
          bold: true,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        detail.transactionCode,
        styles: const escpos.PosStyles(
          align: escpos.PosAlign.center,
          bold: true,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        detail.createdAt == null
            ? '-'
            : AppFormatters.dateTime.format(detail.createdAt!),
        styles: const escpos.PosStyles(align: escpos.PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'Kasir: ${detail.kasir}',
        styles: const escpos.PosStyles(align: escpos.PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    switch (settings.template) {
      case ReceiptTemplateVariant.compact58:
        for (final item in detail.items) {
          bytes.addAll(
            generator.text(
              item.displayName,
              styles: const escpos.PosStyles(bold: true),
            ),
          );
          bytes.addAll(
            generator.row([
              escpos.PosColumn(
                text: '${item.qty} x ${AppFormatters.rupiah(item.sellPrice)}',
                width: 7,
              ),
              escpos.PosColumn(
                text: AppFormatters.rupiah(item.subtotal),
                width: 5,
                styles: const escpos.PosStyles(align: escpos.PosAlign.right),
              ),
            ]),
          );
        }
      case ReceiptTemplateVariant.standard58:
      case ReceiptTemplateVariant.detail80:
        for (final item in detail.items) {
          bytes.addAll(
            generator.row([
              escpos.PosColumn(
                text: item.displayName,
                width: 8,
                styles: const escpos.PosStyles(bold: true),
              ),
              escpos.PosColumn(
                text: AppFormatters.rupiah(item.subtotal),
                width: 4,
                styles: const escpos.PosStyles(align: escpos.PosAlign.right),
              ),
            ]),
          );
          bytes.addAll(
            generator.row([
              escpos.PosColumn(
                text: '${item.qty} x ${AppFormatters.rupiah(item.sellPrice)}',
                width: 12,
              ),
            ]),
          );
        }
        if (settings.template == ReceiptTemplateVariant.detail80) {
          bytes.addAll(generator.hr(ch: '='));
          bytes.addAll(
            generator.qrcode(
              detail.transactionCode,
              align: escpos.PosAlign.center,
            ),
          );
        }
    }

    bytes.addAll(generator.hr());
    bytes.addAll(_summaryRows(generator, detail));

    if (detail.note != null && detail.note!.trim().isNotEmpty) {
      bytes.addAll(
        generator.text('Catatan', styles: const escpos.PosStyles(bold: true)),
      );
      bytes.addAll(generator.text(detail.note!.trim()));
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(
      generator.text(
        'Terima kasih',
        styles: const escpos.PosStyles(align: escpos.PosAlign.center),
      ),
    );
    bytes.addAll(generator.cut());
    return bytes;
  }

  Future<List<int>> _buildTestBytes(PrinterSettings settings) async {
    final profile = await escpos.CapabilityProfile.load();
    final generator = escpos.Generator(
      _paperSizeFor(settings.template),
      profile,
    );
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        'Kasirfix',
        styles: const escpos.PosStyles(
          align: escpos.PosAlign.center,
          bold: true,
          height: escpos.PosTextSize.size2,
          width: escpos.PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'Tes Printer',
        styles: const escpos.PosStyles(
          align: escpos.PosAlign.center,
          bold: true,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Template: ${settings.template.label}'));
    if (settings.selectedPrinter != null) {
      bytes.addAll(
        generator.text('Printer: ${settings.selectedPrinter!.name}'),
      );
    }
    bytes.addAll(generator.text(AppFormatters.dateTime.format(DateTime.now())));
    bytes.addAll(generator.feed(2));
    bytes.addAll(
      generator.text(
        'Cetak berhasil.',
        styles: const escpos.PosStyles(align: escpos.PosAlign.center),
      ),
    );
    bytes.addAll(generator.cut());
    return bytes;
  }

  List<int> _summaryRows(escpos.Generator generator, TransactionDetail detail) {
    return [
      ...generator.row([
        escpos.PosColumn(text: 'Total', width: 6),
        escpos.PosColumn(
          text: AppFormatters.rupiah(detail.totalAmount),
          width: 6,
          styles: const escpos.PosStyles(align: escpos.PosAlign.right),
        ),
      ]),
      ...generator.row([
        escpos.PosColumn(text: 'Bayar', width: 6),
        escpos.PosColumn(
          text: AppFormatters.rupiah(detail.paidAmount),
          width: 6,
          styles: const escpos.PosStyles(align: escpos.PosAlign.right),
        ),
      ]),
      ...generator.row([
        escpos.PosColumn(
          text: 'Kembali',
          width: 6,
          styles: const escpos.PosStyles(bold: true),
        ),
        escpos.PosColumn(
          text: AppFormatters.rupiah(detail.changeAmount),
          width: 6,
          styles: const escpos.PosStyles(
            align: escpos.PosAlign.right,
            bold: true,
          ),
        ),
      ]),
    ];
  }

  escpos.PaperSize _paperSizeFor(ReceiptTemplateVariant template) {
    return switch (template) {
      ReceiptTemplateVariant.detail80 => escpos.PaperSize.mm80,
      ReceiptTemplateVariant.compact58 ||
      ReceiptTemplateVariant.standard58 => escpos.PaperSize.mm58,
    };
  }
}
