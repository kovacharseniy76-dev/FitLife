import '../../models/models.dart';

/// Початковий каталог вправ (використовується і в демо-режимі, і для першого заповнення Firestore).
const List<Exercise> seedExercises = <Exercise>[
  Exercise(id: 'ex_bench', name: 'Жим лежачи', description: 'Базова вправа для грудних м’язів зі штангою або гантелями.',
      category: ExerciseCategory.strength, muscleGroup: 'Груди', difficulty: Difficulty.intermediate),
  Exercise(id: 'ex_pullup', name: 'Підтягування', description: 'Підтягування на перекладині широким хватом.',
      category: ExerciseCategory.strength, muscleGroup: 'Спина', difficulty: Difficulty.advanced),
  Exercise(id: 'ex_pushup', name: 'Віджимання', description: 'Віджимання від підлоги з рівною спиною.',
      category: ExerciseCategory.strength, muscleGroup: 'Груди, трицепс', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_run', name: 'Біг на місці', description: 'Ритмічний біг на місці з активною роботою рук.',
      category: ExerciseCategory.cardio, muscleGroup: 'Все тіло', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_burpee', name: 'Берпі', description: 'Присід, упор лежачи, віджимання і стрибок угору.',
      category: ExerciseCategory.cardio, muscleGroup: 'Все тіло', difficulty: Difficulty.advanced),
  Exercise(id: 'ex_jump', name: 'Стрибки «зірочка»', description: 'Стрибки з розведенням рук і ніг.',
      category: ExerciseCategory.cardio, muscleGroup: 'Все тіло', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_plank', name: 'Планка', description: 'Утримання тіла в прямій лінії на передпліччях.',
      category: ExerciseCategory.core, muscleGroup: 'Кор', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_crunch', name: 'Скручування', description: 'Підйом корпусу лежачи на спині.',
      category: ExerciseCategory.core, muscleGroup: 'Прес', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_squat', name: 'Присідання', description: 'Присідання до паралелі стегон з підлогою.',
      category: ExerciseCategory.legs, muscleGroup: 'Квадрицепс', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_lunge', name: 'Випади', description: 'Крок уперед з опусканням коліна майже до підлоги.',
      category: ExerciseCategory.legs, muscleGroup: 'Сідниці', difficulty: Difficulty.intermediate),
  Exercise(id: 'ex_stretch', name: 'Нахили до ніг', description: 'Плавні нахили з прямими ногами.',
      category: ExerciseCategory.flexibility, muscleGroup: 'Задня поверхня стегна', difficulty: Difficulty.beginner),
  Exercise(id: 'ex_cobra', name: 'Поза кобри', description: 'Прогин у спині з упором на долоні.',
      category: ExerciseCategory.flexibility, muscleGroup: 'Спина', difficulty: Difficulty.beginner),
];

/// Тестовий користувач із даними, схожими на макети з Figma.
User buildDemoUser(ExerciseCatalog catalog) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final user = User(
    id: 'demo_user',
    email: 'demo@fitlife.app',
    name: 'Арсеній',
    createdAt: today.subtract(const Duration(days: 60)),
    birthDate: DateTime(now.year - 19, 3, 14),
    heightCm: 181,
    weightKg: 74.2,
  );

  user.goals.add(Goal(
    id: 'goal_weight',
    title: 'Схуднути до 72 кг',
    startValue: 78.3,
    currentValue: 74.2,
    targetValue: 72,
    deadline: today.add(const Duration(days: 35)),
  ));

  user.habits.addAll(<Habit>[
    Habit(id: 'h_water', name: 'Вода', dailyTarget: 8, currentValue: 5, streakDays: 12, unit: 'склянок'),
    Habit(id: 'h_sleep', name: 'Сон 8 годин', dailyTarget: 1, currentValue: 1, streakDays: 6, unit: 'раз'),
    Habit(id: 'h_stretch', name: 'Розтяжка', dailyTarget: 1, currentValue: 0, streakDays: 3, unit: 'раз'),
  ]);

  Exercise ex(String id) => catalog.getById(id)!;
  Workout mk(String id, String title, DateTime at, int min, List<String> exIds, {bool reminder = false}) {
    final w = Workout(id: id, title: title, scheduledAt: at, durationMin: min);
    for (final e in exIds) {
      w.addExercise(WorkoutExercise(exercise: ex(e), order: 0, sets: 3, reps: 12));
    }
    if (reminder) {
      w.reminder = Reminder(id: 'rem_$id', remindAt: at.subtract(const Duration(minutes: 30)));
    }
    return w;
  }

  final stretch = mk('w_morning', 'Ранкова розтяжка', today.add(const Duration(hours: 7)), 15, <String>['ex_stretch', 'ex_cobra']);
  final walk = mk('w_walk', 'Прогулянка 3 км', today.add(const Duration(hours: 13)), 35, <String>['ex_run']);
  final strength = mk('w_upper', 'Сила: верх тіла', today.add(const Duration(hours: 18, minutes: 30)), 45,
      <String>['ex_bench', 'ex_pullup', 'ex_pushup', 'ex_plank'], reminder: true);
  final legs = mk('w_legs', 'Ноги та прес', today.add(const Duration(days: 2, hours: 18)), 40,
      <String>['ex_squat', 'ex_lunge', 'ex_crunch']);
  final cardio = mk('w_cardio', 'Кардіо-інтервали', today.add(const Duration(days: 4, hours: 9)), 30,
      <String>['ex_jump', 'ex_burpee', 'ex_run']);
  for (final w in <Workout>[stretch, walk, strength, legs, cardio]) {
    user.planWorkout(w);
  }

  // Щоденник за останні 5 тижнів: детерміновані «реалістичні» значення.
  const minutes = <int>[35, 0, 45, 20, 60, 30, 0, 40, 25, 50, 0, 35, 45, 30, 0, 55, 20, 40, 35, 0, 30, 45, 25, 60, 0, 40, 35];
  var n = 0;
  for (var d = minutes.length; d >= 1; d--) {
    final m = minutes[minutes.length - d];
    if (m == 0) continue;
    n++;
    user.activityLog.addEntry(ActivityEntry(
      id: 'e$n',
      date: today.subtract(Duration(days: d)).add(const Duration(hours: 18)),
      type: m >= 45 ? 'Силове тренування' : (m >= 30 ? 'Кардіо' : 'Прогулянка'),
      durationMin: m,
      calories: m * 8,
      steps: 6000 + (m * 53) % 4000,
    ));
  }
  // Сьогоднішня ранкова розтяжка вже виконана — запис пов'язаний із тренуванням.
  user.activityLog.addEntry(ActivityEntry(
    id: 'e_today',
    date: today.add(const Duration(hours: 7, minutes: 20)),
    type: 'Розтяжка',
    durationMin: 15,
    calories: 60,
    steps: 6842,
    workout: stretch,
  ));
  return user;
}
