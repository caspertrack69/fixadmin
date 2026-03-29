import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.fieldErrors == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;

          if (isWide) {
            return Row(
              children: [
                const Expanded(flex: 6, child: _LoginBrandPanel()),
                Expanded(
                  flex: 5,
                  child: _LoginFormPane(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscureText: _obscureText,
                    loginState: loginState,
                    onTogglePassword: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    onSubmit: _submit,
                  ),
                ),
              ],
            );
          }

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.headerDark, Color(0xFF101828)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: _LoginBrandCopy(compact: true),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: _LoginFormContent(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscureText: _obscureText,
                          loginState: loginState,
                          onTogglePassword: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          onSubmit: _submit,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.headerDark, Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const _LoginBrandCopy(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBrandCopy extends StatelessWidget {
  const _LoginBrandCopy({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kasirfix',
          style: textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 34 : 44,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kasir yang cepat, ringkas, dan siap cetak struk.',
          style: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          'Masuk untuk mulai transaksi, cek inventaris, dan lanjutkan pekerjaan tanpa langkah yang bertele-tele.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
          ),
        ),
      ],
    );
  }
}

class _LoginFormPane extends StatelessWidget {
  const _LoginFormPane({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscureText,
    required this.loginState,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscureText;
  final LoginFormState loginState;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 28, 36, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _LoginFormContent(
                formKey: formKey,
                emailController: emailController,
                passwordController: passwordController,
                obscureText: obscureText,
                loginState: loginState,
                onTogglePassword: onTogglePassword,
                onSubmit: onSubmit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFormContent extends StatelessWidget {
  const _LoginFormContent({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscureText,
    required this.loginState,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscureText;
  final LoginFormState loginState;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masuk', style: textTheme.displayMedium),
            const SizedBox(height: 10),
            Text(
              'Gunakan akun kasir Anda untuk mulai bekerja.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                errorText: loginState.fieldErrors?.first('email'),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: obscureText,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                errorText: loginState.fieldErrors?.first('password'),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Password wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loginState.isSubmitting ? null : onSubmit,
                child: loginState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
