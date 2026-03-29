import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_error_state.dart';
import '../core/widgets/app_loading_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

class KasirfixApp extends ConsumerStatefulWidget {
  const KasirfixApp({super.key});

  @override
  ConsumerState<KasirfixApp> createState() => _KasirfixAppState();
}

class _KasirfixAppState extends ConsumerState<KasirfixApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(sessionControllerProvider.notifier).refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    return MaterialApp(
      title: 'Kasirfix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: switch (session) {
        AsyncLoading() => const AppLoadingState(
          label: 'Menyiapkan sesi kasir...',
        ),
        AsyncError(:final error) => AppErrorState(
          title: 'Sesi tidak bisa dimuat',
          message: '$error',
          onRetry: () => ref.invalidate(sessionControllerProvider),
        ),
        AsyncData(:final value) =>
          value == null ? const LoginScreen() : AppShell(session: value),
      },
    );
  }
}
