import 'package:flutter/material.dart';

class BarPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final double barWidth;
  final double barHeight;
  final double radius;

  BarPainter({
    required this.progress,
    required this.glowIntensity,
    required this.barWidth,
    required this.barHeight,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = (size.width - barWidth) / 2;
    final dy = (size.height - barHeight) / 2;
    final trackRect =
        RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, barWidth, barHeight), Radius.circular(radius));
    final fillWidth = barWidth * progress.clamp(0.0, 1.0);

    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = const Color(0xFF1A1A3E)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    if (fillWidth > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, fillWidth, barHeight),
        Radius.circular(radius),
      );

      canvas.drawRRect(
        fillRect.inflate(4 * glowIntensity),
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25 * glowIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      final gradient = LinearGradient(
        colors: const [Color(0xFF00BCD4), Color(0xFF00E5FF), Color(0xFF76FF03)],
        stops: const [0.0, 0.6, 1.0],
      );
      canvas.drawRRect(
        fillRect,
        Paint()
          ..shader = gradient.createShader(
              Rect.fromLTWH(dx, dy, barWidth, barHeight))
          ..style = PaintingStyle.fill,
      );

      if (fillWidth > 3) {
        final edgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + fillWidth - 4, dy + 1, 4, barHeight - 2),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          edgeRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7 * glowIntensity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      final shineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + 2, dy + 1, fillWidth - 4, barHeight * 0.4),
        Radius.circular(radius),
      );
      canvas.drawRRect(
        shineRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(BarPainter old) =>
      progress != old.progress || glowIntensity != old.glowIntensity;
}
