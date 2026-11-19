import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'sheets.dart';

/// Екран 5 — Каталог вправ: пошук і фільтр за категоріями.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _query = TextEditingController();
  ExerciseCategory? _category;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<AppState>().catalog;
    final found = catalog.search(_query.text);
    final c = _category;
    final items = c == null ? found : found.where((e) => e.category == c).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: <Widget>[
        Text('Каталог вправ', style: AppText.display(24)),
        const SizedBox(height: 16),
        TextField(
          controller: _query,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Пошук: присідання, планка…',
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              AppChip(label: 'Усі', selected: c == null, onTap: () => setState(() => _category = null)),
              for (final cat in ExerciseCategory.values) ...<Widget>[
                const SizedBox(width: 8),
                AppChip(label: cat.label, selected: c == cat, onTap: () => setState(() => _category = cat)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty) const EmptyHint(text: 'Нічого не знайдено', icon: Icons.search_off),
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
          itemBuilder: (context, i) => ExerciseCard(exercise: items[i]),
        ),
      ],
    );
  }
}

/// Картка вправи (компонент Exercise Card у Figma).
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, this.onTap});

  final Exercise exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(exercise.category);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () => showExerciseSheet(context, exercise),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 66,
                width: double.infinity,
                decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(14)),
                child: Icon(categoryIcon(exercise.category), color: color, size: 30),
              ),
              const SizedBox(height: 10),
              Text(exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(14, weight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${exercise.muscleGroup} · ${exercise.difficulty.label}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(12, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
