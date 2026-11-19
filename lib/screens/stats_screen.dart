import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Екран 6 — Статистика (сценарій buildStatistics → calculate → getStreak).
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;

  /// Групує хвилини по днях у стовпчики графіка з підписами.
  List<(String, int)> _bars(Statistics s) {
    final days = s.minutesByDay;
    final now = DateTime.now();
    switch (_period) {
      case StatsPeriod.week:
        return <(String, int)>[
          for (var i = 0; i < days.length; i++)
            (ukWeekdaysShort[DateTime(now.year, now.month, now.day - (days.length - 1 - i)).weekday - 1], days[i]),
        ];
      case StatsPeriod.month:
        const n = 5;
        final size = (days.length / n).ceil();
        return <(String, int)>[
          for (var b = 0; b < n; b++)
            ('Т${b + 1}', days.skip(b * size).take(size).fold(0, (a, v) => a + v)),
        ];
      case StatsPeriod.year:
        const n = 12;
        final size = (days.length / n).ceil();
        return <(String, int)>[
          for (var b = 0; b < n; b++)
            (ukMonths[(now.month - n + b + 12) % 12].substring(0, 3), days.skip(b * size).take(size).fold(0, (a, v) => a + v)),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user!;
    final stats = state.buildStatistics(_period);
    final streak = stats.getStreak();
    final bars = _bars(stats);
    final maxV = bars.fold<int>(1, (m, b) => math.max(m, b.$2));
    final goal = user.goals.isEmpty ? null : user.goals.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: <Widget>[
        Text('Статистика', style: AppText.display(24)),
        const SizedBox(height: 16),
        Segmented(
          labels: <String>[for (final p in StatsPeriod.values) p.label],
          index: _period.index,
          onChanged: (i) => setState(() => _period = StatsPeriod.values[i]),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Хвилини тренувань', style: AppText.body(13, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text('${groupDigits(stats.totalMinutes)} хв', style: AppText.display(26)),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    for (var i = 0; i < bars.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Tooltip(
                                message: '${bars[i].$2} хв',
                                child: Container(
                                  height: math.max(6, 100 * bars[i].$2 / maxV).toDouble(),
                                  decoration: BoxDecoration(
                                    color: i == bars.length - 1 ? AppColors.lime : const Color(0xFF3A434E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(bars[i].$1, style: AppText.body(11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: <Widget>[
            _Tile(label: 'Тренувань', value: '${stats.workoutsCount}', color: AppColors.text),
            _Tile(label: 'Спалено ккал', value: groupDigits(stats.totalCalories), color: AppColors.orange),
            _Tile(label: 'Середні кроки', value: groupDigits(stats.averageSteps), color: AppColors.blue),
            _Tile(label: 'Серія активності', value: '$streak дн.', color: AppColors.lime),
          ],
        ),
        if (goal != null) ...<Widget>[
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            radius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Text('Вага', style: AppText.body(14, weight: FontWeight.w600))),
                  Text('${user.weightKg.toStringAsFixed(1)} кг · ціль ${goal.targetValue.toStringAsFixed(0)} кг',
                      style: AppText.body(13, color: AppColors.muted)),
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
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label, style: AppText.body(12, color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(value, style: AppText.body(22, color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
