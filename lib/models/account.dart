import 'activity.dart';
import 'enums.dart';
import 'exercise.dart';
import 'goal.dart';
import 'habit.dart';
import 'system_log.dart';
import 'workout.dart';

/// Абстрактний обліковий запис — спільна основа для всіх ролей.
abstract class Account {
  Account({
    required this.id,
    required this.email,
    required this.name,
    DateTime? createdAt,
    this.status = AccountStatus.active,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String email;
  String name;
  final DateTime createdAt;
  AccountStatus status;

  /// Назва ролі для відображення.
  String get roleName;

  bool isActive() => status == AccountStatus.active;

  String getDisplayName() => name.trim().isEmpty ? email : name;
}

/// Користувач застосунку. Через композицію володіє цілями, звичками,
/// тренуваннями та щоденником активності.
class User extends Account {
  User({
    required super.id,
    required super.email,
    required super.name,
    super.createdAt,
    super.status,
    this.birthDate,
    this.heightCm = 0,
    this.weightKg = 0,
    List<Goal>? goals,
    List<Habit>? habits,
    List<Workout>? workouts,
    ActivityLog? activityLog,
  })  : goals = goals ?? <Goal>[],
        habits = habits ?? <Habit>[],
        workouts = workouts ?? <Workout>[],
        activityLog = activityLog ?? ActivityLog(id: 'log_$id');

  DateTime? birthDate;
  double heightCm;
  double weightKg;

  final List<Goal> goals;
  final List<Habit> habits;
  final List<Workout> workouts;
  final ActivityLog activityLog;

  @override
  String get roleName => 'Користувач';

  int? get age {
    final b = birthDate;
    if (b == null) return null;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) years--;
    return years;
  }

  void register() {
    status = AccountStatus.active;
    SystemLog.instance.add('Зареєстровано користувача $email');
  }

  void updateProfile(String name, double weightKg) {
    this.name = name;
    this.weightKg = weightKg;
  }

  /// Додає тренування до розкладу (сценарій «Спланувати тренування»).
  void planWorkout(Workout workout) {
    workouts.add(workout);
    workouts.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': 'user',
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'birthDate': birthDate?.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
      };

  factory User.fromMap(String id, Map<String, dynamic> m) => User(
        id: id,
        email: (m['email'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        status: enumFromName(AccountStatus.values, m['status'] as String?, AccountStatus.active),
        createdAt: DateTime.tryParse((m['createdAt'] ?? '') as String),
        birthDate: m['birthDate'] == null ? null : DateTime.tryParse(m['birthDate'] as String),
        heightCm: ((m['heightCm'] ?? 0) as num).toDouble(),
        weightKg: ((m['weightKg'] ?? 0) as num).toDouble(),
      );
}

/// Адміністратор: керує обліковими записами та переглядає журнал подій.
class Administrator extends Account {
  Administrator({required super.id, required super.email, required super.name, super.createdAt, super.status});

  @override
  String get roleName => 'Адміністратор';

  void blockAccount(Account account) {
    account.status = AccountStatus.blocked;
    SystemLog.instance.add('$email заблокував акаунт ${account.email}');
  }

  void unblockAccount(Account account) {
    account.status = AccountStatus.active;
    SystemLog.instance.add('$email розблокував акаунт ${account.email}');
  }

  List<String> viewSystemLogs() => SystemLog.instance.entries;
}

/// Контент-менеджер: наповнює каталог вправ (залежність «use» від ExerciseCatalog).
class ContentManager extends Account {
  ContentManager({required super.id, required super.email, required super.name, super.createdAt, super.status, this.catalog});

  ExerciseCatalog? catalog;

  @override
  String get roleName => 'Контент-менеджер';

  ExerciseCatalog get _catalog {
    final c = catalog;
    if (c == null) throw StateError('Каталог вправ не підключено');
    return c;
  }

  void addExercise(Exercise exercise) {
    _catalog.addExercise(exercise);
    SystemLog.instance.add('$email додав вправу «${exercise.name}»');
  }

  void editExercise(Exercise exercise) {
    _catalog.removeExercise(exercise.id);
    _catalog.addExercise(exercise);
    SystemLog.instance.add('$email змінив вправу «${exercise.name}»');
  }

  void deleteExercise(String id) {
    _catalog.removeExercise(id);
    SystemLog.instance.add('$email видалив вправу $id');
  }

  void updateMaterials() {
    SystemLog.instance.add('$email оновив інформаційні матеріали');
  }
}
