/// Простий журнал подій системи (для Administrator.viewSystemLogs()).
class SystemLog {
  SystemLog._();
  static final SystemLog instance = SystemLog._();

  final List<String> _entries = <String>[];

  List<String> get entries => List<String>.unmodifiable(_entries);

  void add(String message) {
    final t = DateTime.now();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    _entries.add('[$hh:$mm] $message');
  }
}
