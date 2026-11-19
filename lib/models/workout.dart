import 'enums.dart';
import 'exercise.dart';

/// Вправа у складі конкретного тренування (підходи, повторення, вага).
class WorkoutExercise {
  WorkoutExercise({
    required this.exercise,
    required this.order,
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0,
  });

  final Exercise exercise;
  int order;
  int sets;
  int reps;
  double weightKg;

  Map<String, dynamic> toMap() => {
        'exerciseId': exercise.id,
        'order': order,
        'sets': sets,
        'reps': reps,
        'weightKg': weightKg,
      };
}

/// Нагадування про тренування. Композиція: належить одному Workout.
class Reminder {
  Reminder({
    required this.id,
    required this.remindAt,
    this.minutesBefore = 30,
    this.enabled = true,
  });

  final String id;
  DateTime remindAt;
  int minutesBefore;
  bool enabled;

  bool _scheduled = false;
  bool get isScheduled => _scheduled;

  /// Позначає нагадування запланованим. Саме надсилання виконує NotificationService
  /// (див. сценарій «Спланувати тренування з нагадуванням»).
  void schedule() {
    if (enabled) _scheduled = true;
  }

  void cancel() {
    _scheduled = false;
    enabled = false;
  }

  Map<String, dynamic> toMap() => {
        'remindAt': remindAt.toIso8601String(),
        'minutesBefore': minutesBefore,
        'enabled': enabled,
      };
}

/// Тренування в розкладі користувача.
class Workout {
  Workout({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.durationMin = 45,
    this.status = WorkoutStatus.planned,
    List<WorkoutExercise>? exercises,
    this.reminder,
  }) : exercises = exercises ?? <WorkoutExercise>[];

  final String id;
  String title;
  DateTime scheduledAt;
  int durationMin;
  WorkoutStatus status;

  final List<WorkoutExercise> exercises;
  Reminder? reminder;

  void addExercise(WorkoutExercise item) {
    item.order = exercises.length + 1;
    exercises.add(item);
  }

  void start() {
    if (status == WorkoutStatus.planned) status = WorkoutStatus.inProgress;
  }

  void complete() {
    status = WorkoutStatus.completed;
    reminder?.cancel();
  }

  void reschedule(DateTime date) {
    scheduledAt = date;
    status = WorkoutStatus.planned;
    final r = reminder;
    if (r != null) {
      r.remindAt = date.subtract(Duration(minutes: r.minutesBefore));
    }
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMin': durationMin,
        'status': status.name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'reminder': reminder?.toMap(),
      };

  /// Відновлення з Firestore. Вправи шукаються в каталозі за id.
  factory Workout.fromMap(String id, Map<String, dynamic> m, ExerciseCatalog catalog) {
    final w = Workout(
      id: id,
      title: (m['title'] ?? '') as String,
      scheduledAt: DateTime.tryParse((m['scheduledAt'] ?? '') as String) ?? DateTime.now(),
      durationMin: ((m['durationMin'] ?? 45) as num).toInt(),
      status: enumFromName(WorkoutStatus.values, m['status'] as String?, WorkoutStatus.planned),
    );
    final items = (m['exercises'] as List<dynamic>?) ?? const <dynamic>[];
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw as Map);
      final ex = catalog.getById((item['exerciseId'] ?? '') as String);
      if (ex == null) continue;
      w.exercises.add(WorkoutExercise(
        exercise: ex,
        order: ((item['order'] ?? 0) as num).toInt(),
        sets: ((item['sets'] ?? 3) as num).toInt(),
        reps: ((item['reps'] ?? 10) as num).toInt(),
        weightKg: ((item['weightKg'] ?? 0) as num).toDouble(),
      ));
    }
    final r = m['reminder'];
    if (r is Map) {
      final rm = Map<String, dynamic>.from(r);
      w.reminder = Reminder(
        id: 'rem_$id',
        remindAt: DateTime.tryParse((rm['remindAt'] ?? '') as String) ?? w.scheduledAt,
        minutesBefore: ((rm['minutesBefore'] ?? 30) as num).toInt(),
        enabled: (rm['enabled'] ?? true) as bool,
      );
    }
    return w;
  }
}
