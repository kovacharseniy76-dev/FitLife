import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'catalog_screen.dart';

/// Робоче місце контент-менеджера: «Керувати каталогом вправ».
class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  Future<void> _addDialog(BuildContext context) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final muscles = TextEditingController();
    var category = ExerciseCategory.strength;
    var difficulty = Difficulty.beginner;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Нова вправа', style: AppText.body(18, weight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Назва')),
              const SizedBox(height: 10),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Опис'), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: muscles, decoration: const InputDecoration(labelText: 'Група м’язів')),
              const SizedBox(height: 10),
              DropdownButtonFormField<ExerciseCategory>(
                value: category,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Категорія'),
                items: <DropdownMenuItem<ExerciseCategory>>[
                  for (final c in ExerciseCategory.values) DropdownMenuItem<ExerciseCategory>(value: c, child: Text(c.label)),
                ],
                onChanged: (v) => setLocal(() => category = v ?? category),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<Difficulty>(
                value: difficulty,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Складність'),
                items: <DropdownMenuItem<Difficulty>>[
                  for (final d in Difficulty.values) DropdownMenuItem<Difficulty>(value: d, child: Text(d.label)),
                ],
                onChanged: (v) => setLocal(() => difficulty = v ?? difficulty),
              ),
            ]),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Скасувати')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.bg),
              onPressed: () => Navigator.of(ctx).pop(name.text.trim().isNotEmpty),
              child: const Text('Додати'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().addExercise(Exercise(
            id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
            name: name.text.trim(),
            description: description.text.trim(),
            category: category,
            muscleGroup: muscles.text.trim(),
            difficulty: difficulty,
          ));
      if (context.mounted) showMessage(context, 'Вправу додано до каталогу');
    }
  }

  Future<void> _manage(BuildContext context, Exercise e) async {
    final del = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(e.name, style: AppText.body(18, weight: FontWeight.w700)),
        content: Text(e.getDescription(), style: AppText.body(14, color: AppColors.soft)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Закрити')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Видалити', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (del == true && context.mounted) {
      await context.read<AppState>().deleteExercise(e.id);
      if (context.mounted) showMessage(context, 'Вправу «${e.name}» видалено');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cm = state.account! as ContentManager;
    final items = state.catalog.all;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.bg,
        onPressed: () => _addDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Вправа'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: Text('Каталог вправ', style: AppText.display(22))),
              SquareIconButton(icon: Icons.logout, tooltip: 'Вийти', onPressed: () => state.signOut()),
            ]),
            const SizedBox(height: 6),
            Text('${cm.getDisplayName()} · вправ у каталозі: ${items.length}', style: AppText.body(14, color: AppColors.muted)),
            const SizedBox(height: 12),
            AppButton(
              label: 'Оновити інформаційні матеріали',
              primary: false,
              icon: Icons.sync,
              onPressed: () {
                cm.updateMaterials();
                showMessage(context, 'Матеріали оновлено');
              },
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 150,
              ),
              itemBuilder: (context, i) => ExerciseCard(exercise: items[i], onTap: () => _manage(context, items[i])),
            ),
            const SizedBox(height: 8),
            Text('Натисніть на вправу, щоб переглянути опис або видалити її.',
                style: AppText.body(12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
