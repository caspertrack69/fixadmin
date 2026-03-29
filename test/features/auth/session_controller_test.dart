import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasirfix/core/network/api_exception.dart';
import 'package:kasirfix/core/providers/app_providers.dart';
import 'package:kasirfix/core/storage/token_store.dart';
import 'package:kasirfix/features/auth/data/auth_repository.dart';
import 'package:kasirfix/features/auth/models/auth_session.dart';
import 'package:kasirfix/features/auth/models/session_user.dart';
import 'package:kasirfix/features/auth/presentation/session_controller.dart';

void main() {
  test('clears session when me endpoint returns unauthorized', () async {
    final tokenStore = _MemoryTokenStore('token-123');
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokenStore),
        authRepositoryProvider.overrideWithValue(_UnauthorizedAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(sessionControllerProvider.future);

    expect(session, isNull);
    expect(tokenStore.cleared, isTrue);
  });
}

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore(this._token);

  String? _token;
  bool cleared = false;

  @override
  Future<void> clearToken() async {
    cleared = true;
    _token = null;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
}

class _UnauthorizedAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<SessionUser> me() async {
    throw const ApiException(
      type: ApiErrorType.unauthorized,
      message: 'Unauthenticated',
      statusCode: 401,
    );
  }
}
