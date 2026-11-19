import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Нижня навігація з 5 вкладками (компонент Bottom Nav у Figma).
class FitLifeBottomNav extends StatelessWidget {
  const FitLifeBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<(IconData, String)> items = <(IconData, String)>[
    (Icons.home_outlined, 'Головна'),
    (Icons.calendar_month_outlined, 'План'),
    (Icons.fitness_center, 'Вправи'),
    (Icons.bar_chart_rounded, 'Статистика'),
    (Icons.person_outline, 'Профіль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.nav,
        border: Border(top: BorderSide(color: AppColors.surface2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(items[i].$1, color: i == index ? AppColors.lime : AppColors.subtle, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$2,
                          style: AppText.body(11,
                              color: i == index ? AppColors.lime : AppColors.subtle,
                              weight: i == index ? FontWeight.w600 : FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
