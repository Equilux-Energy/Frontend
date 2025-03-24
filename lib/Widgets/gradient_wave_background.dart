import 'package:flutter/material.dart';
import 'dart:math' as math;

class FluidGradientBackground extends StatefulWidget {
  const FluidGradientBackground({Key? key}) : super(key: key);

  @override
  FluidGradientBackgroundState createState() => FluidGradientBackgroundState();
}

class FluidGradientBackgroundState extends State<FluidGradientBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.deepPurple.shade900,
                Colors.blue.shade900,
                Colors.black,
              ],
            ),
          ),
        ),
        
        // Animated waves
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: GradientWavePainter(
                waveAnimation: _controller,
                pulseAnimation: _pulseController,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        
        // Sparkling stars effect
        const StarField(starCount: 150),
        
        // Subtle noise texture
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            backgroundBlendMode: BlendMode.softLight,
          ),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

class GradientWavePainter extends CustomPainter {
  final Animation<double> waveAnimation;
  final Animation<double> pulseAnimation;
  
  GradientWavePainter({
    required this.waveAnimation,
    required this.pulseAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // First wave (blue)
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.shade900.withOpacity(0.3),
          Colors.deepPurple.shade900.withOpacity(0.5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    
    final path1 = Path();
    path1.moveTo(0, height * 0.7);
    
    for (int i = 0; i < width.toInt(); i++) {
      final x = i.toDouble();
      final y = height * 0.7 + 
                math.sin((x / width * 4 * math.pi) + (waveAnimation.value * math.pi * 2)) * 30 +
                math.sin((x / width * 7 * math.pi) + (waveAnimation.value * math.pi * 4)) * 15;
      path1.lineTo(x, y);
    }
    
    path1.lineTo(width, height);
    path1.lineTo(0, height);
    path1.close();
    
    canvas.drawPath(path1, paint1);
    
    // Second wave (purple)
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.purple.shade900.withOpacity(0.3),
          Colors.blue.shade900.withOpacity(0.4),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    
    final path2 = Path();
    path2.moveTo(0, height * 0.8);
    
    for (int i = 0; i < width.toInt(); i++) {
      final x = i.toDouble();
      final y = height * 0.8 + 
                math.cos((x / width * 3 * math.pi) + (waveAnimation.value * math.pi * 3)) * 20 +
                math.cos((x / width * 5 * math.pi) + (waveAnimation.value * math.pi * 5)) * 10;
      path2.lineTo(x, y);
    }
    
    path2.lineTo(width, height);
    path2.lineTo(0, height);
    path2.close();
    
    canvas.drawPath(path2, paint2);
    
    // Central radial gradient for ambient glow
    final center = Offset(width / 2, height * 0.4);
    final radius = width * 0.3 * (0.8 + pulseAnimation.value * 0.2);
    
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.deepPurple.withOpacity(0.2 + pulseAnimation.value * 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, centerPaint);
  }
  
  @override
  bool shouldRepaint(GradientWavePainter oldDelegate) => true;
}

class StarField extends StatefulWidget {
  final int starCount;
  
  const StarField({Key? key, this.starCount = 100}) : super(key: key);

  @override
  _StarFieldState createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> with SingleTickerProviderStateMixin {
  late List<Star> stars;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    final random = math.Random();
    stars = List.generate(
      widget.starCount,
      (_) => Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 0.5 + random.nextDouble() * 1.5,
        blinkRate: 0.5 + random.nextDouble() * 2,
      ),
    );
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
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
        return CustomPaint(
          painter: StarPainter(
            stars: stars,
            animation: _controller,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double blinkRate;
  
  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.blinkRate,
  });
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  final Animation<double> animation;
  
  StarPainter({
    required this.stars,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    
    for (final star in stars) {
      // Calculate opacity based on blink rate and animation value
      final opacity = (math.sin(animation.value * math.pi * 2 * star.blinkRate) + 1) / 2;
      
      paint.color = Colors.white.withOpacity(0.3 + opacity * 0.7);
      
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(StarPainter oldDelegate) => true;
}