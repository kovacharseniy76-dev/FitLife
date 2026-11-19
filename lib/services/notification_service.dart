import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'backend.dart';

/// Сервіс сповіщень (NotificationService з діаграми класів).
/// Зберігає заплановані нагадування, у визначений час кладе повідомлення
/// у «вхідні» застосунку, а в режимі Firebase передає їх у FCM через бекенд.
class NotificationService extends ChangeNotifier {
  NotificationService(this._backend) {
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _deliverDue());
  }

  final FitLifeBackend _backend;
  Timer? _timer;

  final Map<String, Reminder> _scheduled = <String, Reminder>{};
  final Map<String, String> _titles = <String, String>{};
  final Map<String, String> _owners = <String, String>{};
  final List<String> _inbox = <String>[];

  List<String> get inbox => List<String>.unmodifiable(_inbox);
  int get scheduledCount => _scheduled.length;

  Future<void> sendPush(String userId, String message) async {
    _inbox.insert(0, message);
    notifyListeners();
    await _backend.sendPush(userId, message);
  }

  /// 1.4.1 scheduleNotification(reminder) — викликається після Reminder.schedule().
  Future<void> scheduleNotification(Reminder reminder, {required String userId, required String workoutTitle}) async {
    _scheduled[reminder.id] = reminder;
    _titles[reminder.id] = workoutTitle;
    _owners[reminder.id] = userId;
    notifyListeners();
    await _backend.scheduleReminder(userId, reminder, workoutTitle);
  }

  Future<void> cancelNotification(String id) async {
    _scheduled.remove(id)?.cancel();
    _titles.remove(id);
    _owners.remove(id);
    notifyListeners();
    await _backend.cancelReminder(id);
  }

  void _deliverDue() {
    final now = DateTime.now();
    final due = _scheduled.values.where((r) => r.enabled && !r.remindAt.isAfter(now)).toList();
    for (final r in due) {
      final title = _titles[r.id] ?? 'тренування';
      final owner = _owners[r.id] ?? '';
      _scheduled.remove(r.id);
      sendPush(owner, 'Через ${r.minutesBefore} хв: «$title»');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
