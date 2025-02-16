import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({Key? key}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final int _numberOfParticles = 100;
  final Random _random = Random();
  Offset? _touchPosition;
  final double _connectDistance = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Slower initial velocities
    for (int i = 0; i < _numberOfParticles; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 100,
        y: _random.nextDouble() * 100,
        radius: _random.nextDouble() * 5 + 4,
        vx: _random.nextDouble() * 1.0 - 0.5,  // Reduced velocity range
        vy: _random.nextDouble() * 1.0 - 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    for (var particle in _particles) {
      // Further reduced speed multiplier
      particle.x += particle.vx * 0.5;
      particle.y += particle.vy * 0.5;

      if (particle.x < 0 || particle.x > 100) {
        particle.vx *= -1;
        particle.x = particle.x.clamp(0.0, 100.0);
      }
      if (particle.y < 0 || particle.y > 100) {
        particle.vy *= -1;
        particle.y = particle.y.clamp(0.0, 100.0);
      }
    }
  }

  void _handlePanUpdate(Offset localPosition) {
    setState(() {
      _touchPosition = localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0030), Color(0xff5e0b8b)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: GestureDetector(
        onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
        onPanEnd: (_) => setState(() => _touchPosition = null),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            _updateParticles();
            return CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                touchPosition: _touchPosition,
                screenSize: MediaQuery.of(context).size,
                connectDistance: _connectDistance,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class Particle {
  double x, y;
  double radius;
  double vx, vy;
  final double maxSpeed = 1.2; // Reduced maximum speed

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.vx,
    required this.vy,
  });

  void applyForce(double fx, double fy) {
    vx = (vx + fx).clamp(-maxSpeed, maxSpeed);
    vy = (vy + fy).clamp(-maxSpeed, maxSpeed);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset? touchPosition;
  final Size screenSize;
  final double connectDistance;

  ParticlePainter({
    required this.particles,
    required this.touchPosition,
    required this.screenSize,
    required this.connectDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final connectionPaint = Paint()
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final particlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.withOpacity(0.9),
          Colors.yellow.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset.zero,
        radius: 20,
      ));

    // Draw particle connections
    for (var i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      final pos1 = Offset(
        p1.x / 100 * screenSize.width,
        p1.y / 100 * screenSize.height,
      );

      for (var j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final pos2 = Offset(
          p2.x / 100 * screenSize.width,
          p2.y / 100 * screenSize.height,
        );
        final distance = (pos1 - pos2).distance;

        if (distance < connectDistance) {
          final alpha = (1 - distance / connectDistance).clamp(0.1, 0.4);
          connectionPaint.color = Colors.white
              .withOpacity(alpha)
              .withGreen(200)
              .withRed(200);
          canvas.drawLine(pos1, pos2, connectionPaint);
        }
      }
    }

    // Draw particles
    for (var particle in particles) {
      final pos = Offset(
        particle.x / 100 * screenSize.width,
        particle.y / 100 * screenSize.height,
      );

      // Main particle
      canvas.drawCircle(pos, particle.radius, particlePaint);
      
      // Glow effect
      canvas.drawCircle(
        pos,
        particle.radius * 1.5,
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Cursor connections
      if (touchPosition != null) {
        final cursorDistance = (pos - touchPosition!).distance;
        if (cursorDistance < connectDistance) {
          final alpha = (1 - cursorDistance / connectDistance).clamp(0.2, 0.7);
          connectionPaint.color = Colors.yellow.withOpacity(alpha);
          canvas.drawLine(pos, touchPosition!, connectionPaint);
          
          if (cursorDistance < connectDistance * 0.6) {
            canvas.drawCircle(
              touchPosition!,
              (connectDistance - cursorDistance) * 0.3,
              Paint()
                ..color = Colors.white.withOpacity(alpha * 0.3)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
            );
          }
        }
      }
    }

    // Cursor glow
    if (touchPosition != null) {
      canvas.drawCircle(
        touchPosition!,
        30,
        Paint()
          ..color = Colors.yellow.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
