import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_rings.dart';
import '../widgets/common.dart';
import 'sheets.dart';

/// Екран 3 — Головна: кільця активності, тренування на сьогодні, звички.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenPlanner});

  final VoidCallback onOpenPlanner;

  static const int stepsGoal = 10000;
  static const int caloriesGoal = 600;
  static const int minutesGoal = 60;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notifications = state.notifications;
    final user = state.user!;
    final now = DateTime.now();
    final steps = state.todaySteps;
    final kcal = state.todayCalories;
    final minutes = state.todayMinutes;
    final next = state.nextWorkoutToday;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${ukWeekdaysFull[now.weekday - 1]}, ${now.day} ${ukMonthsGen[now.month - 1]}',
                      style: AppText.body(13, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text('Привіт, ${user.getDisplayName()}!', style: AppText.display(22)),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: notifications,
              builder: (context, _) => SquareIconButton(
                icon: Icons.notifications_none,
                tooltip: 'Сповіщення',
                badge: notifications.inbox.isNotEmpty,
                onPressed: () => showInboxSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: <Widget>[
              ActivityRings(rings: <RingData>[
                RingData(steps / stepsGoal, AppColors.lime),
                RingData(kcal / caloriesGoal, AppColors.orange),
                RingData(minutes / minutesGoal, AppColors.blue),
              ]),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Metric(label: 'Кроки', value: groupDigits(steps), goal: '/ ${groupDigits(stepsGoal)}', color: AppColors.lime),
                    const SizedBox(height: 10),
                    _Metric(label: 'Калорії', value: '$kcal', goal: '/ $caloriesGoal ккал', color: AppColors.orange),
                    const SizedBox(height: 10),
                    _Metric(label: 'Активність', value: '$minutes', goal: '/ $minutesGoal хв', color: AppColors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (next != null) _TodayWorkoutCard(workout: next) else _NoWorkoutCard(onPlan: onOpenPlanner),
        const SizedBox(height: 12),
        AppButton(
          label: 'Записати активність',
          primary: false,
          icon: Icons.add,
          onPressed: () => showAddEntrySheet(context),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Звички'),
        const SizedBox(height: 4),
        if (user.habits.isEmpty) const EmptyHint(text: 'Звичок поки немає'),
        for (final h in user.habits) ...<Widget>[_HabitTile(habit: h), const SizedBox(height: 10)],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.goal, required this.color});

  final String label;
  final String value;
  final String goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.body(12, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text.rich(TextSpan(children: <TextSpan>[
          TextSpan(text: value, style: AppText.body(17, color: color, weight: FontWeight.w700)),
          TextSpan(text: ' $goal', style: AppText.body(12, color: AppColors.muted)),
        ])),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({required this.workout});

  final Workout workout;

  Future<void> _onPlay(BuildContext context) async {
    final state = context.read<AppState>();
    if (workout.status == WorkoutStatus.planned) {
      await state.startWorkout(workout);
      if (context.mounted) showMessage(context, 'Тренування «${workout.title}» розпочато');
    } else {
      // Завершення: запис у щоденник, пов'язаний із тренуванням → Workout.complete()
      await state.addEntry(
        type: workout.title,
        durationMin: workout.durationMin,
        calories: workout.durationMin * 8,
        steps: 0,
        workout: workout,
      );
      if (context.mounted) showMessage(context, 'Тренування виконано й записано в щоденник');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inProgress = workout.status == WorkoutStatus.inProgress;
    return AppCard(
      color: AppColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(inProgress ? 'ТРИВАЄ ЗАРАЗ' : 'ТРЕНУВАННЯ НА СЬОГОДНІ',
                    style: AppText.body(12, color: AppColors.bg, weight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.tint(AppColors.bg, 30), borderRadius: BorderRadius.circular(20)),
                child: Text(hhmm(workout.scheduledAt), style: AppText.body(12, color: AppColors.bg, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(workout.title, style: AppText.display(20, color: AppColors.bg)),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('${workout.durationMin} хв · ${workout.exercises.length} вправ',
                    style: AppText.body(14, color: AppColors.bg, weight: FontWeight.w500)),
              ),
              Material(
                color: AppColors.bg,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: inProgress ? 'Завершити тренування' : 'Почати тренування',
                  icon: Icon(inProgress ? Icons.check : Icons.play_arrow, color: AppColors.lime),
                  onPressed: () => _onPlay(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoWorkoutCard extends StatelessWidget {
  const _NoWorkoutCard({required this.onPlan});

  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          const TintIcon(icon: Icons.event_available, color: AppColors.lime),
          const SizedBox(width: 12),
          Expanded(child: Text('На сьогодні все виконано або не заплановано', style: AppText.body(14, color: AppColors.soft))),
          TextButton(onPressed: onPlan, child: Text('План', style: AppText.body(14, color: AppColors.lime, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit});

  final Habit habit;

  IconData get _icon {
    final n = habit.name.toLowerCase();
    if (n.contains('вод')) return Icons.water_drop_outlined;
    if (n.contains('сон')) return Icons.bedtime_outlined;
    return Icons.self_improvement;
  }

  Color get _color {
    final n = habit.name.toLowerCase();
    if (n.contains('вод')) return AppColors.blue;
    if (n.contains('сон')) return AppColors.lime;
    return AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneToday;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      child: Row(
        children: <Widget>[
          TintIcon(icon: _icon, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(habit.name, style: AppText.body(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${habit.currentValue} з ${habit.dailyTarget} ${habit.unit} · серія ${habit.streakDays} дн.',
                    style: AppText.body(12, color: AppColors.muted)),
              ],
            ),
          ),
          Material(
            color: done ? AppColors.lime : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: done ? BorderSide.none : const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: done ? null : () => context.read<AppState>().markHabit(habit),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(done ? Icons.check : Icons.add, color: done ? AppColors.bg : AppColors.text, semanticLabel: done ? 'Виконано' : 'Відмітити'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
