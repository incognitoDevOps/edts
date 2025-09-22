import 'package:flutter/material.dart';
import 'package:customer/themes/app_colors.dart';
import 'dart:math' as math;

/// A custom BuzRyde/RIDY loader widget with animated logo and teal accent.
class BuzRydeLoader extends StatefulWidget {
  final double size;
  const BuzRydeLoader({Key? key, this.size = 64}) : super(key: key);

  @override
  State<BuzRydeLoader> createState() => _BuzRydeLoaderState();
}

class _BuzRydeLoaderState extends State<BuzRydeLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer teal border (rotates)
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 6,
                      ),
                    ),
                  ),
                  // Rotating arc (incomplete circle)
                  CustomPaint(
                    size: Size(widget.size - 10, widget.size - 10),
                    painter: _ArcPainter(),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/loader.png',
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(0, 0) & size;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Draw an arc (not a full circle)
    canvas.drawArc(
      rect,
      -math.pi / 4, // start angle
      1.5 * math.pi, // sweep angle (270 degrees)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
