/// Корисна звичка (вода, сон, розтяжка) з денною ціллю та серією днів.
class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.dailyTarget,
    this.currentValue = 0,
    this.streakDays = 0,
    this.unit = '',
  });

  final String id;
  String name;
  int dailyTarget;
  int currentValue;
  int streakDays;

  /// Одиниця для відображення («склянок», «год»).
  String unit;

  bool get isDoneToday => currentValue >= dailyTarget;

  /// Фіксує ще одне виконання. Коли денну ціль досягнуто вперше — серія росте.
  void markDone() {
    if (isDoneToday) return;
    currentValue++;
    if (isDoneToday) streakDays++;
  }

  /// Скидає лічильник на початку нового дня; якщо ціль учора не виконано — серія обнуляється.
  void resetDay() {
    if (!isDoneToday) streakDays = 0;
    currentValue = 0;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'dailyTarget': dailyTarget,
        'currentValue': currentValue,
        'streakDays': streakDays,
        'unit': unit,
      };

  factory Habit.fromMap(String id, Map<String, dynamic> m) => Habit(
        id: id,
        name: (m['name'] ?? '') as String,
        dailyTarget: ((m['dailyTarget'] ?? 1) as num).toInt(),
        currentValue: ((m['currentValue'] ?? 0) as num).toInt(),
        streakDays: ((m['streakDays'] ?? 0) as num).toInt(),
        unit: (m['unit'] ?? '') as String,
      );
}
