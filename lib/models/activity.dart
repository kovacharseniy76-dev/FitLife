import 'enums.dart';
import 'workout.dart';

/// Запис у щоденнику активності.
class ActivityEntry {
  ActivityEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.durationMin,
    this.calories = 0,
    this.steps = 0,
    this.notes = '',
    this.workout,
  });

  final String id;
  final DateTime date;
  final String type;
  final int durationMin;
  final int calories;
  final int steps;
  final String notes;

  /// Тренування, з яким пов'язаний запис (0..1).
  final Workout? workout;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'type': type,
        'durationMin': durationMin,
        'calories': calories,
        'steps': steps,
        'notes': notes,
        'workoutId': workout?.id,
      };

  factory ActivityEntry.fromMap(String id, Map<String, dynamic> m, {Workout? workout}) => ActivityEntry(
        id: id,
        date: DateTime.tryParse((m['date'] ?? '') as String) ?? DateTime.now(),
        type: (m['type'] ?? '') as String,
        durationMin: ((m['durationMin'] ?? 0) as num).toInt(),
        calories: ((m['calories'] ?? 0) as num).toInt(),
        steps: ((m['steps'] ?? 0) as num).toInt(),
        notes: (m['notes'] ?? '') as String,
        workout: workout,
      );
}

/// Підсумки активності за період. Створюється щоденником (ActivityLog.buildStatistics).
class Statistics {
  Statistics(this.period);

  final StatsPeriod period;
  int totalMinutes = 0;
  int totalCalories = 0;
  int workoutsCount = 0;
  int averageSteps = 0;

  List<ActivityEntry> _entries = const <ActivityEntry>[];

  /// Хвилини активності по днях періоду (для стовпчикового графіка), від найстаршого дня.
  List<int> minutesByDay = const <int>[];

  void calculate(List<ActivityEntry> entries) {
    _entries = List<ActivityEntry>.of(entries);
    totalMinutes = entries.fold(0, (s, e) => s + e.durationMin);
    totalCalories = entries.fold(0, (s, e) => s + e.calories);
    workoutsCount = entries.where((e) => e.workout != null).length;
    final days = period.days;
    final today = _day(DateTime.now());
    final byDay = List<int>.filled(days, 0);
    final stepsByDay = <DateTime, int>{};
    for (final e in entries) {
      final d = _day(e.date);
      final idx = days - 1 - _daysBetween(d, today);
      if (idx >= 0 && idx < days) byDay[idx] += e.durationMin;
      stepsByDay[d] = (stepsByDay[d] ?? 0) + e.steps;
    }
    minutesByDay = byDay;
    averageSteps = stepsByDay.isEmpty ? 0 : (stepsByDay.values.fold(0, (s, v) => s + v) / stepsByDay.length).round();
  }

  /// Кількість днів поспіль (до сьогодні включно), у які була хоча б одна активність.
  int getStreak() {
    final active = _entries.map((e) => _day(e.date)).toSet();
    var day = _day(DateTime.now());
    if (!active.contains(day)) day = _prev(day);
    var streak = 0;
    while (active.contains(day)) {
      streak++;
      day = _prev(day);
    }
    return streak;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _prev(DateTime d) => DateTime(d.year, d.month, d.day - 1);

  /// Кількість календарних днів між датами (через UTC, щоб перехід на літній час не зсував результат).
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

/// Щоденник активності користувача. Композиція: володіє записами ActivityEntry.
class ActivityLog {
  ActivityLog({required this.id, List<ActivityEntry>? entries}) : _entries = entries ?? <ActivityEntry>[];

  final String id;
  final List<ActivityEntry> _entries;

  List<ActivityEntry> get entries => List<ActivityEntry>.unmodifiable(_entries);

  /// Сценарій «Записати активність»: додає запис і, якщо він пов'язаний
  /// з тренуванням, позначає тренування виконаним.
  void addEntry(ActivityEntry entry) {
    _entries.add(entry);
    _entries.sort((a, b) => b.date.compareTo(a.date));
    entry.workout?.complete();
  }

  List<ActivityEntry> getEntries(DateTime from, DateTime to) =>
      _entries.where((e) => !e.date.isBefore(from) && !e.date.isAfter(to)).toList();

  /// Сценарій «Переглянути статистику»: створює Statistics і рахує показники.
  Statistics buildStatistics(StatsPeriod period) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - (period.days - 1));
    final stats = Statistics(period);
    stats.calculate(getEntries(from, now.add(const Duration(days: 1))));
    return stats;
  }
}
