import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'sheets.dart';

/// Екран 4 — Планувальник: тижнева смуга днів і розклад обраного дня.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _selected = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Календарна арифметика через конструктор DateTime — без зсувів під час переходу на літній/зимовий час.
  DateTime get _weekStart => DateTime(_selected.year, _selected.month, _selected.day - (_selected.weekday - 1));

  void _shiftWeek(int weeks) =>
      setState(() => _selected = DateTime(_selected.year, _selected.month, _selected.day + 7 * weeks));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user!;
    final ws = _weekStart;
    final days = <DateTime>[for (var i = 0; i < 7; i++) DateTime(ws.year, ws.month, ws.day + i)];
    final weekEnd = DateTime(ws.year, ws.month, ws.day + 7);
    final weekCount =
        user.workouts.where((w) => !w.scheduledAt.isBefore(ws) && w.scheduledAt.isBefore(weekEnd)).length;
    final items = state.workoutsOn(_selected);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Планувальник', style: AppText.display(24)),
                      const SizedBox(height: 4),
                      Text('${ukMonths[_selected.month - 1]} ${_selected.year} · тренувань за тиждень: $weekCount',
                          style: AppText.body(14, color: AppColors.muted)),
                    ],
                  ),
                ),
                SquareIconButton(icon: Icons.chevron_left, tooltip: 'Попередній тиждень', onPressed: () => _shiftWeek(-1)),
                const SizedBox(width: 8),
                SquareIconButton(icon: Icons.chevron_right, tooltip: 'Наступний тиждень', onPressed: () => _shiftWeek(1)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                for (final d in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _DayCell(
                        day: d,
                        selected: d == _selected,
                        hasWorkouts: state.workoutsOn(d).isNotEmpty,
                        onTap: () => setState(() => _selected = d),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SectionHeader(title: 'Розклад на ${_selected.day} ${ukMonthsGen[_selected.month - 1]}'),
            const SizedBox(height: 6),
            if (items.isEmpty) const EmptyHint(text: 'На цей день тренувань немає. Натисніть «+», щоб додати.', icon: Icons.event_busy),
            for (final w in items) ...<Widget>[_WorkoutRow(workout: w), const SizedBox(height: 12)],
            const SizedBox(height: 6),
            AppCard(
              padding: const EdgeInsets.all(16),
              radius: 18,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.notifications_active_outlined, color: AppColors.lime),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: state.notifications,
                      builder: (context, _) => Text(
                        'Заплановано нагадувань: ${state.notifications.scheduledCount}',
                        style: AppText.body(14, color: AppColors.soft),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            tooltip: 'Додати тренування',
            backgroundColor: AppColors.lime,
            foregroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => showPlanWorkoutSheet(context, day: _selected),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.hasWorkouts, required this.onTap});

  final DateTime day;
  final bool selected;
  final bool hasWorkouts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.bg : AppColors.text;
    return Material(
      color: selected ? AppColors.lime : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(ukWeekdaysShort[day.weekday - 1], style: AppText.body(11, color: selected ? AppColors.bg : AppColors.muted)),
              const SizedBox(height: 3),
              Text('${day.day}', style: AppText.body(17, color: fg, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasWorkouts ? (selected ? AppColors.bg : AppColors.lime) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final done = workout.status == WorkoutStatus.completed;
    final category = workout.exercises.isEmpty ? null : workout.exercises.first.exercise.category;
    final tagColor = done ? AppColors.lime : (category == null ? AppColors.soft : categoryColor(category));
    final tagText = done ? 'Виконано' : (category?.label ?? workout.status.label);
    final highlight = workout.status == WorkoutStatus.inProgress;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(hhmm(workout.scheduledAt),
                style: AppText.body(13, color: highlight ? AppColors.lime : AppColors.muted, weight: FontWeight.w600)),
          ),
        ),
        Expanded(
          child: Opacity(
            opacity: done ? 0.7 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showDetails(context),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                radius: 18,
                border: highlight ? AppColors.lime : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(
                        child: Text(
                          workout.title,
                          style: AppText.body(15, weight: FontWeight.w600).copyWith(
                            decoration: done ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.muted,
                          ),
                        ),
                      ),
                      Text(tagText, style: AppText.body(12, color: tagColor, weight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      '${workout.durationMin} хв · ${workout.exercises.length} вправ${workout.reminder?.enabled == true ? ' · нагадування' : ''}',
                      style: AppText.body(13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(workout.title, style: AppText.display(20)),
            const SizedBox(height: 6),
            Text('${hhmm(workout.scheduledAt)} · ${workout.durationMin} хв · ${workout.status.label}',
                style: AppText.body(14, color: AppColors.muted)),
            const SizedBox(height: 14),
            for (final item in workout.exercises)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: TintIcon(icon: categoryIcon(item.exercise.category), color: categoryColor(item.exercise.category), size: 36),
                title: Text('${item.order}. ${item.exercise.name}', style: AppText.body(15, weight: FontWeight.w600)),
                subtitle: Text('${item.sets} × ${item.reps}${item.weightKg > 0 ? ' · ${item.weightKg} кг' : ''}',
                    style: AppText.body(13, color: AppColors.muted)),
              ),
            const SizedBox(height: 12),
            if (workout.status == WorkoutStatus.planned)
              AppButton(
                label: 'Почати тренування',
                icon: Icons.play_arrow,
                onPressed: () {
                  state.startWorkout(workout);
                  Navigator.of(ctx).pop();
                },
              )
            else if (workout.status == WorkoutStatus.inProgress)
              AppButton(
                label: 'Завершити й записати',
                icon: Icons.check,
                onPressed: () {
                  state.addEntry(
                    type: workout.title,
                    durationMin: workout.durationMin,
                    calories: workout.durationMin * 8,
                    workout: workout,
                  );
                  Navigator.of(ctx).pop();
                },
              ),
            if (workout.status != WorkoutStatus.completed) ...<Widget>[
              const SizedBox(height: 10),
              AppButton(
                label: 'Перенести на завтра',
                primary: false,
                onPressed: () {
                  final d = workout.scheduledAt;
                  state.rescheduleWorkout(workout, DateTime(d.year, d.month, d.day + 1, d.hour, d.minute));
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
