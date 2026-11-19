/// Режим Firebase вмикається прапорцем:
///   flutter run --dart-define=USE_FIREBASE=true
/// Без прапорця застосунок працює в демо-режимі з тестовими даними.
const bool useFirebase = bool.fromEnvironment('USE_FIREBASE');
