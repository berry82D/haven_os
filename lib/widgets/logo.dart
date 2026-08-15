import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class HavenLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const HavenLogo({
    super.key,
    this.size = 80,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- Logo mark ----
        CustomPaint(
          size: Size(size, size),
          painter: _LogoPainter(size: size), // pass size as double
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'Haven OS',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink,
              fontFamily: 'serif',
              letterSpacing: 2,
            ),
          ),
          Text(
            'Family CFO · Farm Manager',
            style: TextStyle(
              fontSize: size * 0.13,
              color: AppTheme.ink.withValues(alpha: 0.6),
              fontFamily: 'serif',
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}

// ---- Custom painter – fixed to use double size ----
class _LogoPainter extends CustomPainter {
  final double size;

  _LogoPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.04;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final r = size * 0.35;

    // ---- Barn roof ----
    final roofPath = Path()
      ..moveTo(center.dx - r * 1.2, center.dy - r * 0.3)
      ..lineTo(center.dx, center.dy - r * 1.3)
      ..lineTo(center.dx + r * 1.2, center.dy - r * 0.3)
      ..close();
    canvas.drawPath(roofPath, paint);
    canvas.drawPath(roofPath, strokePaint);

    // ---- Barn body ----
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.2),
      width: r * 1.8,
      height: r * 1.2,
    );
    canvas.drawRect(bodyRect, paint);
    canvas.drawRect(bodyRect, strokePaint);

    // ---- Barn door ----
    final doorRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.25),
      width: r * 0.5,
      height: r * 0.7,
    );
    canvas.drawRect(doorRect, Paint()..color = Colors.brown.shade700);
    canvas.drawRect(doorRect, strokePaint);

    // ---- Coin / dollar ----
    final coinPaint = Paint()..color = Colors.amber.shade600;
    final coinRect = Rect.fromCircle(
      center: Offset(center.dx, center.dy + r * 0.15),
      radius: r * 0.15,
    );
    canvas.drawCircle(coinRect.center, coinRect.width / 2, coinPaint);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy + r * 0.07 - textPainter.height / 2),
    );

    // ---- Leaf ----
    final leafPaint = Paint()..color = Colors.green.shade600;
    canvas.drawOval(
      Rect.fromCircle(
          center: Offset(center.dx + r * 0.8, center.dy - r * 0.8),
          radius: r * 0.1),
      leafPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
