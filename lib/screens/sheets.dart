import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: child,
    ),
  );
}

Widget _sheetTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(text, style: AppText.display(20))),
        ],
      ),
    );

// ---------------------------------------------------------------------------
// «Отримати нагадування» — вхідні сповіщення
// ---------------------------------------------------------------------------

Future<void> showInboxSheet(BuildContext context) {
  final ns = context.read<AppState>().notifications;
  return _sheet<void>(
    context,
    AnimatedBuilder(
      animation: ns,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sheetTitle('Сповіщення'),
            Text('Заплановано нагадувань: ${ns.scheduledCount}', style: AppText.body(13, color: AppColors.muted)),
            const SizedBox(height: 12),
            if (ns.inbox.isEmpty)
              const EmptyHint(text: 'Нових сповіщень немає. Нагадування з’являться тут перед тренуванням.', icon: Icons.notifications_none)
            else
              for (final m in ns.inbox.take(10)) ...<Widget>[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  radius: 16,
                  child: Row(children: <Widget>[
                    const TintIcon(icon: Icons.alarm, color: AppColors.lime, size: 36),
                    const SizedBox(width: 12),
                    Expanded(child: Text(m, style: AppText.body(14))),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// «Записати активність у щоденник»
// ---------------------------------------------------------------------------

Future<void> showAddEntrySheet(BuildContext context) => _sheet<void>(context, const _AddEntrySheet());

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _type = TextEditingController(text: 'Прогулянка');
  final _minutes = TextEditingController(text: '30');
  final _calories = TextEditingController(text: '150');
  final _steps = TextEditingController(text: '3000');
  final _notes = TextEditingController();
  Workout? _workout;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in <TextEditingController>[_type, _minutes, _calories, _steps, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _number(String? v) => (int.tryParse(v ?? '') == null) ? 'Введіть число' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await context.read<AppState>().addEntry(
          type: _type.text.trim(),
          durationMin: int.parse(_minutes.text),
          calories: int.parse(_calories.text),
          steps: int.parse(_steps.text),
          notes: _notes.text.trim(),
          workout: _workout,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, _workout == null ? 'Запис збережено' : 'Запис збережено, тренування позначено виконаним');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user!;
    final open = user.workouts
        .where((w) => w.status != WorkoutStatus.completed && w.status != WorkoutStatus.skipped)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sheetTitle('Новий запис у щоденник'),
            TextFormField(
              controller: _type,
              decoration: const InputDecoration(labelText: 'Вид активності'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Вкажіть вид активності' : null,
            ),
            const SizedBox(height: 12),
            Row(children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Хвилини'),
                  validator: _number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ккал'),
                  validator: _number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _steps,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Кроки'),
                  validator: _number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<Workout?>(
              value: _workout,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(labelText: 'Пов’язане тренування (необов’язково)'),
              items: <DropdownMenuItem<Workout?>>[
                const DropdownMenuItem<Workout?>(value: null, child: Text('Без тренування')),
                for (final w in open)
                  DropdownMenuItem<Workout?>(value: w, child: Text('${w.title} · ${w.scheduledAt.day}.${twoDigits(w.scheduledAt.month)}')),
              ],
              onChanged: (w) => setState(() => _workout = w),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Нотатки')),
            const SizedBox(height: 20),
            AppButton(label: 'Зберегти запис', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// «Спланувати тренування» (з вибором вправ і нагадуванням)
// ---------------------------------------------------------------------------

Future<void> showPlanWorkoutSheet(BuildContext context, {DateTime? day, Exercise? preselected}) =>
    _sheet<void>(context, _PlanWorkoutSheet(day: day ?? DateTime.now(), preselected: preselected));

class _PlanWorkoutSheet extends StatefulWidget {
  const _PlanWorkoutSheet({required this.day, this.preselected});

  final DateTime day;
  final Exercise? preselected;

  @override
  State<_PlanWorkoutSheet> createState() => _PlanWorkoutSheetState();
}

class _PlanWorkoutSheetState extends State<_PlanWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Нове тренування');
  late DateTime _date = DateTime(widget.day.year, widget.day.month, widget.day.day);
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 30);
  int _duration = 45;
  bool _reminder = true;
  int _minutesBefore = 30;
  final Set<String> _selected = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preselected;
    if (p != null) {
      _selected.add(p.id);
      _title.text = p.name;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : _date,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null && mounted) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      showMessage(context, 'Оберіть хоча б одну вправу');
      return;
    }
    setState(() => _busy = true);
    final at = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final state = context.read<AppState>();
    await state.planWorkout(
      title: _title.text.trim(),
      scheduledAt: at,
      durationMin: _duration,
      items: <PlannedExercise>[for (final id in _selected) PlannedExercise(exerciseId: id)],
      reminderEnabled: _reminder,
      minutesBefore: _minutesBefore,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, _reminder ? 'Тренування заплановано, нагадування увімкнено' : 'Тренування заплановано');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<AppState>().catalog;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sheetTitle('Спланувати тренування'),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Назва'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Вкажіть назву' : null,
            ),
            const SizedBox(height: 12),
            Row(children: <Widget>[
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  text: '${_date.day} ${ukMonthsGen[_date.month - 1]}',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.schedule,
                  text: '${twoDigits(_time.hour)}:${twoDigits(_time.minute)}',
                  onTap: _pickTime,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Text('Тривалість: $_duration хв', style: AppText.body(14, color: AppColors.soft)),
            Slider(
              value: _duration.toDouble(),
              min: 10,
              max: 120,
              divisions: 22,
              activeColor: AppColors.lime,
              label: '$_duration хв',
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            const SizedBox(height: 8),
            Text('Вправи (${_selected.length})', style: AppText.body(15, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final e in catalog.all)
                  AppChip(
                    label: e.name,
                    selected: _selected.contains(e.id),
                    onTap: () => setState(() {
                      if (!_selected.remove(e.id)) _selected.add(e.id);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              radius: 16,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _reminder,
                    activeColor: AppColors.lime,
                    title: Text('Нагадування', style: AppText.body(15, weight: FontWeight.w600)),
                    subtitle: Text('Push-сповіщення перед тренуванням', style: AppText.body(12, color: AppColors.muted)),
                    onChanged: (v) => setState(() => _reminder = v),
                  ),
                  if (_reminder)
                    Row(
                      children: <Widget>[
                        Text('За', style: AppText.body(14, color: AppColors.soft)),
                        const SizedBox(width: 12),
                        for (final m in <int>[15, 30, 60]) ...<Widget>[
                          AppChip(label: '$m хв', selected: _minutesBefore == m, onTap: () => setState(() => _minutesBefore = m)),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  if (_reminder) const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Зберегти тренування', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(children: <Widget>[
            Icon(icon, color: AppColors.muted, size: 20),
            const SizedBox(width: 10),
            Text(text, style: AppText.body(15)),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// «Переглянути опис вправи»
// ---------------------------------------------------------------------------

Color categoryColor(ExerciseCategory c) {
  switch (c) {
    case ExerciseCategory.strength:
      return AppColors.orange;
    case ExerciseCategory.cardio:
      return AppColors.blue;
    case ExerciseCategory.core:
      return AppColors.lime;
    case ExerciseCategory.legs:
      return AppColors.purple;
    case ExerciseCategory.flexibility:
      return AppColors.soft;
  }
}

IconData categoryIcon(ExerciseCategory c) {
  switch (c) {
    case ExerciseCategory.strength:
      return Icons.fitness_center;
    case ExerciseCategory.cardio:
      return Icons.monitor_heart_outlined;
    case ExerciseCategory.core:
      return Icons.accessibility_new;
    case ExerciseCategory.legs:
      return Icons.directions_run;
    case ExerciseCategory.flexibility:
      return Icons.self_improvement;
  }
}

Future<void> showExerciseSheet(BuildContext context, Exercise e, {bool canPlan = true}) {
  final color = categoryColor(e.category);
  return _sheet<void>(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(20)),
            child: Icon(categoryIcon(e.category), color: color, size: 56),
          ),
          const SizedBox(height: 16),
          Text(e.name, style: AppText.display(22)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: <Widget>[
            _Tag(e.category.label, color),
            _Tag(e.difficulty.label, AppColors.soft),
            _Tag(e.muscleGroup, AppColors.soft),
          ]),
          const SizedBox(height: 14),
          Text(e.getDescription(), style: AppText.body(15, color: AppColors.soft)),
          if (canPlan) ...<Widget>[
            const SizedBox(height: 20),
            Builder(
              builder: (ctx) => AppButton(
                label: 'Додати в тренування',
                icon: Icons.add,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showPlanWorkoutSheet(context, preselected: e);
                },
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.tint(color, 30), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: AppText.body(12, color: color, weight: FontWeight.w600)),
    );
  }
}
