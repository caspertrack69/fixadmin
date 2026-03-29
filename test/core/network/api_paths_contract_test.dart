import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasirfix/core/network/api_paths.dart';

void main() {
  test('client API paths exist in the Postman collection', () {
    final file = File(
      'docs/postman/fixphone-flutter-api.postman_collection.json',
    );
    final decoded =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final urls = <String>{};

    void collect(dynamic items) {
      if (items is! List) {
        return;
      }

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final request = item['request'];
        if (request is Map) {
          final url = request['url'];
          if (url is String) {
            urls.add(url);
          } else if (url is Map && url['raw'] is String) {
            urls.add(url['raw'] as String);
          }
        }

        collect(item['item']);
      }
    }

    collect(decoded['item']);

    expect(urls, contains('{{base_url}}${ApiPaths.authLogin}'));
    expect(urls, contains('{{base_url}}${ApiPaths.authMe}'));
    expect(urls, contains('{{base_url}}${ApiPaths.authLogout}'));
    expect(urls, contains('{{base_url}}${ApiPaths.kasirDashboard}'));
    expect(urls, contains('{{base_url}}${ApiPaths.catalogTree}'));
    expect(urls, contains('{{base_url}}${ApiPaths.transactions}'));
    expect(urls, contains('{{base_url}}${ApiPaths.transactionDetail(1)}'));
    expect(urls, contains('{{base_url}}${ApiPaths.stockIn}'));
    expect(
      urls.any(
        (url) => url.startsWith('{{base_url}}${ApiPaths.variantsSearch}'),
      ),
      isTrue,
    );
  });
}
