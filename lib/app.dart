import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/models.dart';
import 'screens/admin_screen.dart';
import 'screens/content_screen.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLife',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _RootGate(),
    );
  }
}

/// Показує екран залежно від того, хто увійшов (ролі з діаграми варіантів використання).
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.lime)));
    }
    final a = state.account;
    if (a == null) return const WelcomeScreen();
    if (a is Administrator) return const AdminScreen();
    if (a is ContentManager) return const ContentScreen();
    return const HomeShell();
  }
}
