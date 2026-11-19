import '../models/models.dart';

/// Помилка автентифікації з повідомленням для користувача.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Інтерфейс бекенда. Дві реалізації: DemoBackend (дані в пам'яті)
/// і FirebaseBackend (Firebase Authentication + Cloud Firestore + FCM).
abstract class FitLifeBackend {
  // --- Firebase Authentication ---
  /// Перевіряє email і пароль, повертає uid (повідомлення verifyCredentials на діаграмах).
  Future<String> verifyCredentials(String email, String password);
  Future<String> createCredentials(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);

  // --- Cloud Firestore ---
  /// Завантажує акаунт із бази (повідомлення loadAccount на діаграмах).
  Future<Account?> loadAccount(String uid);
  Future<void> saveAccount(Account account);
  Future<List<Account>> listAccounts();

  Future<List<Exercise>> loadCatalog();
  Future<void> saveExercise(Exercise exercise);
  Future<void> deleteExercise(String id);

  /// Заповнює цілі, звички, тренування та щоденник користувача.
  Future<void> loadUserData(User user, ExerciseCatalog catalog);
  Future<void> saveWorkout(String uid, Workout workout);
  Future<void> saveHabit(String uid, Habit habit);
  Future<void> saveGoal(String uid, Goal goal);
  Future<void> saveEntry(String uid, ActivityEntry entry);

  // --- Firebase Cloud Messaging ---
  Future<void> scheduleReminder(String uid, Reminder reminder, String workoutTitle);
  Future<void> cancelReminder(String reminderId);
  Future<void> sendPush(String uid, String message);
}
