import 'enums.dart';

/// Фізична вправа з каталогу.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.muscleGroup,
    required this.difficulty,
  });

  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final String muscleGroup;
  final Difficulty difficulty;

  String getDescription() =>
      '$name — $description\nГрупа м’язів: $muscleGroup. Рівень: ${difficulty.label}.';

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category.name,
        'muscleGroup': muscleGroup,
        'difficulty': difficulty.name,
      };

  factory Exercise.fromMap(String id, Map<String, dynamic> m) => Exercise(
        id: id,
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        category: enumFromName(ExerciseCategory.values, m['category'] as String?, ExerciseCategory.strength),
        muscleGroup: (m['muscleGroup'] ?? '') as String,
        difficulty: enumFromName(Difficulty.values, m['difficulty'] as String?, Difficulty.beginner),
      );
}

/// Каталог вправ. Агрегація: вправи існують незалежно від каталогу.
class ExerciseCatalog {
  ExerciseCatalog([List<Exercise>? exercises]) : _exercises = List<Exercise>.of(exercises ?? const <Exercise>[]);

  final List<Exercise> _exercises;

  List<Exercise> get all => List<Exercise>.unmodifiable(_exercises);

  List<Exercise> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return _exercises
        .where((e) => e.name.toLowerCase().contains(q) || e.muscleGroup.toLowerCase().contains(q))
        .toList();
  }

  List<Exercise> filterByCategory(ExerciseCategory c) => _exercises.where((e) => e.category == c).toList();

  Exercise? getById(String id) {
    for (final e in _exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  void addExercise(Exercise exercise) {
    _exercises.removeWhere((e) => e.id == exercise.id);
    _exercises.add(exercise);
  }

  void removeExercise(String id) => _exercises.removeWhere((e) => e.id == id);
}
