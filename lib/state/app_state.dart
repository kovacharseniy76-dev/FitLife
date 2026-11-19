import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/backend.dart';
import '../services/notification_service.dart';

/// Вправа, яку користувач обрав під час планування тренування.
class PlannedExercise {
  const PlannedExercise({required this.exerciseId, this.sets = 3, this.reps = 12, this.weightKg = 0});
  final String exerciseId;
  final int sets;
  final int reps;
  final double weightKg;
}

/// Стан застосунку. Методи повторюють сценарії з діаграм кооперації та послідовності.
class AppState extends ChangeNotifier {
  AppState(this.backend)
      : auth = AuthService(backend),
        notifications = NotificationService(backend);

  final FitLifeBackend backend;
  final AuthService auth;
  final NotificationService notifications;

  ExerciseCatalog catalog = ExerciseCatalog();
  Account? account;
  bool loading = true;

  User? get user {
    final a = account;
    return a is User ? a : null;
  }

  String _id(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> init() async {
    try {
      catalog = ExerciseCatalog(await backend.loadCatalog());
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Сценарій 1. Увійти в систему
  // ------------------------------------------------------------------

  /// Повертає null у разі успіху або текст помилки.
  Future<String?> signIn(String email, String password) async {
    try {
      final a = await auth.signIn(email, password);
      await _afterLogin(a);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не вдалося увійти: $e';
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      final a = await auth.signUp(email, password, name: name);
      await _afterLogin(a);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не вдалося зареєструватися: $e';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await auth.sendPasswordReset(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не вдалося надіслати лист: $e';
    }
  }

  Future<void> _afterLogin(Account a) async {
    account = a;
    if (a is User) {
      await backend.loadUserData(a, catalog);
      for (final w in a.workouts) {
        final r = w.reminder;
        if (r != null && r.enabled && w.status == WorkoutStatus.planned && r.remindAt.isAfter(DateTime.now())) {
          r.schedule();
          await notifications.scheduleNotification(r, userId: a.id, workoutTitle: w.title);
        }
      }
    } else if (a is ContentManager) {
      a.catalog = catalog;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    account = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Сценарій 2. Спланувати тренування з нагадуванням
  // ------------------------------------------------------------------

  Future<Workout> planWorkout({
    required String title,
    required DateTime scheduledAt,
    required int durationMin,
    required List<PlannedExercise> items,
    bool reminderEnabled = false,
    int minutesBefore = 30,
  }) async {
    final u = user!;
    // 1.1 «create» Workout(title, scheduledAt)
    final w = Workout(id: _id('w'), title: title, scheduledAt: scheduledAt, durationMin: durationMin);
    // loop [для кожної вправи]: getById(id) → addExercise(item) → «create» WorkoutExercise
    for (final it in items) {
      final ex = catalog.getById(it.exerciseId);
      if (ex == null) continue;
      w.addExercise(WorkoutExercise(exercise: ex, order: 0, sets: it.sets, reps: it.reps, weightKg: it.weightKg));
    }
    // opt [нагадування увімкнено]: schedule() → scheduleNotification(reminder)
    if (reminderEnabled) {
      final r = Reminder(
        id: 'rem_${w.id}',
        remindAt: scheduledAt.subtract(Duration(minutes: minutesBefore)),
        minutesBefore: minutesBefore,
      );
      w.reminder = r;
      r.schedule();
      await notifications.scheduleNotification(r, userId: u.id, workoutTitle: title);
    }
    u.planWorkout(w);
    await backend.saveWorkout(u.id, w);
    notifyListeners();
    return w;
  }

  Future<void> startWorkout(Workout w) async {
    w.start();
    await backend.saveWorkout(user!.id, w);
    notifyListeners();
  }

  /// Workout.reschedule(date) з повторним плануванням нагадування.
  Future<void> rescheduleWorkout(Workout w, DateTime date) async {
    final u = user!;
    w.reschedule(date);
    final r = w.reminder;
    if (r != null && r.enabled) {
      await notifications.cancelNotification(r.id);
      r.enabled = true;
      r.schedule();
      await notifications.scheduleNotification(r, userId: u.id, workoutTitle: w.title);
    }
    u.workouts.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    await backend.saveWorkout(u.id, w);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Сценарій 3. Записати активність і переглянути статистику
  // ------------------------------------------------------------------

  Future<void> addEntry({
    required String type,
    required int durationMin,
    int calories = 0,
    int steps = 0,
    String notes = '',
    Workout? workout,
  }) async {
    final u = user!;
    // 1.1 «create» ActivityEntry(...)
    final entry = ActivityEntry(
      id: _id('e'),
      date: DateTime.now(),
      type: type,
      durationMin: durationMin,
      calories: calories,
      steps: steps,
      notes: notes,
      workout: workout,
    );
    // addEntry → opt [запис пов'язаний із тренуванням]: complete()
    u.activityLog.addEntry(entry);
    await backend.saveEntry(u.id, entry);
    if (workout != null) {
      final r = workout.reminder;
      if (r != null) await notifications.cancelNotification(r.id);
      await backend.saveWorkout(u.id, workout);
    }
    notifyListeners();
  }

  /// buildStatistics(period) → «create» Statistics → calculate(entries); getStreak() викликає екран.
  Statistics buildStatistics(StatsPeriod period) => user!.activityLog.buildStatistics(period);

  // ------------------------------------------------------------------
  // Звички, цілі, профіль
  // ------------------------------------------------------------------

  Future<void> markHabit(Habit habit) async {
    habit.markDone();
    await backend.saveHabit(user!.id, habit);
    notifyListeners();
  }

  Future<void> updateProfile(String name, double weightKg) async {
    final u = user!;
    u.updateProfile(name, weightKg);
    for (final g in u.goals) {
      if (g.title.toLowerCase().contains('кг')) {
        g.currentValue = weightKg;
        await backend.saveGoal(u.id, g);
      }
    }
    await backend.saveAccount(u);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Адміністратор і контент-менеджер
  // ------------------------------------------------------------------

  Future<List<Account>> listAccounts() => backend.listAccounts();

  Future<void> toggleBlock(Account target) async {
    final admin = account;
    if (admin is! Administrator || target.id == admin.id) return;
    if (target.isActive()) {
      admin.blockAccount(target);
    } else {
      admin.unblockAccount(target);
    }
    await backend.saveAccount(target);
    notifyListeners();
  }

  Future<void> addExercise(Exercise e) async {
    final cm = account;
    if (cm is! ContentManager) return;
    cm.addExercise(e);
    await backend.saveExercise(e);
    notifyListeners();
  }

  Future<void> deleteExercise(String id) async {
    final cm = account;
    if (cm is! ContentManager) return;
    cm.deleteExercise(id);
    await backend.deleteExercise(id);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Допоміжні значення для головного екрана
  // ------------------------------------------------------------------

  List<ActivityEntry> get todayEntries {
    final u = user;
    if (u == null) return const <ActivityEntry>[];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return u.activityLog.getEntries(start, now.add(const Duration(days: 1)));
  }

  int get todaySteps => todayEntries.fold(0, (s, e) => s + e.steps);
  int get todayCalories => todayEntries.fold(0, (s, e) => s + e.calories);
  int get todayMinutes => todayEntries.fold(0, (s, e) => s + e.durationMin);

  List<Workout> workoutsOn(DateTime day) {
    final u = user;
    if (u == null) return const <Workout>[];
    return u.workouts
        .where((w) => w.scheduledAt.year == day.year && w.scheduledAt.month == day.month && w.scheduledAt.day == day.day)
        .toList();
  }

  /// Найближче незавершене тренування на сьогодні.
  Workout? get nextWorkoutToday {
    for (final w in workoutsOn(DateTime.now())) {
      if (w.status != WorkoutStatus.completed && w.status != WorkoutStatus.skipped) return w;
    }
    return null;
  }

  @override
  void dispose() {
    notifications.dispose();
    super.dispose();
  }
}
