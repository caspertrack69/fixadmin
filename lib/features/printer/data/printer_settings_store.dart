import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/printer_settings.dart';

abstract class PrinterSettingsStore {
  Future<PrinterSettings> read();
  Future<void> save(PrinterSettings settings);
}

class SecurePrinterSettingsStore implements PrinterSettingsStore {
  SecurePrinterSettingsStore({required FlutterSecureStorage storage})
    : _storage = storage;

  static const _settingsKey = 'printer_settings_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<PrinterSettings> read() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const PrinterSettings();
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return PrinterSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return PrinterSettings.fromJson(
          decoded.map((key, value) => MapEntry('$key', value)),
        );
      }
    } catch (_) {
      // Ignore invalid stored payload and fall back to defaults.
    }

    return const PrinterSettings();
  }

  @override
  Future<void> save(PrinterSettings settings) async {
    await _storage.write(
      key: _settingsKey,
      value: json.encode(settings.toJson()),
    );
  }
}
