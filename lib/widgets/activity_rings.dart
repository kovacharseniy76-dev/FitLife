import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RingData {
  const RingData(this.progress, this.color);
  final double progress;
  final Color color;
}

/// Концентричні кільця активності (кроки, калорії, хвилини) з головного екрана.
class ActivityRings extends StatelessWidget {
  const ActivityRings({super.key, required this.rings, this.size = 116, this.stroke = 10, this.center});

  final List<RingData> rings;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingsPainter(rings, stroke),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.stroke);

  final List<RingData> rings;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    var radius = size.shortestSide / 2 - stroke / 2;
    for (final r in rings) {
      final track = Paint()
        ..color = AppColors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(c, radius, track);
      final p = r.progress.clamp(0.0, 1.0).toDouble();
      if (p > 0) {
        final arc = Paint()
          ..color = r.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCircle(center: c, radius: radius), -math.pi / 2, 2 * math.pi * p, false, arc);
      }
      radius -= stroke * 1.4;
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.rings != rings || old.stroke != stroke;
}
