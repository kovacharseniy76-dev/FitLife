import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';
import 'catalog_screen.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

/// Оболонка для ролі «Користувач»: 5 вкладок нижньої навігації.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: <Widget>[
            HomeScreen(onOpenPlanner: () => _go(1)),
            const PlannerScreen(),
            const CatalogScreen(),
            const StatsScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: FitLifeBottomNav(index: _index, onChanged: _go),
    );
  }
}
