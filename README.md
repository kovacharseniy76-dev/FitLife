# FitLife — персональний планувальник фізичної активності

Мобільний застосунок на Flutter, реалізований за проєктною документацією
(опис проєкту, концептуальна модель, діаграми варіантів використання, класів,
кооперації та послідовності, дизайн у Figma). Повне технічне завдання — у `docs/TZ.md`.

## Швидкий старт (демо-режим, без Firebase)

Потрібен встановлений Flutter SDK 3.22 або новіший.

```bash
cd fitlife_app
flutter create . --project-name fitlife --platforms=android,ios,web   # створює папки платформ (код у lib/ не змінюється)
del test\widget_test.dart   # Windows (macOS/Linux: rm test/widget_test.dart) — шаблонний тест від flutter create
flutter pub get
flutter run -d chrome          # або flutter run на емуляторі / телефоні
flutter test                   # модульні тести бізнес-логіки
```

Тестові акаунти демо-режиму:

| Email | Пароль | Роль |
|---|---|---|
| demo@fitlife.app | demo123 | Користувач (з тестовими даними) |
| admin@fitlife.app | admin123 | Адміністратор |
| content@fitlife.app | content123 | Контент-менеджер |
| blocked@fitlife.app | blocked123 | Заблокований акаунт (гілка «акаунт заблоковано») |

## Підключення Firebase

1. Створіть проєкт у Firebase Console, увімкніть **Authentication → Email/Password** і **Cloud Firestore**.
2. Додайте застосунок Android (`google-services.json` → `android/app/`) та/або iOS (`GoogleService-Info.plist` → `ios/Runner/`).
3. Запустіть: `flutter run --dart-define=USE_FIREBASE=true`.
4. Каталог вправ заповниться автоматично під час першого запуску. Щоб створити адміністратора,
   змініть у документі `users/{uid}` поле `role` на `admin` (або `content` для контент-менеджера).
5. Нагадування записуються в колекцію `scheduledNotifications`; для фактичного надсилання push
   потрібна Cloud Function, яка в момент `sendAt` надсилає FCM-повідомлення на `fcmToken` користувача.

## Структура

```
lib/
  main.dart, app.dart, config.dart   — запуск, вибір бекенда, маршрутизація за роллю
  models/       — класи з діаграми класів (Account, User, Workout, Exercise, ActivityLog, Statistics, …)
  services/     — AuthService, NotificationService, інтерфейс бекенда
    demo/       — DemoBackend і тестові дані
    firebase/   — FirebaseBackend (Authentication, Firestore, FCM)
  state/        — AppState: сценарії з діаграм послідовності
  screens/      — 7 екранів з Figma + екрани адміністратора й контент-менеджера
  widgets/      — нижня навігація, кільця активності, картки, кнопки
  theme/        — кольори та шрифти з Figma
test/           — модульні тести
docs/TZ.md      — комплексне технічне завдання
```

## Відповідність проєктній документації

| Документ | Де в коді |
|---|---|
| Діаграма класів | `lib/models/*` — ті самі назви класів, полів і методів |
| Use case: ролі | `app.dart` (`_RootGate`): Користувач → 5 вкладок, Адміністратор → `AdminScreen`, Контент-менеджер → `ContentScreen` |
| Сценарій «Увійти в систему» | `AuthService.signIn` (verifyCredentials → loadAccount → isActive) |
| Сценарій «Спланувати тренування» | `AppState.planWorkout` (create Workout → loop getById/addExercise → opt Reminder.schedule → scheduleNotification) |
| Сценарій «Записати активність і статистика» | `AppState.addEntry`, `ActivityLog.addEntry` (→ Workout.complete), `ActivityLog.buildStatistics` → `Statistics.calculate` / `getStreak` |
| Дизайн Figma | `theme/app_theme.dart` (кольори, Unbounded/Inter), `screens/*` |
