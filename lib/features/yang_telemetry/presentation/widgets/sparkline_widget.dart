import 'package:flutter/material.dart';

class SparklineWidget extends StatelessWidget {
  final List<BigInt> history;
  final Color color;

  const SparklineWidget({
    super.key,
    required this.history,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 30,
      child: CustomPaint(
        painter: _SparklinePainter(history, color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<BigInt> history;
  final Color color;

  _SparklinePainter(this.history, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Find min and max values to normalize
    BigInt minVal = history.reduce((a, b) => a < b ? a : b);
    BigInt maxVal = history.reduce((a, b) => a > b ? a : b);
    
    // Prevent division by zero if all values are equal
    double range = (maxVal - minVal).toDouble();
    if (range == 0.0) range = 1.0;

    final dx = size.width / (history.length - 1);
    
    for (int i = 0; i < history.length; i++) {
      final double x = i * dx;
      final double normalizedY = (history[i] - minVal).toDouble() / range;
      final double y = size.height - (normalizedY * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.history != history || oldDelegate.color != color;
}
