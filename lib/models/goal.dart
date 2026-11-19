/// Ціль користувача (наприклад, «схуднути до 72 кг»).
class Goal {
  Goal({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.deadline,
    double? startValue,
  }) : startValue = startValue ?? currentValue;

  final String id;
  String title;
  double targetValue;
  double currentValue;
  DateTime deadline;

  /// Значення на момент постановки цілі — потрібне, щоб рахувати прогрес
  /// і для цілей «зменшити» (вага), і для цілей «збільшити» (кроки).
  final double startValue;

  /// Прогрес від 0.0 до 1.0.
  double getProgress() {
    final total = targetValue - startValue;
    if (total == 0) return 1.0;
    final done = (currentValue - startValue) / total;
    return done.clamp(0.0, 1.0).toDouble();
  }

  bool isAchieved() => getProgress() >= 1.0;

  Map<String, dynamic> toMap() => {
        'title': title,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'startValue': startValue,
        'deadline': deadline.toIso8601String(),
      };

  factory Goal.fromMap(String id, Map<String, dynamic> m) => Goal(
        id: id,
        title: (m['title'] ?? '') as String,
        targetValue: ((m['targetValue'] ?? 0) as num).toDouble(),
        currentValue: ((m['currentValue'] ?? 0) as num).toDouble(),
        startValue: ((m['startValue'] ?? m['currentValue'] ?? 0) as num).toDouble(),
        deadline: DateTime.tryParse((m['deadline'] ?? '') as String) ?? DateTime.now(),
      );
}
