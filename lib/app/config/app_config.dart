import 'package:flutter/foundation.dart';

final class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fixphone.baktify.my.id/api/v1',
  );

  static String get deviceName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Fixadmin Android',
      TargetPlatform.iOS => 'Fixadmin iPhone',
      TargetPlatform.macOS => 'Fixadmin macOS',
      TargetPlatform.windows => 'Fixadmin Windows',
      TargetPlatform.linux => 'Fixadmin Linux',
      TargetPlatform.fuchsia => 'Fixadmin Fuchsia',
    };
  }

  const AppConfig._();
}
