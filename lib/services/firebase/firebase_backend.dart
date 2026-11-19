import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../models/models.dart';
import '../backend.dart';
import '../demo/seed_data.dart';

/// Бекенд на Firebase: Authentication (облікові дані), Cloud Firestore (дані),
/// Firebase Cloud Messaging (токен пристрою; надсилання — через Cloud Function,
/// яка читає колекцію `scheduledNotifications`).
///
/// Структура Firestore:
///   users/{uid}                         — профіль і роль ('user' | 'admin' | 'content')
///   users/{uid}/workouts|habits|goals|entries/{id}
///   exercises/{id}                      — каталог вправ
///   scheduledNotifications/{reminderId} — заплановані нагадування
class FirebaseBackend implements FitLifeBackend {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _exercises => _db.collection('exercises');

  static String _message(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Некоректний email';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Невірний email або пароль';
      case 'email-already-in-use':
        return 'Акаунт з таким email вже існує';
      case 'weak-password':
        return 'Пароль має містити щонайменше 6 символів';
      case 'too-many-requests':
        return 'Забагато спроб. Спробуйте пізніше';
      default:
        return e.message ?? 'Помилка автентифікації';
    }
  }

  @override
  Future<String> verifyCredentials(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _registerDeviceToken(cred.user!.uid);
      return cred.user!.uid;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<String> createCredentials(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user!.uid;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> _registerDeviceToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _users.doc(uid).set(<String, dynamic>{'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (_) {
      // Сповіщення не критичні для входу (наприклад, у браузері без VAPID-ключа).
    }
  }

  Account _accountFrom(String id, Map<String, dynamic> m) {
    final role = (m['role'] ?? 'user') as String;
    final status = enumFromName(AccountStatus.values, m['status'] as String?, AccountStatus.active);
    final created = DateTime.tryParse((m['createdAt'] ?? '') as String);
    final email = (m['email'] ?? '') as String;
    final name = (m['name'] ?? '') as String;
    switch (role) {
      case 'admin':
        return Administrator(id: id, email: email, name: name, createdAt: created, status: status);
      case 'content':
        return ContentManager(id: id, email: email, name: name, createdAt: created, status: status);
      default:
        return User.fromMap(id, m);
    }
  }

  Map<String, dynamic> _accountMap(Account a) {
    if (a is User) return a.toMap();
    return <String, dynamic>{
      'email': a.email,
      'name': a.name,
      'role': a is Administrator ? 'admin' : 'content',
      'status': a.status.name,
      'createdAt': a.createdAt.toIso8601String(),
    };
  }

  @override
  Future<Account?> loadAccount(String uid) async {
    final snap = await _users.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return _accountFrom(uid, data);
  }

  @override
  Future<void> saveAccount(Account account) =>
      _users.doc(account.id).set(_accountMap(account), SetOptions(merge: true));

  @override
  Future<List<Account>> listAccounts() async {
    final q = await _users.get();
    return q.docs.map((d) => _accountFrom(d.id, d.data())).toList();
  }

  @override
  Future<List<Exercise>> loadCatalog() async {
    final q = await _exercises.get();
    if (q.docs.isEmpty) {
      // Перший запуск: заповнюємо каталог початковими вправами.
      final batch = _db.batch();
      for (final e in seedExercises) {
        batch.set(_exercises.doc(e.id), e.toMap());
      }
      await batch.commit();
      return List<Exercise>.of(seedExercises);
    }
    return q.docs.map((d) => Exercise.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> saveExercise(Exercise exercise) => _exercises.doc(exercise.id).set(exercise.toMap());

  @override
  Future<void> deleteExercise(String id) => _exercises.doc(id).delete();

  @override
  Future<void> loadUserData(User user, ExerciseCatalog catalog) async {
    final ref = _users.doc(user.id);
    final results = await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      ref.collection('goals').get(),
      ref.collection('habits').get(),
      ref.collection('workouts').get(),
      ref.collection('entries').get(),
    ]);
    user.goals
      ..clear()
      ..addAll(results[0].docs.map((d) => Goal.fromMap(d.id, d.data())));
    user.habits
      ..clear()
      ..addAll(results[1].docs.map((d) => Habit.fromMap(d.id, d.data())));
    user.workouts.clear();
    for (final d in results[2].docs) {
      user.planWorkout(Workout.fromMap(d.id, d.data(), catalog));
    }
    final byId = <String, Workout>{for (final w in user.workouts) w.id: w};
    for (final d in results[3].docs) {
      final data = d.data();
      final entry = ActivityEntry.fromMap(d.id, data, workout: byId[data['workoutId']]);
      // Пов'язане тренування вже має статус «виконано», addEntry лише підтверджує його.
      user.activityLog.addEntry(entry);
    }
  }

  @override
  Future<void> saveWorkout(String uid, Workout workout) =>
      _users.doc(uid).collection('workouts').doc(workout.id).set(workout.toMap());

  @override
  Future<void> saveHabit(String uid, Habit habit) =>
      _users.doc(uid).collection('habits').doc(habit.id).set(habit.toMap());

  @override
  Future<void> saveGoal(String uid, Goal goal) => _users.doc(uid).collection('goals').doc(goal.id).set(goal.toMap());

  @override
  Future<void> saveEntry(String uid, ActivityEntry entry) =>
      _users.doc(uid).collection('entries').doc(entry.id).set(entry.toMap());

  @override
  Future<void> scheduleReminder(String uid, Reminder reminder, String workoutTitle) =>
      _db.collection('scheduledNotifications').doc(reminder.id).set(<String, dynamic>{
        'userId': uid,
        'title': 'Нагадування FitLife',
        'body': 'Через ${reminder.minutesBefore} хв: «$workoutTitle»',
        'sendAt': reminder.remindAt.toIso8601String(),
        'sent': false,
      });

  @override
  Future<void> cancelReminder(String reminderId) => _db.collection('scheduledNotifications').doc(reminderId).delete();

  @override
  Future<void> sendPush(String uid, String message) async {
    // Безпосереднє надсилання push виконує сервер (Cloud Function) за fcmToken користувача.
  }
}
