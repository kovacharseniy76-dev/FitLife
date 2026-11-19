import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Картка з фоном Surface і заокругленням, як у макетах.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 22, this.color, this.border});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: child,
    );
  }
}

/// Основна кнопка (лайм) або другорядна (з обведенням).
class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.primary = true, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.bg : AppColors.text;
    final content = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: AppText.body(16, color: fg, weight: FontWeight.w700)),
              if (icon != null) ...<Widget>[const SizedBox(width: 8), Icon(icon, color: fg, size: 20)],
            ],
          );
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: primary
          ? FilledButton(
              onPressed: loading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                disabledBackgroundColor: AppColors.tint(AppColors.lime, 140),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: content,
            ),
    );
  }
}

/// Квадратна іконка-кнопка 44×44 (сповіщення, стрілки, редагування).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.badge = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(icon, color: AppColors.text, size: 21),
                if (badge)
                  const Positioned(
                    top: 10,
                    right: 11,
                    child: CircleAvatar(radius: 4, backgroundColor: AppColors.orange),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Іконка в кольоровому квадраті (звички, вправи).
class TintIcon extends StatelessWidget {
  const TintIcon({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Чип-фільтр (категорії вправ, вибір вправ у плані).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lime : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: selected ? BorderSide.none : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(label,
              style: AppText.body(14, color: selected ? AppColors.bg : AppColors.soft, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Сегментований перемикач (Вхід / Реєстрація, Тиждень / Місяць / Рік).
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.border : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(labels[i],
                      style: AppText.body(14,
                          color: i == index ? AppColors.text : AppColors.muted, weight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Заголовок секції з необов'язковою дією праворуч.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: AppText.body(17, weight: FontWeight.w700))),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: AppText.body(13, color: AppColors.lime, weight: FontWeight.w600)),
          ),
      ],
    );
  }
}

/// Порожній стан списку.
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.text, this.icon = Icons.inbox_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body(14, color: AppColors.muted))),
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String twoDigits(int n) => n.toString().padLeft(2, '0');
String hhmm(DateTime d) => '${twoDigits(d.hour)}:${twoDigits(d.minute)}';

/// Розділяє тисячі пробілом: 6842 → «6 842».
String groupDigits(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

const List<String> ukWeekdaysShort = <String>['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
const List<String> ukMonthsGen = <String>[
  'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
  'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
];
const List<String> ukMonths = <String>[
  'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
  'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень',
];
const List<String> ukWeekdaysFull = <String>["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця", "Субота", "Неділя"];
