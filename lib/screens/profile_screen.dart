import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'sheets.dart';

/// Екран 7 — Профіль: дані користувача, ціль, меню, вихід.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Future<void> _edit(BuildContext context, User user) async {
    final name = TextEditingController(text: user.name);
    final weight = TextEditingController(text: user.weightKg.toStringAsFixed(1));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Редагувати профіль', style: AppText.body(18, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: "Ім'я")),
            const SizedBox(height: 12),
            TextField(
              controller: weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Вага, кг'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Скасувати')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.bg),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final w = double.tryParse(weight.text.replaceAll(',', '.')) ?? user.weightKg;
      await context.read<AppState>().updateProfile(name.text.trim(), w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user!;
    final goal = user.goals.isEmpty ? null : user.goals.first;
    final level = 1 + user.activityLog.entries.length ~/ 4;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: <Widget>[
        Row(children: <Widget>[
          Expanded(child: Text('Профіль', style: AppText.display(24))),
          SquareIconButton(icon: Icons.edit_outlined, tooltip: 'Редагувати профіль', onPressed: () => _edit(context, user)),
        ]),
        const SizedBox(height: 18),
        Row(children: <Widget>[
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.lime,
            child: Text(_initials(user.getDisplayName()), style: AppText.display(24, color: AppColors.bg)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(user.getDisplayName(), style: AppText.body(20, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Учасник з ${ukMonthsGen[user.createdAt.month - 1]} ${user.createdAt.year}',
                    style: AppText.body(13, color: AppColors.muted)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tint(AppColors.orange), borderRadius: BorderRadius.circular(20)),
                  child: Text('Рівень $level', style: AppText.body(12, color: AppColors.orange, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          radius: 20,
          child: Row(children: <Widget>[
            _Stat(value: user.heightCm > 0 ? '${user.heightCm.toStringAsFixed(0)} см' : '—', label: 'Зріст'),
            _Stat(value: user.weightKg > 0 ? '${user.weightKg.toStringAsFixed(1)} кг' : '—', label: 'Вага', divided: true),
            _Stat(value: user.age?.toString() ?? '—', label: 'Вік'),
          ]),
        ),
        if (goal != null) ...<Widget>[
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(16),
            radius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Text('Ціль: ${goal.title}', style: AppText.body(14, weight: FontWeight.w600))),
                  Text('${(goal.getProgress() * 100).round()}%', style: AppText.body(13, color: AppColors.lime, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: goal.getProgress(),
                    minHeight: 10,
                    backgroundColor: AppColors.track,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  goal.isAchieved()
                      ? 'Ціль досягнуто!'
                      : 'Залишилось ${(goal.currentValue - goal.targetValue).abs().toStringAsFixed(1)} · до ${goal.deadline.day} ${ukMonthsGen[goal.deadline.month - 1]}',
                  style: AppText.body(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          radius: 20,
          child: Column(children: <Widget>[
            _MenuRow(
              icon: Icons.notifications_none,
              title: 'Нагадування',
              trailing: '${state.notifications.scheduledCount}',
              onTap: () => showInboxSheet(context),
            ),
            _MenuRow(icon: Icons.menu_book_outlined, title: 'Щоденник активності', trailing: '${user.activityLog.entries.length}',
                onTap: () => _showLog(context, user)),
            _MenuRow(icon: Icons.add_circle_outline, title: 'Записати активність', onTap: () => showAddEntrySheet(context), last: true),
          ]),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.read<AppState>().signOut(),
          child: Text('Вийти з акаунта', style: AppText.body(15, color: AppColors.orange, weight: FontWeight.w600)),
        ),
      ],
    );
  }

  void _showLog(BuildContext context, User user) {
    final entries = user.activityLog.entries;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: <Widget>[
            Text('Щоденник активності', style: AppText.display(20)),
            const SizedBox(height: 12),
            if (entries.isEmpty) const EmptyHint(text: 'Записів поки немає'),
            for (final e in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: TintIcon(
                    icon: e.workout != null ? Icons.fitness_center : Icons.directions_walk,
                    color: e.workout != null ? AppColors.orange : AppColors.blue,
                    size: 36),
                title: Text(e.type, style: AppText.body(15, weight: FontWeight.w600)),
                subtitle: Text(
                  '${e.date.day} ${ukMonthsGen[e.date.month - 1]} · ${e.durationMin} хв · ${e.calories} ккал · ${groupDigits(e.steps)} кроків',
                  style: AppText.body(12, color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.divided = false});

  final String value;
  final String label;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: divided
            ? const BoxDecoration(
                border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
              )
            : null,
        child: Column(children: <Widget>[
          Text(value, style: AppText.body(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: AppText.body(12, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, required this.onTap, this.trailing, this.last = false});

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: last
            ? null
            : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surface2))),
        child: Row(children: <Widget>[
          Icon(icon, color: AppColors.muted, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppText.body(15))),
          if (trailing != null) Text(trailing!, style: AppText.body(13, color: AppColors.muted)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFF6F7A86), size: 18),
        ]),
      ),
    );
  }
}
