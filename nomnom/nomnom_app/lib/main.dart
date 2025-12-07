import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/application/auth_notifier.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'theme/nomnom_theme.dart';

void main() {
  runApp(const ProviderScope(child: NomNomApp()));
}

class NomNomApp extends ConsumerWidget {
  const NomNomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    Widget home;
    if (authState.isLoading) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (authState.isAuthenticated) {
      home = const FeedScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      title: 'NomNom',
      debugShowCheckedModeBanner: false,

      theme: NomNomTheme.light(),
      darkTheme: NomNomTheme.dark(),
      themeMode: ThemeMode
          .system,

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },

      home: home,
    );
  }
}
