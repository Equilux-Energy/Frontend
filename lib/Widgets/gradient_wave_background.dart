// fluid_gradient_background.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FluidGradientBackground extends StatefulWidget {
  const FluidGradientBackground({super.key});

  @override
  State<FluidGradientBackground> createState() => _FluidGradientBackgroundState();
}

class _FluidGradientBackgroundState extends State<FluidGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<WaveConfig> _waves = [
    WaveConfig(
      color: const Color(0x6025124A),
      amplitude: 70,
      frequency: 0.012,
      speed: 1,
      verticalPosition: 0.45,
    ),
    WaveConfig(
      color: const Color(0x80471F75),
      amplitude: 50,
      frequency: 0.016,
      speed: 2,
      verticalPosition: 0.55,
    ),
    WaveConfig(
      color: const Color(0x406A1B9A),
      amplitude: 60,
      frequency: 0.014,
      speed: 3,
      verticalPosition: 0.6,
    ),
    WaveConfig(
      color: const Color(0x209D1BC2),
      amplitude: 40,
      frequency: 0.018,
      speed: 4,
      verticalPosition: 0.5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24), // Longer duration for smoother transition
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Base gradient layers
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.5, -0.5),
                  radius: 1.8,
                  colors: [
                    Color(0xFF1A0A2C),
                    Color(0xFF2D0F45),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade900.withOpacity(0.8),
                    Colors.purple.shade900.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            // Dynamic waves with seamless animation
            ..._waves.map((wave) {
              final totalPhase = (_controller.value * 2 * math.pi * wave.speed) % (2 * math.pi);
              return CustomPaint(
                painter: _WavePainter(
                  color: wave.color,
                  amplitude: wave.amplitude,
                  frequency: wave.frequency,
                  phase: totalPhase,
                  verticalPosition: wave.verticalPosition,
                ),
                size: Size.infinite,
              );
            }),
          ],
        );
      },
    );
  }
}

class WaveConfig {
  final Color color;
  final double amplitude;
  final double frequency;
  final double speed;
  final double verticalPosition;

  WaveConfig({
    required this.color,
    required this.amplitude,
    required this.frequency,
    required this.speed,
    required this.verticalPosition,
  });
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double amplitude;
  final double frequency;
  final double phase;
  final double verticalPosition;

  _WavePainter({
    required this.color,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.verticalPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final baseY = size.height * verticalPosition;

    path.moveTo(-100, baseY);
    for (double x = 0; x <= size.width + 100; x++) {
      final y = baseY + amplitude * math.sin(frequency * x + phase);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width + 100, size.height);
    path.lineTo(-100, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}
