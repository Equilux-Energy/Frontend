import 'package:flutter/material.dart';
import 'dart:math';

class GradientWaveBackground extends StatefulWidget {
  const GradientWaveBackground({super.key});

  @override
  State<GradientWaveBackground> createState() => _GradientWaveBackgroundState();
}

class _GradientWaveBackgroundState extends State<GradientWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Color> _colors = [
    const Color(0xFF1A0020), // Darkest purple
    const Color(0xFF2A0030), // Base purple
    const Color(0xFF5e0b8b), // Accent purple
  ];
  double _phase = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..addListener(() => setState(() => _phase = _controller.value))
     ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _compositeCurve(double x) {
    return sin(x * 2 * pi) * 0.4 +
           sin(x * 3 * pi + pi/3) * 0.3 +
           sin(x * 5 * pi) * 0.2 +
           sin(x * 7 * pi - pi/4) * 0.1;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DeepPurpleGradientPainter(
        phase: _phase,
        colors: _colors,
        compositeCurve: _compositeCurve,
      ),
      size: Size.infinite,
    );
  }
}

class _DeepPurpleGradientPainter extends CustomPainter {
  final double phase;
  final List<Color> colors;
  final double Function(double) compositeCurve;

  _DeepPurpleGradientPainter({
    required this.phase,
    required this.colors,
    required this.compositeCurve,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.srcOver;
    final path = Path();
    final noisePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..blendMode = BlendMode.overlay;

    // Create three layered curved gradients
    for (int layer = 0; layer < 3; layer++) {
      final layerPhase = (phase + layer * 0.15) % 1.0;
      final colorIndex = layer % colors.length;
      final nextColorIndex = (layer + 1) % colors.length;

      path.reset();
      path.moveTo(0, size.height);

      // Generate curved divider path
      for (double x = 0; x <= size.width; x += 4) {
        final t = (x / size.width + layerPhase) % 1.0;
        final y = size.height * 0.5 + 
          compositeCurve(t * 2 + layerPhase) * size.height * 0.25 +
          compositeCurve(t * 3 - layerPhase) * size.height * 0.15;
        
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      // Create gradient with dark purple colors
      final gradient = LinearGradient(
        colors: [colors[colorIndex], colors[nextColorIndex]],
        stops: const [0.4, 0.6],
        transform: GradientRotation(
          compositeCurve(layerPhase) * pi * 0.25,
        ),
      );

      paint
        ..shader = gradient.createShader(Rect.fromLTRB(0, 0, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

      canvas.drawPath(path, paint);
    }

    // Add subtle texture with dark purple noise
    final random = Random();
    for (int i = 0; i < 150; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 2,
        noisePaint..color = colors[1].withOpacity(0.03),
      );
    }
  }

  @override
  bool shouldRepaint(_DeepPurpleGradientPainter oldDelegate) => true;
}