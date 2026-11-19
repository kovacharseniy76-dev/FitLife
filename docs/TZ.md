# Комплексне завдання для ШІ: реалізація мобільного застосунку FitLife

## Роль і мета
Ти — досвідчений Flutter-розробник. Реалізуй мобільний застосунок **FitLife** — персональний планувальник фізичної активності — за проєктною документацією нижче. Код має відповідати діаграмам (класів, варіантів використання, кооперації, послідовності) і дизайну.

## 1. Опис проєкту
FitLife допомагає організовувати тренування, відстежувати фізичну активність і формувати корисні звички. Користувач планує тренування, веде щоденник активності, переглядає статистику та отримує нагадування. Цільова аудиторія: студенти та молодь, початківці, люди, які регулярно тренуються, і ті, хто хоче виробити звичку рухатися. Інтерфейс — українською мовою, мінімалістичний.

## 2. Стек
- Flutter (Android, iOS, Web), мова Dart.
- Firebase Authentication — реєстрація та вхід.
- Cloud Firestore — зберігання даних.
- Firebase Cloud Messaging — сповіщення.
- Керування станом — provider (ChangeNotifier).

## 3. Ролі та функції (діаграма варіантів використання)
- **Користувач:** зареєструватися, увійти, відновити пароль, редагувати профіль, спланувати тренування (з вибором вправ і нагадуванням), переглянути каталог і опис вправ, записати активність у щоденник, відмітити виконання звички, переглянути статистику, отримати нагадування.
- **Адміністратор:** керувати обліковими записами (блокувати / розблоковувати), переглядати журнал подій.
- **Контент-менеджер:** керувати каталогом вправ, оновлювати інформаційні матеріали.
- Усі ролі входять через спільний механізм авторизації (абстрактний актор «Авторизований користувач»).
- Зовнішні системи: Firebase Authentication, Сервіс сповіщень (FCM).

## 4. Модель даних (діаграма класів)
- **Account** (абстрактний): id, email, name, createdAt, status: AccountStatus; isActive(), getDisplayName().
- **User** extends Account: birthDate, heightCm, weightKg; register(), updateProfile(name, weightKg), planWorkout(workout).
- **Administrator** extends Account: blockAccount(account), unblockAccount(account), viewSystemLogs().
- **ContentManager** extends Account: addExercise, editExercise, deleteExercise, updateMaterials.
- **AuthService:** currentUserId; signUp, signIn, signOut, sendPasswordReset.
- **Goal:** id, title, targetValue, currentValue, deadline; getProgress(), isAchieved().
- **Habit:** id, name, dailyTarget, currentValue, streakDays; markDone(), resetDay().
- **Workout:** id, title, scheduledAt, durationMin, status: WorkoutStatus; addExercise(item), start(), complete(), reschedule(date).
- **WorkoutExercise:** order, sets, reps, weightKg; посилається на 1 Exercise.
- **Exercise:** id, name, description, category: ExerciseCategory, muscleGroup, difficulty: Difficulty; getDescription().
- **ExerciseCatalog:** search(query), filterByCategory(c), getById(id), addExercise, removeExercise.
- **ActivityLog:** id; addEntry(entry), getEntries(from, to), buildStatistics(period).
- **ActivityEntry:** id, date, type, durationMin, calories, steps, notes; 0..1 зв'язок із Workout.
- **Statistics:** period: StatsPeriod, totalMinutes, totalCalories, workoutsCount, averageSteps; calculate(entries), getStreak().
- **Reminder:** id, remindAt, minutesBefore, enabled; schedule(), cancel().
- **NotificationService:** sendPush, scheduleNotification(reminder), cancelNotification(id).
- Переліки: AccountStatus (Active, Blocked), WorkoutStatus (Planned, InProgress, Completed, Skipped), ExerciseCategory (Strength, Cardio, Core, Legs, Flexibility), Difficulty (Beginner, Intermediate, Advanced), StatsPeriod (Week, Month, Year).
- Композиція: User володіє Goal, Habit, Workout, ActivityLog; Workout — WorkoutExercise і Reminder; ActivityLog — ActivityEntry. Агрегація: ExerciseCatalog — Exercise.

## 5. Логіка ключових сценаріїв (діаграми кооперації та послідовності)
1. **Вхід:** signIn(email, password) → перевірка облікових даних у Firebase Authentication → завантаження акаунта з Firestore → isActive(). Якщо акаунт заблоковано — повідомлення «акаунт заблоковано», інакше — привітання на ім'я.
2. **Планування тренування:** planWorkout → створення Workout → для кожної вправи: getById у каталозі та addExercise (створює WorkoutExercise) → якщо нагадування увімкнено: Reminder.schedule() → NotificationService.scheduleNotification(reminder).
3. **Щоденник і статистика:** addEntry → створення ActivityEntry → якщо запис пов'язаний із тренуванням — Workout.complete(). buildStatistics(period) → створення Statistics → calculate(entries) → getStreak().

## 6. Дизайн (Figma)
- 7 екранів: Вітальний, Авторизація (вхід / реєстрація), Головна, Планувальник, Каталог вправ, Статистика, Профіль. Нижня навігація з 5 вкладками: Головна, План, Вправи, Статистика, Профіль.
- Темна тема. Кольори: фон #0E1116, картки #171C23, межі #2A323C, текст #F2F5F7 / #9AA4AF, акценти: лайм #C8F25A (основний), помаранчевий #FF8A3D (калорії, сила), блакитний #5AB8FF (кроки, кардіо).
- Шрифти: Unbounded (заголовки), Inter (текст). Радіуси карток 18–24, кнопки висотою від 48.
- Головна: кільця активності (кроки, калорії, хвилини), картка тренування на сьогодні, звички. Планувальник: тижнева смуга днів, розклад, кнопка «+». Каталог: пошук і фільтр за категоріями. Статистика: перемикач тиждень / місяць / рік, стовпчиковий графік, показники. Профіль: дані, ціль із прогресом, меню, вихід.

## 7. Вимоги до реалізації
- Структура: lib/models, lib/services, lib/state, lib/screens, lib/widgets, lib/theme.
- Бекенд через інтерфейси: **демо-режим** (дані в пам'яті, запуск без налаштування Firebase) і **Firebase-режим** (Authentication, Firestore, FCM), перемикач через --dart-define=USE_FIREBASE=true.
- Модульні тести для бізнес-логіки моделей (прогрес цілі, статистика, серія днів).
- README з інструкцією запуску.

## 8. Критерії приймання
- Застосунок запускається командою flutter run у демо-режимі.
- Працюють усі 7 екранів і навігація між ними.
- Сценарії 1–3 виконуються так, як на діаграмах послідовності.
- Назви класів, полів і методів збігаються з діаграмою класів.
