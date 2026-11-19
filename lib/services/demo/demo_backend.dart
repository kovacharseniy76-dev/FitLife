import '../../models/models.dart';
import '../backend.dart';
import 'seed_data.dart';

/// Демо-бекенд: усі дані в пам'яті. Дозволяє запустити застосунок без налаштування Firebase.
///
/// Тестові акаунти:
///  - demo@fitlife.app / demo123 — користувач із заповненими даними
///  - admin@fitlife.app / admin123 — адміністратор
///  - content@fitlife.app / content123 — контент-менеджер
///  - blocked@fitlife.app / blocked123 — заблокований користувач (гілка «акаунт заблоковано»)
class DemoBackend implements FitLifeBackend {
  DemoBackend() {
    final catalog = ExerciseCatalog(seedExercises);
    _exercises.addAll(seedExercises);
    final demo = buildDemoUser(catalog);
    final admin = Administrator(id: 'admin', email: 'admin@fitlife.app', name: 'Адміністратор');
    final content = ContentManager(id: 'content', email: 'content@fitlife.app', name: 'Контент-менеджер');
    final blocked = User(id: 'blocked', email: 'blocked@fitlife.app', name: 'Олег', status: AccountStatus.blocked);
    for (final a in <Account>[demo, admin, content, blocked]) {
      _accounts[a.id] = a;
    }
    _passwords['demo@fitlife.app'] = 'demo123';
    _passwords['admin@fitlife.app'] = 'admin123';
    _passwords['content@fitlife.app'] = 'content123';
    _passwords['blocked@fitlife.app'] = 'blocked123';
  }

  final Map<String, Account> _accounts = <String, Account>{};
  final Map<String, String> _passwords = <String, String>{};
  final List<Exercise> _exercises = <Exercise>[];
  int _seq = 0;

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 250));

  Account? _byEmail(String email) {
    for (final a in _accounts.values) {
      if (a.email.toLowerCase() == email.toLowerCase()) return a;
    }
    return null;
  }

  @override
  Future<String> verifyCredentials(String email, String password) async {
    await _latency();
    final account = _byEmail(email);
    if (account == null || _passwords[account.email] != password) {
      throw AuthException('Невірний email або пароль');
    }
    return account.id;
  }

  @override
  Future<String> createCredentials(String email, String password) async {
    await _latency();
    if (!email.contains('@')) throw AuthException('Некоректний email');
    if (password.length < 6) throw AuthException('Пароль має містити щонайменше 6 символів');
    if (_byEmail(email) != null) throw AuthException('Акаунт з таким email вже існує');
    _passwords[email] = password;
    return 'user_${++_seq}';
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {
    await _latency();
    if (_byEmail(email) == null) throw AuthException('Акаунт з таким email не знайдено');
  }

  @override
  Future<Account?> loadAccount(String uid) async {
    await _latency();
    return _accounts[uid];
  }

  @override
  Future<void> saveAccount(Account account) async {
    _accounts[account.id] = account;
  }

  @override
  Future<List<Account>> listAccounts() async => _accounts.values.toList();

  @override
  Future<List<Exercise>> loadCatalog() async => List<Exercise>.of(_exercises);

  @override
  Future<void> saveExercise(Exercise exercise) async {
    _exercises.removeWhere((e) => e.id == exercise.id);
    _exercises.add(exercise);
  }

  @override
  Future<void> deleteExercise(String id) async => _exercises.removeWhere((e) => e.id == id);

  // Дані користувача вже зберігаються всередині об'єкта User у пам'яті.
  @override
  Future<void> loadUserData(User user, ExerciseCatalog catalog) async {}
  @override
  Future<void> saveWorkout(String uid, Workout workout) async {}
  @override
  Future<void> saveHabit(String uid, Habit habit) async {}
  @override
  Future<void> saveGoal(String uid, Goal goal) async {}
  @override
  Future<void> saveEntry(String uid, ActivityEntry entry) async {}

  @override
  Future<void> scheduleReminder(String uid, Reminder reminder, String workoutTitle) async {}
  @override
  Future<void> cancelReminder(String reminderId) async {}
  @override
  Future<void> sendPush(String uid, String message) async {}
}
