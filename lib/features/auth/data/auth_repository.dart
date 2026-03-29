import '../../../app/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/storage/token_store.dart';
import '../models/auth_session.dart';
import '../models/session_user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<SessionUser> me();
  Future<void> logout();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient apiClient,
    required TokenStore tokenStore,
    required SessionCoordinator coordinator,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _coordinator = coordinator;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final SessionCoordinator _coordinator;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.postObject<AuthSession>(
      ApiPaths.authLogin,
      body: {
        'email': email,
        'password': password,
        'device_name': AppConfig.deviceName,
      },
      parser: (json) {
        final rawUser = json['user'];
        return AuthSession(
          token: json['token'] as String? ?? '',
          user: SessionUser.fromJson(
            rawUser is Map<String, dynamic>
                ? rawUser
                : (rawUser as Map).map((key, value) => MapEntry('$key', value)),
          ),
        );
      },
    );

    await _tokenStore.saveToken(session.token);
    await _coordinator.notifySessionChanged();
    return session;
  }

  @override
  Future<SessionUser> me() async {
    return _apiClient.getObject<SessionUser>(
      ApiPaths.authMe,
      parser: SessionUser.fromJson,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.postVoid(ApiPaths.authLogout);
    } finally {
      await _tokenStore.clearToken();
      await _coordinator.notifySessionChanged();
    }
  }
}
