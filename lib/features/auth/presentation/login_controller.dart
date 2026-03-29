import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';

class LoginFormState {
  const LoginFormState({
    this.isSubmitting = false,
    this.errorMessage,
    this.fieldErrors,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final FieldErrors? fieldErrors;

  LoginFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    FieldErrors? fieldErrors,
    bool clearErrors = false,
  }) {
    return LoginFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : errorMessage ?? this.errorMessage,
      fieldErrors: clearErrors ? null : fieldErrors ?? this.fieldErrors,
    );
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, LoginFormState>(LoginController.new);

class LoginController extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  Future<bool> submit({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = const LoginFormState();
      return true;
    } on ApiException catch (exception) {
      state = LoginFormState(
        isSubmitting: false,
        errorMessage: exception.message,
        fieldErrors: exception.fieldErrors,
      );
      return false;
    } catch (_) {
      state = const LoginFormState(
        isSubmitting: false,
        errorMessage: 'Login gagal. Coba lagi sebentar.',
      );
      return false;
    }
  }
}
