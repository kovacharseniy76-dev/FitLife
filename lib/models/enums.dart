/// Переліки з діаграми класів FitLife.

enum AccountStatus { active, blocked }

enum WorkoutStatus { planned, inProgress, completed, skipped }

enum ExerciseCategory { strength, cardio, core, legs, flexibility }

enum Difficulty { beginner, intermediate, advanced }

enum StatsPeriod { week, month, year }

extension WorkoutStatusLabel on WorkoutStatus {
  String get label {
    switch (this) {
      case WorkoutStatus.planned:
        return 'Заплановано';
      case WorkoutStatus.inProgress:
        return 'Триває';
      case WorkoutStatus.completed:
        return 'Виконано';
      case WorkoutStatus.skipped:
        return 'Пропущено';
    }
  }
}

extension ExerciseCategoryLabel on ExerciseCategory {
  String get label {
    switch (this) {
      case ExerciseCategory.strength:
        return 'Сила';
      case ExerciseCategory.cardio:
        return 'Кардіо';
      case ExerciseCategory.core:
        return 'Прес';
      case ExerciseCategory.legs:
        return 'Ноги';
      case ExerciseCategory.flexibility:
        return 'Гнучкість';
    }
  }
}

extension DifficultyLabel on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.beginner:
        return 'Легкий';
      case Difficulty.intermediate:
        return 'Середній';
      case Difficulty.advanced:
        return 'Складний';
    }
  }
}

extension StatsPeriodInfo on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.week:
        return 'Тиждень';
      case StatsPeriod.month:
        return 'Місяць';
      case StatsPeriod.year:
        return 'Рік';
    }
  }

  /// Кількість днів, які охоплює період.
  int get days {
    switch (this) {
      case StatsPeriod.week:
        return 7;
      case StatsPeriod.month:
        return 30;
      case StatsPeriod.year:
        return 365;
    }
  }
}

/// Безпечне читання переліку з рядка (для Firestore).
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
