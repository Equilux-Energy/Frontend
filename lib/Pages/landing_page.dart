import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import '../Widgets/gradient_wave_background.dart';
import 'dart:math' as math;

/// This widget uses VisibilityDetector to monitor when its child scrolls into view.
/// When visible, after an optional delay it animates the child into view using
/// AnimatedOpacity, AnimatedSlide, and (optionally) AnimatedScale. When off-screen,
/// it immediately reverses the animations. The child's space is maintained even when invisible.
class AnimateOnVisibility extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  /// When not visible, the widget is shifted by these amounts (as an Offset)
  /// (for slide animations). If not provided, no slide animation is applied.
  final double? slideXBegin;
  final double? slideYBegin;
  /// If true, the widget scales from 0 to 1 when becoming visible.
  final bool scale;

  const AnimateOnVisibility({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.slideXBegin,
    this.slideYBegin,
    this.scale = false,
  }) : super(key: key);

  @override
  _AnimateOnVisibilityState createState() => _AnimateOnVisibilityState();
}

class _AnimateOnVisibilityState extends State<AnimateOnVisibility> {
  bool _animate = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (VisibilityInfo info) {
        bool nowVisible = info.visibleFraction > 0;
        if (nowVisible && !_animate) {
          Future.delayed(widget.delay, () {
            if (mounted && info.visibleFraction > 0) {
              setState(() {
                _animate = true;
              });
            }
          });
        }
        if (!nowVisible && _animate) {
          setState(() {
            _animate = false;
          });
        }
      },
      child: Visibility(
        visible: true,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: AnimatedOpacity(
          opacity: _animate ? 1.0 : 0.0,
          duration: widget.duration,
          curve: Curves.easeInOut,
          child: (widget.slideXBegin != null || widget.slideYBegin != null)
              ? AnimatedSlide(
                  offset: _animate
                      ? Offset.zero
                      : Offset(widget.slideXBegin ?? 0, widget.slideYBegin ?? 0),
                  duration: widget.duration,
                  curve: Curves.easeInOut,
                  child: widget.scale
                      ? AnimatedScale(
                          scale: _animate ? 1.0 : 0.0,
                          duration: widget.duration,
                          curve: Curves.easeInOut,
                          child: widget.child,
                        )
                      : widget.child,
                )
              : (widget.scale
                  ? AnimatedScale(
                      scale: _animate ? 1.0 : 0.0,
                      duration: widget.duration,
                      curve: Curves.easeInOut,
                      child: widget.child,
                    )
                  : widget.child),
        ),
      ),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0;
  bool _showFloatingNavbar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
  setState(() {
    _scrollProgress = (_scrollController.offset / 100).clamp(0, 1);
    _showFloatingNavbar = _scrollController.offset > 120;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // No app bar here - we'll use a custom floating one
      body: Stack(
        children: [
          const FluidGradientBackground(),
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildInitialHeader(), // Initial header that will fade out
                _buildHeroSection(),
                _buildEnergyRevolutionSection(),
                _buildGridSystemSection(),
                _buildFeatureCards(),
                _buildTechExplanation(),
                _buildJoinCommunitySection(),
              ],
            ),
          ),
          // Floating navbar that appears on scroll
          _buildFloatingNavbar(),
        ],
      ),
    );
  }

  Widget _buildInitialHeader() {
  // This is the initial header that fades out on scroll
  return AnimatedOpacity(
    opacity: 1.0 - _scrollProgress,
    duration: const Duration(milliseconds: 200),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: kToolbarHeight + 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PIONEER',
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              _buildNavButton('Overview', '/about'),
              _buildNavButton('Platform', '/features'),
              _buildNavButton('Connect', '/contact'),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.amber),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => context.push('/signin'),
                  child: const Text('Join Now', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildFloatingNavbar() {
  return AnimatedPositioned(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
    top: _showFloatingNavbar ? 16 : -80, // Slide in from top
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        width: _showFloatingNavbar ? 500 : 0, // Animate width
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  const Text(
                    'PIONEER',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Navigation items
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFloatingNavItem('About', '/about'),
                      _buildFloatingNavItem('Platform', '/features'),
                      _buildFloatingNavItem('Contact', '/contact'),
                      const SizedBox(width: 8),
                      _buildFloatingActionButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildFloatingNavItem(String text, String route) {
  return TextButton(
    onPressed: () => context.push(route),
    style: TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}

Widget _buildFloatingActionButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    onPressed: () => context.push('/signin'),
    child: const Text(
      'Join',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildNavButton(String text, String route) {
    return TextButton(
      onPressed: () => context.push(route),
      child: Text(
        text, 
        style: const TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Decorative energy grid lines in background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          
          // Main hero content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AnimateOnVisibility(
                    key: Key('hero-title'),
                    slideYBegin: 0.3,
                    child: Text(
                      'PIONEER',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 15, color: Colors.amber, offset: Offset(0, 0)),
                          Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AnimateOnVisibility(
                    key: Key('hero-subtitle'),
                    delay: Duration(milliseconds: 200),
                    slideYBegin: 0.3,
                    child: Text(
                      'The Future of Energy Trading',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28, 
                        color: Colors.white, 
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimateOnVisibility(
                    key: const Key('hero-tagline'),
                    delay: const Duration(milliseconds: 400),
                    slideYBegin: 0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(color: Colors.purple.shade300.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Decentralized Peer-to-Peer Energy Exchange Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22, 
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  AnimateOnVisibility(
                    key: const Key('hero-cta'),
                    delay: const Duration(milliseconds: 600),
                    scale: true,
                    child: _buildPrimaryButton(
                      'Join the Energy Revolution',
                      onPressed: () => context.push('/signup'),
                    ),
                  ),
                  const SizedBox(height: 80),
                  AnimateOnVisibility(
                    key: const Key('hero-scroll'),
                    delay: const Duration(milliseconds: 800),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 36,
                    ).animate(onComplete: (controller) => controller.repeat())
                     .fadeIn(duration: 600.ms)
                     .then(delay: 400.ms)
                     .moveY(begin: 0, end: 12, duration: 800.ms)
                     .then(delay: 100.ms)
                     .moveY(begin: 12, end: 0, duration: 800.ms),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyRevolutionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
      child: Column(
        children: [
          const AnimateOnVisibility(
            key: Key('revolution-title'),
            slideYBegin: 0.2,
            child: Text(
              'The Energy Crisis in Lebanon',
              style: TextStyle(
                fontSize: 42, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimateOnVisibility(
            key: const Key('revolution-subtitle'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'Transforming how energy is distributed, traded, and consumed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              return isMobile 
                ? _buildMobileProblemStats()
                : _buildDesktopProblemStats();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileProblemStats() {
    return Column(
      children: [
        AnimateOnVisibility(
          key: const Key('stat-card-0'),
          slideYBegin: 0.2,
          child: _buildStatCard('70%+', 'Households rely on private generators'),
        ),
        const SizedBox(height: 24),
        AnimateOnVisibility(
          key: const Key('stat-card-1'),
          slideYBegin: 0.2,
          delay: const Duration(milliseconds: 100),
          child: _buildStatCard('\$200/mo', 'Average energy costs per household'),
        ),
        const SizedBox(height: 24),
        AnimateOnVisibility(
          key: const Key('stat-card-2'),
          slideYBegin: 0.2,
          delay: const Duration(milliseconds: 200),
          child: _buildStatCard('4-6 hrs/day', 'National grid availability'),
        ),
        const SizedBox(height: 24),
        AnimateOnVisibility(
          key: const Key('stat-card-3'),
          slideYBegin: 0.2,
          delay: const Duration(milliseconds: 300),
          child: _buildStatCard('15%', 'Grid transmission efficiency'),
        ),
      ],
    );
  }
  
  Widget _buildDesktopProblemStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('stat-card-0'),
            slideYBegin: 0.2,
            child: _buildStatCard('70%+', 'Households rely on private generators'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('stat-card-1'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 100),
            child: _buildStatCard('\$200/mo', 'Average energy costs per household'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('stat-card-2'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 200),
            child: _buildStatCard('4-6 hrs/day', 'National grid availability'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('stat-card-3'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 300),
            child: _buildStatCard('15%', 'Grid transmission efficiency'),
          ),
        ),
      ],
    );
  }

  Widget _buildGridSystemSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Column(
        children: [
          const AnimateOnVisibility(
            key: Key('grid-title'),
            slideYBegin: 0.2,
            child: Text(
              'Blockchain-Powered Microgrid',
              style: TextStyle(
                fontSize: 42, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimateOnVisibility(
            key: const Key('grid-subtitle'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'A decentralized approach to energy distribution',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          
          // 3D grid illustration
          SizedBox(
            height: 400,
            child: AnimateOnVisibility(
              key: const Key('grid-illustration'),
              slideYBegin: 0.2,
              delay: const Duration(milliseconds: 300),
              child: _buildGridIllustration(),
            ),
          ),
          
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimateOnVisibility(
                key: const Key('grid-action'),
                delay: const Duration(milliseconds: 400),
                slideYBegin: 0.2,
                child: _buildSecondaryButton(
                  'Explore the Technology',
                  onPressed: () => context.push('/technology'),
                  leadingIcon: Icons.memory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGridIllustration() {
    return Stack(
      children: [
        // Background grid container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purple.shade300.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: CustomPaint(
            painter: _NetworkGridPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        
        // Energy nodes
        Positioned(
          top: 100,
          left: 100,
          child: _buildEnergyNode('Home', Colors.amber, Icons.home),
        ),
        
        Positioned(
          top: 120,
          right: 150,
          child: _buildEnergyNode('Solar', Colors.amber.shade300, Icons.solar_power),
        ),
        
        Positioned(
          bottom: 100,
          left: 180,
          child: _buildEnergyNode('Business', Colors.blue.shade300, Icons.business),
        ),
        
        Positioned(
          bottom: 140,
          right: 120,
          child: _buildEnergyNode('Storage', Colors.green.shade300, Icons.battery_charging_full),
        ),
        
        // Central exchange node
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade900.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.sync_alt,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEnergyNode(String label, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        children: [
          const AnimateOnVisibility(
            key: Key('features-title'),
            slideYBegin: 0.2,
            child: Text(
              'Advanced Platform Features',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          AnimateOnVisibility(
            key: const Key('features-subtitle'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'Built on blockchain with AI-powered smart contracts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          
          // Features grid - responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1100;
              
              int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
              
              return GridView.count(
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.0,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  AnimateOnVisibility(
                    key: const Key('feature-card-0'),
                    slideYBegin: 0.2,
                    child: _buildFeatureCard(
                      Icons.account_balance_wallet,
                      'Blockchain Trading',
                      'Secure peer-to-peer transactions using advanced Hyperledger Fabric technology',
                    ),
                  ),
                  AnimateOnVisibility(
                    key: const Key('feature-card-1'),
                    slideYBegin: 0.2,
                    delay: const Duration(milliseconds: 100),
                    child: _buildFeatureCard(
                      Icons.solar_power,
                      'Renewable Integration',
                      'Seamlessly combine solar panels with existing generators for optimal energy use',
                    ),
                  ),
                  AnimateOnVisibility(
                    key: const Key('feature-card-2'),
                    slideYBegin: 0.2,
                    delay: const Duration(milliseconds: 200),
                    child: _buildFeatureCard(
                      Icons.psychology,
                      'AI Predictions',
                      'Machine learning algorithms for precise energy consumption and production forecasting',
                    ),
                  ),
                  AnimateOnVisibility(
                    key: const Key('feature-card-3'),
                    slideYBegin: 0.2,
                    delay: const Duration(milliseconds: 300),
                    child: _buildFeatureCard(
                      Icons.bolt,
                      'Microgrid Support',
                      'Advanced islanding capability with automatic grid synchronization technology',
                    ),
                  ),
                  AnimateOnVisibility(
                    key: const Key('feature-card-4'),
                    slideYBegin: 0.2,
                    delay: const Duration(milliseconds: 400),
                    child: _buildFeatureCard(
                      Icons.security,
                      'Military-Grade Security',
                      'End-to-end encrypted communications with blockchain verification',
                    ),
                  ),
                  AnimateOnVisibility(
                    key: const Key('feature-card-5'),
                    slideYBegin: 0.2,
                    delay: const Duration(milliseconds: 500),
                    child: _buildFeatureCard(
                      Icons.currency_exchange,
                      'Dynamic Pricing',
                      'Real-time market-based pricing engine that adapts to supply and demand',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTechExplanation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900.withOpacity(0.4),
            Colors.purple.shade900.withOpacity(0.4),
          ],
        ),
      ),
      child: Column(
        children: [
          const AnimateOnVisibility(
            key: Key('tech-title'),
            slideYBegin: 0.2,
            child: Text(
              'Cutting-Edge Technology Stack',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          AnimateOnVisibility(
            key: const Key('tech-subtitle'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'PIONEER combines advanced technologies to create a robust energy trading platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          
          // Tech stack visualization
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimateOnVisibility(
              key: const Key('tech-flow'),
              slideYBegin: 0.2,
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade300.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        techPills.length ~/ 2,
                        (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimateOnVisibility(
                              key: Key('tech-pill-$i'),
                              delay: Duration(milliseconds: 50 * i),
                              slideYBegin: 0.2,
                              child: _buildTechPill(techPills[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const AnimateOnVisibility(
                      key: Key('tech-diagram'),
                      delay: Duration(milliseconds: 500),
                      child: Icon(
                        Icons.architecture,
                        color: Colors.amber,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        techPills.length ~/ 2,
                        (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimateOnVisibility(
                              key: Key('tech-pill-${i + techPills.length ~/ 2}'),
                              delay: Duration(milliseconds: 50 * (i + techPills.length ~/ 2)),
                              slideYBegin: 0.2,
                              child: _buildTechPill(techPills[i + techPills.length ~/ 2]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 60),
          AnimateOnVisibility(
            key: const Key('tech-button'),
            delay: const Duration(milliseconds: 600),
            scale: true,
            child: _buildSecondaryButton(
              'Technical Documentation',
              onPressed: () => context.push('/documentation'),
              leadingIcon: Icons.article,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCommunitySection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
      child: Column(
        children: [
          const AnimateOnVisibility(
            key: Key('join-title'),
            slideYBegin: 0.2,
            child: Text(
              'Join the Energy Revolution',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          AnimateOnVisibility(
            key: const Key('join-subtitle'),
            slideYBegin: 0.2,
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'Be part of the solution that transforms energy access in Lebanon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          
          // Benefits section
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              
              return isMobile
                                  ? _buildMobileBenefits()
                : _buildDesktopBenefits();
            },
          ),
          
          const SizedBox(height: 80),
          AnimateOnVisibility(
            key: const Key('join-cta'),
            delay: const Duration(milliseconds: 600),
            scale: true,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade900.withOpacity(0.6),
                    Colors.purple.shade900.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Ready to Transform Energy in Lebanon?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    'Start Trading Now',
                    onPressed: () => context.push('/signup'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Demo System Cost: \$590',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 80),
          _buildFooter(),
        ],
      ),
    );
  }
  
  Widget _buildMobileBenefits() {
    return Column(
      children: [
        AnimateOnVisibility(
          key: const Key('benefit-card-0'),
          slideYBegin: 0.2,
          child: _buildBenefitCard(
            Icons.savings,
            '40% Cost Reduction',
            'Through direct P2P trading and optimized pricing algorithms',
          ),
        ),
        const SizedBox(height: 24),
        AnimateOnVisibility(
          key: const Key('benefit-card-1'),
          slideYBegin: 0.2,
          delay: const Duration(milliseconds: 100),
          child: _buildBenefitCard(
            Icons.eco,
            'Sustainable Future',
            'Promote renewable energy adoption and reduce dependency on fossil fuels',
          ),
        ),
        const SizedBox(height: 24),
        AnimateOnVisibility(
          key: const Key('benefit-card-2'),
          slideYBegin: 0.2,
          delay: const Duration(milliseconds: 200),
          child: _buildBenefitCard(
            Icons.security,
            'Energy Security',
            'Microgrid islanding during national grid failures ensures consistent power',
          ),
        ),
        const SizedBox(height: 24),
        AnimateOnVisibility(
          key: const Key('benefit-card-3'),
          slideYBegin: 0.2,
          delay: const Duration(milliseconds: 300),
          child: _buildBenefitCard(
            Icons.trending_up,
            'Earn Income',
            'Sell excess energy to neighbors and businesses in your community',
          ),
        ),
      ],
    );
  }
  
  Widget _buildDesktopBenefits() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('benefit-card-0'),
            slideXBegin: -0.2,
            child: _buildBenefitCard(
              Icons.savings, 
              '40% Cost Reduction',
              'Through direct P2P trading and optimized pricing algorithms',
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('benefit-card-1'),
            slideYBegin: 0.2,
            child: _buildBenefitCard(
              Icons.eco,
              'Sustainable Future',
              'Promote renewable energy adoption and reduce dependency on fossil fuels',
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('benefit-card-2'),
            slideYBegin: 0.2,
            child: _buildBenefitCard(
              Icons.security,
              'Energy Security',
              'Microgrid islanding during national grid failures ensures consistent power',
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: AnimateOnVisibility(
            key: const Key('benefit-card-3'),
            slideXBegin: 0.2,
            child: _buildBenefitCard(
              Icons.trending_up,
              'Earn Income',
              'Sell excess energy to neighbors and businesses in your community',
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(
          top: BorderSide(
            color: Colors.purple.shade300.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PIONEER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildComplianceBadge('IEEE 1547'),
              _buildComplianceBadge('ISO 50001'),
              _buildComplianceBadge('NIST CSF'),
              _buildComplianceBadge('GDPR Compliant'),
              _buildComplianceBadge('UL 1741'),
              _buildComplianceBadge('IEC 62109'),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink('Privacy', '/privacy'),
              _buildFooterDivider(),
              _buildFooterLink('Terms', '/terms'),
              _buildFooterDivider(),
              _buildFooterLink('FAQ', '/faq'),
              _buildFooterDivider(),
              _buildFooterLink('Contact', '/contact'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2025 Equilux Energy. All rights reserved.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooterLink(String text, String route) {
    return TextButton(
      onPressed: () => context.push(route),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildFooterDivider() {
    return Container(
      height: 16,
      width: 1,
      color: Colors.white30,
    );
  }

  // Helper widgets
  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade300.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value, 
            style: const TextStyle(
              fontSize: 42, 
              fontWeight: FontWeight.bold, 
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label, 
            textAlign: TextAlign.center, 
            style: const TextStyle(
              fontSize: 18, 
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade300.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              title, 
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                description, 
                textAlign: TextAlign.center, 
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefitCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade300.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            title, 
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description, 
            textAlign: TextAlign.center, 
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTechPill(String tech) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1),
      ),
      child: Text(
        tech,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildComplianceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.amber.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }
  
  Widget _buildPrimaryButton(String text, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }
  
  Widget _buildSecondaryButton(String text, {required VoidCallback onPressed, IconData? leadingIcon}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.purple.shade300.withOpacity(0.4)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }

  // List of technologies used in the platform
  final List<String> techPills = [
    'Hyperledger Fabric',
    'TensorFlow Lite',
    'IoT Sensors',
    'AWS IoT Core',
    'Flutter Framework',
    'MPPT Controllers',
    'Machine Learning',
    'Smart Contracts',
  ];
}

// Custom painters for visual effects

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw diagonal accent lines
    final accentPaint = Paint()
      ..color = Colors.amber.withOpacity(0.15)
      ..strokeWidth = 2;
      
    canvas.drawLine(
      Offset(0, size.height * 0.3), 
      Offset(size.width, size.height * 0.7),
      accentPaint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.2, 0), 
      Offset(size.width * 0.8, size.height),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NetworkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
      
    final accentPaint = Paint()
      ..color = Colors.amber.withOpacity(0.2)
      ..strokeWidth = 2;
      
    // Create a network of connecting lines
    final random = math.Random(42); // Fixed seed for consistent results
    final points = <Offset>[];
    
    // Generate random points
    for (int i = 0; i < 20; i++) {
      points.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }
    
    // Add the center point
    final center = Offset(size.width / 2, size.height / 2);
    points.add(center);
    
    // Connect points in a network pattern
    for (int i = 0; i < points.length; i++) {
      // Always connect to center
      if (i != points.length - 1) {
        canvas.drawLine(points[i], center, accentPaint);
      }
      
      // Connect to some other points
      for (int j = i + 1; j < points.length; j++) {
        if (random.nextBool() && j != points.length - 1) {
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }
    
    // Add some energy pulses along the lines
    final pulsePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 8; i++) {
      final pointIndex = random.nextInt(points.length - 1);
      canvas.drawCircle(
        Offset.lerp(points[pointIndex], center, random.nextDouble())!,
        3,
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade300.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              title, 
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description, 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Import for math.Random
