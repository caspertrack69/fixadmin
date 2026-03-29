import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../models/auth_session.dart';

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, AuthSession?>(
      SessionController.new,
    );

class SessionController extends AsyncNotifier<AuthSession?> {
  @override
  FutureOr<AuthSession?> build() async {
    ref
        .read(sessionCoordinatorProvider)
        .register(
          onUnauthorized: _handleUnauthorized,
          onSessionChanged: _handleSessionChanged,
        );

    final token = await ref.read(tokenStoreProvider).readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final user = await ref.read(authRepositoryProvider).me();
      return AuthSession(token: token, user: user);
    } on ApiException catch (exception) {
      if (exception.isUnauthorized) {
        await ref.read(tokenStoreProvider).clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AsyncData(current.copyWith(user: user));
    } on ApiException catch (exception) {
      if (exception.isUnauthorized) {
        await ref.read(tokenStoreProvider).clearToken();
        state = const AsyncData(null);
      } else {
        state = AsyncError(exception, StackTrace.current);
      }
    }
  }

  Future<void> logout() async {
    final previous = state.asData?.value;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).logout();
      state = const AsyncData(null);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> _handleUnauthorized() async {
    state = const AsyncData(null);
  }

  Future<void> _handleSessionChanged() async {
    ref.invalidateSelf();
  }
}
