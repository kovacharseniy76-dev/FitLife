import 'package:fitlife/models/models.dart';
import 'package:fitlife/services/auth_service.dart';
import 'package:fitlife/services/backend.dart';
import 'package:fitlife/services/demo/demo_backend.dart';
import 'package:fitlife/services/demo/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Goal', () {
    test('прогрес для цілі «зменшити вагу»', () {
      final g = Goal(id: 'g', title: 'До 72 кг', startValue: 78, currentValue: 75, targetValue: 72, deadline: DateTime(2030));
      expect(g.getProgress(), closeTo(0.5, 1e-9));
      expect(g.isAchieved(), isFalse);
      g.currentValue = 71.5;
      expect(g.getProgress(), 1.0);
      expect(g.isAchieved(), isTrue);
    });
  });

  group('Habit', () {
    test('серія росте лише один раз на день', () {
      final h = Habit(id: 'h', name: 'Вода', dailyTarget: 2, streakDays: 3);
      h.markDone();
      expect(h.streakDays, 3);
      h.markDone();
      expect(h.streakDays, 4);
      h.markDone();
      expect(h.currentValue, 2);
      h.resetDay();
      expect(h.currentValue, 0);
      expect(h.streakDays, 4);
      h.resetDay(); // учора ціль не виконано
      expect(h.streakDays, 0);
    });
  });

  group('ActivityLog → Statistics', () {
    test('addEntry завершує пов’язане тренування', () {
      final w = Workout(id: 'w', title: 'Сила', scheduledAt: DateTime.now());
      final log = ActivityLog(id: 'log');
      log.addEntry(ActivityEntry(id: 'e', date: DateTime.now(), type: 'Сила', durationMin: 40, workout: w));
      expect(w.status, WorkoutStatus.completed);
    });

    test('buildStatistics рахує суми і серію днів', () {
      final now = DateTime.now();
      DateTime daysAgo(int d) => DateTime(now.year, now.month, now.day - d, 12);
      final log = ActivityLog(id: 'log');
      log.addEntry(ActivityEntry(id: 'a', date: daysAgo(0), type: 'Біг', durationMin: 30, calories: 200, steps: 5000));
      log.addEntry(ActivityEntry(id: 'b', date: daysAgo(1), type: 'Біг', durationMin: 20, calories: 100, steps: 3000));
      log.addEntry(ActivityEntry(id: 'c', date: daysAgo(3), type: 'Біг', durationMin: 10, calories: 50, steps: 1000));
      log.addEntry(ActivityEntry(id: 'old', date: daysAgo(40), type: 'Біг', durationMin: 99));

      final week = log.buildStatistics(StatsPeriod.week);
      expect(week.totalMinutes, 60);
      expect(week.totalCalories, 350);
      expect(week.averageSteps, 3000);
      expect(week.minutesByDay.length, 7);
      expect(week.minutesByDay.last, 30);
      expect(week.getStreak(), 2);
    });
  });

  group('Workout', () {
    test('addExercise нумерує вправи, reschedule переносить нагадування', () {
      final catalog = ExerciseCatalog(seedExercises);
      final at = DateTime(2030, 1, 10, 18);
      final w = Workout(id: 'w', title: 'Ноги', scheduledAt: at)
        ..reminder = Reminder(id: 'r', remindAt: at.subtract(const Duration(minutes: 30)));
      w.addExercise(WorkoutExercise(exercise: catalog.getById('ex_squat')!, order: 0));
      w.addExercise(WorkoutExercise(exercise: catalog.getById('ex_lunge')!, order: 0));
      expect(w.exercises.map((e) => e.order), <int>[1, 2]);
      w.reschedule(DateTime(2030, 1, 11, 18));
      expect(w.reminder!.remindAt, DateTime(2030, 1, 11, 17, 30));
    });
  });

  group('ExerciseCatalog', () {
    test('пошук і фільтр за категорією', () {
      final catalog = ExerciseCatalog(seedExercises);
      expect(catalog.search('план').map((e) => e.id), contains('ex_plank'));
      expect(catalog.filterByCategory(ExerciseCategory.legs).every((e) => e.category == ExerciseCategory.legs), isTrue);
    });
  });

  group('AuthService (сценарій «Увійти в систему»)', () {
    test('успішний вхід і заблокований акаунт', () async {
      final auth = AuthService(DemoBackend());
      final a = await auth.signIn('demo@fitlife.app', 'demo123');
      expect(a, isA<User>());
      expect(auth.currentUserId, 'demo_user');
      await expectLater(auth.signIn('blocked@fitlife.app', 'blocked123'), throwsA(isA<AuthException>()));
      await expectLater(auth.signIn('demo@fitlife.app', 'wrong'), throwsA(isA<AuthException>()));
    });
  });
}
