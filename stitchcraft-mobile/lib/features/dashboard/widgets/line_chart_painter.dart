import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class LineChartPainter extends CustomPainter {
  final List<double> incomePoints;
  final List<double> expensePoints;
  final Color incomeColor;
  final Color expenseColor;

  LineChartPainter({
    required this.incomePoints,
    required this.expensePoints,
    this.incomeColor = const Color(0xFF10B981), // Emerald green for collected income
    this.expenseColor = const Color(0xFFF43F5E), // Rose / Red for expenses
  });

  // Legacy single-series constructor compatibility
  LineChartPainter.singleSeries(
    List<double> dataPoints, {
    Color color = AppTheme.brandPurple,
  })  : incomePoints = dataPoints,
        expensePoints = List.filled(dataPoints.length, 0.0),
        incomeColor = color,
        expenseColor = AppTheme.alertRed;

  @override
  void paint(Canvas canvas, Size size) {
    if (incomePoints.isEmpty && expensePoints.isEmpty) return;

    final int pointCount = math.max(
      incomePoints.length,
      expensePoints.length,
    );
    if (pointCount < 2) return;

    // Determine max value across both series for shared scale
    double maxIncome = 0.0;
    for (final v in incomePoints) {
      if (v > maxIncome) maxIncome = v;
    }
    double maxExpense = 0.0;
    for (final v in expensePoints) {
      if (v > maxExpense) maxExpense = v;
    }
    final double maxVal = math.max(maxIncome, maxExpense);

    const double topPadding = 18.0;
    const double bottomPadding = 12.0;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final double widthBetweenPoints = size.width / (pointCount - 1);
    final double scaleY = maxVal > 0 ? chartHeight / maxVal : 1.0;
    final double baselineY = size.height - bottomPadding;

    // Draw faint horizontal grid reference lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, topPadding), Offset(size.width, topPadding), gridPaint);
    canvas.drawLine(
      Offset(0, topPadding + chartHeight / 2),
      Offset(size.width, topPadding + chartHeight / 2),
      gridPaint,
    );
    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), gridPaint);

    // If both series are completely zero, draw a subtle clean baseline
    if (maxVal <= 0) {
      final zeroPaint = Paint()
        ..color = AppTheme.darkGrey.withValues(alpha: 0.25)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), zeroPaint);
      return;
    }

    // Draw Expenses Area first (so Income renders cleanly over it)
    if (expensePoints.isNotEmpty) {
      _drawSeries(
        canvas: canvas,
        size: size,
        points: expensePoints,
        pointCount: pointCount,
        color: expenseColor,
        scaleY: scaleY,
        topPadding: topPadding,
        bottomPadding: bottomPadding,
        baselineY: baselineY,
        widthBetweenPoints: widthBetweenPoints,
        alphaMultiplier: 0.35,
      );
    }

    // Draw Income Area
    if (incomePoints.isNotEmpty) {
      _drawSeries(
        canvas: canvas,
        size: size,
        points: incomePoints,
        pointCount: pointCount,
        color: incomeColor,
        scaleY: scaleY,
        topPadding: topPadding,
        bottomPadding: bottomPadding,
        baselineY: baselineY,
        widthBetweenPoints: widthBetweenPoints,
        alphaMultiplier: 0.40,
      );
    }
  }

  void _drawSeries({
    required Canvas canvas,
    required Size size,
    required List<double> points,
    required int pointCount,
    required Color color,
    required double scaleY,
    required double topPadding,
    required double bottomPadding,
    required double baselineY,
    required double widthBetweenPoints,
    required double alphaMultiplier,
  }) {
    final strokePath = Path();
    final fillPath = Path();

    fillPath.moveTo(0, baselineY);

    for (int i = 0; i < pointCount; i++) {
      final double val = i < points.length ? points[i] : 0.0;
      final double x = i * widthBetweenPoints;
      final double y = baselineY - (val * scaleY);

      if (i == 0) {
        strokePath.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        final double prevVal = (i - 1) < points.length ? points[i - 1] : 0.0;
        final double prevX = (i - 1) * widthBetweenPoints;
        final double prevY = baselineY - (prevVal * scaleY);

        final double cx1 = prevX + widthBetweenPoints / 2;
        final double cy1 = prevY;
        final double cx2 = prevX + widthBetweenPoints / 2;
        final double cy2 = y;

        strokePath.cubicTo(cx1, cy1, cx2, cy2, x, y);
        fillPath.cubicTo(cx1, cy1, cx2, cy2, x, y);
      }
    }

    fillPath.lineTo(size.width, baselineY);
    fillPath.close();

    // 1. Draw gradient area fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: alphaMultiplier),
        color.withValues(alpha: 0.02),
      ],
    );
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(Rect.fromLTWH(0, topPadding, size.width, size.height - topPadding));

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw stroke line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, linePaint);

    // 3. Draw dots on points
    final dotPaint = Paint()..color = color;
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final dotBackgroundPaint = Paint()
      ..color = const Color(0xFF121926)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pointCount; i++) {
      final double val = i < points.length ? points[i] : 0.0;
      if (val > 0) {
        final double x = i * widthBetweenPoints;
        final double y = baselineY - (val * scaleY);

        canvas.drawCircle(Offset(x, y), 5.0, dotBackgroundPaint);
        canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
        canvas.drawCircle(Offset(x, y), 4.5, dotOuterPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    if (oldDelegate.incomePoints.length != incomePoints.length ||
        oldDelegate.expensePoints.length != expensePoints.length) {
      return true;
    }
    for (int i = 0; i < incomePoints.length; i++) {
      if (oldDelegate.incomePoints[i] != incomePoints[i]) return true;
    }
    for (int i = 0; i < expensePoints.length; i++) {
      if (oldDelegate.expensePoints[i] != expensePoints[i]) return true;
    }
    return false;
  }
}
