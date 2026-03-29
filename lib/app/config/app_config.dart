import 'package:flutter/foundation.dart';

final class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fixphone.baktify.my.id/api/v1',
  );

  static String get deviceName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Kasirfix Android',
      TargetPlatform.iOS => 'Kasirfix iPhone',
      TargetPlatform.macOS => 'Kasirfix macOS',
      TargetPlatform.windows => 'Kasirfix Windows',
      TargetPlatform.linux => 'Kasirfix Linux',
      TargetPlatform.fuchsia => 'Kasirfix Fuchsia',
    };
  }

  const AppConfig._();
}
