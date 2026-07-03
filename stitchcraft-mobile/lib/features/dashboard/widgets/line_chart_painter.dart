import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  LineChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()
      ..color = AppTheme.brandPurple
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    final double widthBetweenPoints = size.width / (dataPoints.length - 1);
    final double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final double scaleY = maxVal > 0 ? (size.height - 20) / maxVal : 1.0;

    final path = Path();
    final fillPath = Path();

    fillPath.moveTo(0, size.height);

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * widthBetweenPoints;
      final double y = size.height - (dataPoints[i] * scaleY);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        final double prevX = (i - 1) * widthBetweenPoints;
        final double prevY = size.height - (dataPoints[i - 1] * scaleY);
        path.cubicTo(
          prevX + widthBetweenPoints / 2,
          prevY,
          x - widthBetweenPoints / 2,
          y,
          x,
          y,
        );
        fillPath.cubicTo(
          prevX + widthBetweenPoints / 2,
          prevY,
          x - widthBetweenPoints / 2,
          y,
          x,
          y,
        );
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.brandPurple.withValues(alpha: 0.3),
        AppTheme.brandPurple.withValues(alpha: 0.0),
      ],
    );
    paintFill.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}
