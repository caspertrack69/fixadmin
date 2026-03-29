enum ReceiptTemplateVariant {
  compact58,
  standard58,
  detail80;

  String get value {
    return switch (this) {
      ReceiptTemplateVariant.compact58 => 'compact58',
      ReceiptTemplateVariant.standard58 => 'standard58',
      ReceiptTemplateVariant.detail80 => 'detail80',
    };
  }

  String get label {
    return switch (this) {
      ReceiptTemplateVariant.compact58 => 'Ringkas 58mm',
      ReceiptTemplateVariant.standard58 => 'Standar 58mm',
      ReceiptTemplateVariant.detail80 => 'Lengkap 80mm',
    };
  }

  String get description {
    return switch (this) {
      ReceiptTemplateVariant.compact58 =>
        'Paling hemat kertas untuk transaksi cepat.',
      ReceiptTemplateVariant.standard58 =>
        'Format umum untuk printer kasir 58mm.',
      ReceiptTemplateVariant.detail80 =>
        'Lebih lega untuk detail item dan catatan.',
    };
  }

  factory ReceiptTemplateVariant.fromValue(String? value) {
    return ReceiptTemplateVariant.values.firstWhere(
      (item) => item.value == value,
      orElse: () => ReceiptTemplateVariant.standard58,
    );
  }
}

class SavedBluetoothPrinter {
  const SavedBluetoothPrinter({required this.name, required this.address});

  final String name;
  final String address;

  Map<String, dynamic> toJson() {
    return {'name': name, 'address': address};
  }

  factory SavedBluetoothPrinter.fromJson(Map<String, dynamic> json) {
    return SavedBluetoothPrinter(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

class PrinterSettings {
  const PrinterSettings({
    this.selectedPrinter,
    this.template = ReceiptTemplateVariant.standard58,
    this.autoPrintAfterCheckout = false,
  });

  final SavedBluetoothPrinter? selectedPrinter;
  final ReceiptTemplateVariant template;
  final bool autoPrintAfterCheckout;

  PrinterSettings copyWith({
    SavedBluetoothPrinter? selectedPrinter,
    ReceiptTemplateVariant? template,
    bool? autoPrintAfterCheckout,
    bool clearPrinter = false,
  }) {
    return PrinterSettings(
      selectedPrinter: clearPrinter
          ? null
          : selectedPrinter ?? this.selectedPrinter,
      template: template ?? this.template,
      autoPrintAfterCheckout:
          autoPrintAfterCheckout ?? this.autoPrintAfterCheckout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selected_printer': selectedPrinter?.toJson(),
      'template': template.value,
      'auto_print_after_checkout': autoPrintAfterCheckout,
    };
  }

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    final rawPrinter = json['selected_printer'];
    return PrinterSettings(
      selectedPrinter: rawPrinter is Map<String, dynamic>
          ? SavedBluetoothPrinter.fromJson(rawPrinter)
          : rawPrinter is Map
          ? SavedBluetoothPrinter.fromJson(
              rawPrinter.map((key, value) => MapEntry('$key', value)),
            )
          : null,
      template: ReceiptTemplateVariant.fromValue(json['template'] as String?),
      autoPrintAfterCheckout:
          json['auto_print_after_checkout'] as bool? ?? false,
    );
  }
}

class PrinterSettingsState {
  const PrinterSettingsState({
    this.isHydrating = true,
    this.isScanning = false,
    this.isConnecting = false,
    this.isPrintingTest = false,
    this.isConnected = false,
    this.connectedAddress,
    this.settings = const PrinterSettings(),
    this.discoveredPrinters = const [],
  });

  final bool isHydrating;
  final bool isScanning;
  final bool isConnecting;
  final bool isPrintingTest;
  final bool isConnected;
  final String? connectedAddress;
  final PrinterSettings settings;
  final List<SavedBluetoothPrinter> discoveredPrinters;

  PrinterSettingsState copyWith({
    bool? isHydrating,
    bool? isScanning,
    bool? isConnecting,
    bool? isPrintingTest,
    bool? isConnected,
    String? connectedAddress,
    PrinterSettings? settings,
    List<SavedBluetoothPrinter>? discoveredPrinters,
    bool clearConnectedAddress = false,
  }) {
    return PrinterSettingsState(
      isHydrating: isHydrating ?? this.isHydrating,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isPrintingTest: isPrintingTest ?? this.isPrintingTest,
      isConnected: isConnected ?? this.isConnected,
      connectedAddress: clearConnectedAddress
          ? null
          : connectedAddress ?? this.connectedAddress,
      settings: settings ?? this.settings,
      discoveredPrinters: discoveredPrinters ?? this.discoveredPrinters,
    );
  }
}
