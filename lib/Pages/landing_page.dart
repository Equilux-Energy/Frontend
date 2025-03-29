import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' as rive;
import 'package:flutter_svg/flutter_svg.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingIsland = false;
  double _scrollProgress = 0.0;
  
  // Animation controllers
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late AnimationController _waveController;
  
  // Hover states for interactive elements
  bool _heroButtonHovered = false;
  int? _hoveredFeature;
  int? _hoveredTechItem;
  
  // Mouse position for custom cursor effect
  Offset _mousePosition = Offset.zero;
  bool _mouseInView = false;
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _visionKey = GlobalKey();
  final GlobalKey _technologyKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Initialize animation controllers
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    // Set system UI overlay style to match the dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _scrollListener() {
    final threshold = MediaQuery.of(context).size.height * 0.3;
    setState(() {
      _scrollProgress = (_scrollController.offset / threshold).clamp(0.0, 1.0);
      _showFloatingIsland = _scrollController.offset > threshold;
    });
  }
  
  void _updateMousePosition(PointerEvent event) {
    setState(() {
      _mousePosition = event.position;
      _mouseInView = true;
    });
  }
  
  void _clearMousePosition(PointerEvent event) {
    setState(() {
      _mouseInView = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'equilux.energy.dev@gmail.com',
      queryParameters: {
        'subject': 'Inquiry about PIONEER Project'
      }
    );
    
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch email client'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _updateMousePosition,
      onExit: _clearMousePosition,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Animated background with particles and plasma effect
            RepaintBoundary(
              child: Stack(
                children: [
                  // Base gradient background
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: NeospacePlasmaBackgroundPainter(
                          animation: _rotateController.value,
                        ),
                      );
                    },
                  ),
                  
                  // Energy grid overlay
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: EnergyGridPainter(
                          animation: _waveController.value,
                        ),
                      );
                    },
                  ),
                  
                  // Particle system
                  AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: HolographicParticlesPainter(
                          animation: _particleController.value,
                          mousePosition: _mouseInView ? _mousePosition : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Main scrollable content
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInitialHeader(),
                  _buildRevolutionaryHeroSection(),
                  _buildEnergyTransformationSection(),
                  _buildFuturisticTechnologySection(),
                  _buildInteractiveFeaturesSection(),
                  _buildContactSection(),
                ],
              ),
            ),
            
            // Floating Island App Bar
            _buildFloatingIslandAppBar(),

            // Update the back to top button for mobile
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              top: _showFloatingIsland ? 95 : -100,
              right: 0,
              left: 0,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 3 * math.sin(_floatController.value * math.pi * 2)),
                    child: child,
                  );
                },
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_double_arrow_up,
                            color: Colors.white.withOpacity(0.7),
                            size: 28,
                          ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, -2 * _pulseController.value),
                                child: Icon(
                                  Icons.keyboard_double_arrow_up,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Custom cursor effect (only visible when mouse is in view)
            if (_mouseInView)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutQuint,
                left: _mousePosition.dx - 15,
                top: _mousePosition.dy - 15,
                child: IgnorePointer(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialHeader() {
  final isMobile = Responsive.isMobile(context);
  
  return AnimatedOpacity(
    opacity: 1.0 - _scrollProgress,
    duration: const Duration(milliseconds: 200),
    child: Container(
      padding: Responsive.getScreenPadding(context),
      height: kToolbarHeight + (isMobile ? 16 : 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo with animation
          Row(
            children: [
              // Animated energy icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: isMobile ? 32 : 40,
                    height: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3 + 0.2 * _pulseController.value),
                          blurRadius: 10 + 5 * _pulseController.value,
                          spreadRadius: 1 + _pulseController.value,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.bolt,
                        color: Colors.deepPurple.shade100,
                        size: isMobile ? 16 : 20,
                      ),
                    ),
                  );
                }
              ),
              SizedBox(width: isMobile ? 8 : 16),
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.deepPurple.shade300,
                      Colors.cyan.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Text(
                  'PIONEER',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: isMobile ? 2.0 : 3.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          // Nav Items - Mobile Menu vs Desktop Nav
          isMobile 
              ? _buildMobileHeaderMenu() 
              : Row(
                  children: [
                    _buildNavItem('Vision', () {
                      _scrollToSection(_visionKey);
                    }),
                    _buildNavItem('Technology', () {
                      _scrollToSection(_technologyKey);
                    }),
                    _buildNavItem('Features', () {
                      _scrollToSection(_featuresKey);
                    }),
                    _buildNavItem('Contact', () {
                      _scrollToSection(_contactKey);
                    }),
                  ],
                ),
        ],
      ),
    ),
  );
}

Widget _buildMobileHeaderMenu() {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.menu, color: Colors.white),
    color: Colors.black.withOpacity(0.8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(
        color: Colors.deepPurple.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    onSelected: (value) {
      switch (value) {
        case 'Vision':
          _scrollToSection(_visionKey);
          break;
        case 'Technology':
          _scrollToSection(_technologyKey);
          break;
        case 'Features':
          _scrollToSection(_featuresKey);
          break;
        case 'Contact':
          _scrollToSection(_contactKey);
          break;
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'Vision',
        child: Text('Vision', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem(
        value: 'Technology',
        child: Text('Technology', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem(
        value: 'Features',
        child: Text('Features', style: TextStyle(color: Colors.white)),
      ),
      const PopupMenuItem(
        value: 'Contact',
        child: Text('Contact', style: TextStyle(color: Colors.white)),
      ),
    ],
  );
}

  Widget _buildFloatingIslandAppBar() {
  final size = MediaQuery.of(context).size;
  final isMobile = Responsive.isMobile(context);
  final islandWidth = math.min(size.width * 0.92, 800.0);
  
  return AnimatedPositioned(
    duration: const Duration(milliseconds: 600),
    curve: Curves.elasticOut,
    top: _showFloatingIsland ? 20 : -100,
    left: (size.width - islandWidth) / 2,
    right: (size.width - islandWidth) / 2,
    child: AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 3 * math.sin(_floatController.value * math.pi * 2)),
          child: child,
        );
      },
      child: Container(
        height: isMobile ? 60 : 70,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.cyan.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 30),
              child: isMobile 
                ? _buildMobileAppBarContent()
                : _buildDesktopAppBarContent(),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildMobileAppBarContent() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Logo only for mobile
      ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: [
              Colors.deepPurple.shade300,
              Colors.cyan.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: const Text(
          'PIONEER',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      
      // Mobile menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: Colors.white),
        color: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Colors.deepPurple.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        onSelected: (value) {
          switch (value) {
            case 'Vision':
              _scrollToSection(_visionKey);
              break;
            case 'Technology':
              _scrollToSection(_technologyKey);
              break;
            case 'Features':
              _scrollToSection(_featuresKey);
              break;
            case 'Contact':
              _scrollToSection(_contactKey);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'Vision',
            child: Text('Vision', style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem(
            value: 'Technology',
            child: Text('Technology', style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem(
            value: 'Features',
            child: Text('Features', style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem(
            value: 'Contact',
            child: Text('Contact', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ],
  );
}

Widget _buildDesktopAppBarContent() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Animated logo
      Row(
        children: [
          // Energy pulse icon
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse rings
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 36 * (0.6 + 0.4 * _pulseController.value),
                      height: 36 * (0.6 + 0.4 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(
                            0.8 * (1 - _pulseController.value),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                
                // Middle pulse ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 26 * (0.7 + 0.3 * _pulseController.value),
                      height: 26 * (0.7 + 0.3 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.cyan.withOpacity(
                            0.6 * (1 - _pulseController.value),
                          ),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                ),
                
                // Core
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.deepPurple.shade300,
                        Colors.deepPurple.shade900,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Text with gradient
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.deepPurple.shade300,
                  Colors.cyan.shade300,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Text(
              'PIONEER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      
      // Nav items for desktop
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingNavItem('Vision', () {
            _scrollToSection(_visionKey);
          }),
          _buildFloatingNavItem('Technology', () {
            _scrollToSection(_technologyKey);
          }),
          _buildFloatingNavItem('Features', () {
            _scrollToSection(_featuresKey);
          }),
          _buildFloatingNavItem('Contact', () {
            _scrollToSection(_contactKey);
          }),
        ],
      ),
    ],
  );
}
  
 void _scrollToSection(GlobalKey key) {
  if (key.currentContext == null) return;
  
  final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  
  print('Section position: ${position.dy}');
  print('Current scroll position: ${_scrollController.position.pixels}');
  print('Floating island visible: $_showFloatingIsland');
  
  final absoluteScrollPosition = _scrollController.position.pixels + position.dy;// - (_showFloatingIsland ? 100 : 80);
  
  print('Target scroll position: $absoluteScrollPosition');
  
  _scrollController.animateTo(
    absoluteScrollPosition,
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeInOutCubic,
  );
}

  Widget _buildNavItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      hoverColor: Colors.deepPurple.withOpacity(0.2),
      splashColor: Colors.deepPurple.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(String title, VoidCallback onTap) {
  return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      hoverColor: Colors.deepPurple.withOpacity(0.2),
      splashColor: Colors.deepPurple.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
}

  Widget _buildRevolutionaryHeroSection() {
  final isMobile = Responsive.isMobile(context);
  final isTablet = Responsive.isTablet(context);
  
  return Stack(
    key: _heroKey,
    children: [
      // Height should be screen height plus some extra space for scrolling effect
      SizedBox(
        height: MediaQuery.of(context).size.height * 1.1,
        width: double.infinity,
      ),
      
      // Energy field background effect
      Positioned.fill(
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotateController, _pulseController]),
          builder: (context, child) {
            return CustomPaint(
              painter: EnergyFieldPainter(
                rotationValue: _rotateController.value,
                pulseValue: _pulseController.value,
              ),
            );
          },
        ),
      ),
      
      // Orbiting energy spheres
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _orbitController,
          builder: (context, child) {
            return CustomPaint(
              painter: OrbitalEnergyPainter(
                animation: _orbitController.value,
              ),
            );
          },
        ),
      ),
      
      // Content positioned on top of effects
      Positioned.fill(
        child: Center(
          child: Padding(
            padding: Responsive.getScreenPadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main title with glowing effect
                FutureText(
                  'PIONEER',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, isMobile ? 60 : isTablet ? 80 : 100),
                    fontWeight: FontWeight.w900,
                    letterSpacing: isMobile ? 5 : 10,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // Subtitle with animated reveal
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 15 : 30,
                    vertical: isMobile ? 10 : 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: StaggeredTextAnimation(
                    text: 'Peer-to-Peer Integrated Optimized Energy Exchange Resource',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, isMobile ? 16 : isTablet ? 18 : 22),
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 1,
                      height: 1.4,
                    ),
                  ),
                ),
                
                SizedBox(height: isMobile ? 30 : 50),
                
                // Description text with animated typing effect
                SizedBox(
                  width: isMobile ? double.infinity : 700,
                  child: TypewriterText(
                    'Revolutionizing energy distribution with blockchain-powered microgrids and AI-driven optimization.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, isMobile ? 14 : 18),
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                ),
                
                SizedBox(height: isMobile ? 40 : 70),
                
                // Animated call-to-action button
                StatefulBuilder(
                  builder: (context, setState) {
                    return MouseRegion(
                      onEnter: (_) => setState(() => _heroButtonHovered = true),
                      onExit: (_) => setState(() => _heroButtonHovered = false),
                      child: GestureDetector(
                        onTap: () => _scrollToSection(_visionKey),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: _heroButtonHovered ? (isMobile ? 30 : 40) : (isMobile ? 24 : 32),
                            vertical: isMobile ? 12 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: _heroButtonHovered 
                                ? Colors.deepPurple.withOpacity(0.8)
                                : Colors.deepPurple.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.deepPurple.shade300,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(_heroButtonHovered ? 0.5 : 0.3),
                                blurRadius: _heroButtonHovered ? 25 : 15,
                                spreadRadius: _heroButtonHovered ? 1 : -2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isMobile ? 'Discover More' : 'Discover the Future of Energy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.getFontSize(context, 16),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: _heroButtonHovered ? 1.5 : 1.0,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _heroButtonHovered ? 12 : 0,
                              ),
                              AnimatedOpacity(
                                opacity: _heroButtonHovered ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: isMobile ? 50 : 100),
                
                // Scroll indicator with fluid animation
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 8 * math.sin(_floatController.value * math.pi)),
                      child: AnimatedOpacity(
                        opacity: 0.7 + 0.3 * math.sin(_floatController.value * math.pi),
                        duration: Duration.zero,
                        child: const Icon(
                          Icons.expand_more,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildEnergyTransformationSection() {
  final isMobile = Responsive.isMobile(context);
  
  return Container(
    key: _visionKey,
    padding: Responsive.getScreenPadding(context).copyWith(
      top: isMobile ? 60 : 100,
      bottom: isMobile ? 60 : 100
    ),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 50,
          spreadRadius: -10,
          offset: const Offset(0, -30),
        ),
      ],
    ),
    child: Column(
      children: [
        // Section title with reveal animation
        RevealText(
          'Energy Revolution',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, isMobile ? 32 : 42),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Description with fade animation
        FadeSlideAnimation(
          delay: const Duration(milliseconds: 300),
          child: SizedBox(
            width: isMobile ? double.infinity : 800,
            child: Text(
              'PIONEER transforms conventional energy systems into dynamic, decentralized networks. Break free from unreliable centralized infrastructure and high costs with peer-to-peer energy trading.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, isMobile ? 14 : 18),
                color: Colors.white70,
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ),
        ),
        
        SizedBox(height: isMobile ? 50 : 80),
        
        // Microgrid visualization with interactive components
        SizedBox(
          height: isMobile ? 450 : 500,  // Increase height for mobile
          child: Stack(
            // Important: This makes tooltip positioning work properly relative to the Stack
            clipBehavior: Clip.none,
            children: [
              // Dynamic energy flow visualization - LAYER 1 (BOTTOM)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_rotateController, _pulseController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: EnergyFlowPainter(
                          animation: _rotateController.value,
                          pulseValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Central trading hub with pulsing animation - LAYER 2 (MIDDLE)
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 30),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.5 + 0.3 * _pulseController.value),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3 + 0.2 * _pulseController.value),
                            blurRadius: 20 + 10 * _pulseController.value,
                            spreadRadius: 2 + 2 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            color: Colors.deepPurple.shade100,
                            size: isMobile ? 28 : 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Trading Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Interactive energy nodes - LAYER 3 (TOP)
              // Use our updated node positioning that pushes nodes further away from center
              if (isMobile) _buildMobileEnergyNodes() else _buildDesktopEnergyNodes(),
            ],
          ),
        ),
        
        SizedBox(height: isMobile ? 50 : 80),
        
        // Transformation benefits - already handles mobile vs desktop layouts
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return isMobile
                ? _buildMobileTransformationBenefits()
                : _buildDesktopTransformationBenefits();
          },
        ),
      ],
    ),
  );
}

// Add these new methods for mobile and desktop energy nodes
// Updated method for mobile energy nodes
Widget _buildMobileEnergyNodes() {
  final width = MediaQuery.of(context).size.width;
  return Stack(
    // Critical for ensuring tooltips are properly positioned
    clipBehavior: Clip.none,
    children: [
      // Top left node - push further to the left and top
      Positioned(
        top: 20,  // Move higher up
        left: width * 0.05, // Push further left
        child: InteractiveEnergyNode(
          label: 'Residential',
          icon: Icons.home,
          color: Colors.amber,
          description: 'Homes generate and consume energy from renewable sources',
          isMobile: true,
          tooltipDirection: TooltipDirection.right, // Tooltip appears to the right
          zIndex: 5, // Ensure high z-index
        ),
      ),
      
      // Top right node - push further to the right and top
      Positioned(
        top: 20,  // Move higher up
        right: width * 0.05, // Push further right
        child: InteractiveEnergyNode(
          label: 'Solar Array',
          icon: Icons.solar_power,
          color: Colors.orange,
          description: 'Clean energy generation with optimal sun tracking',
          isMobile: true,
          tooltipDirection: TooltipDirection.left, // Tooltip appears to the left
          zIndex: 5, // Ensure high z-index
        ),
      ),
      
      // Bottom left node - push further to the left and bottom
      Positioned(
        bottom: 20, // Move lower down
        left: width * 0.05, // Push further left
        child: InteractiveEnergyNode(
          label: 'Business',
          icon: Icons.business,
          color: Colors.blue.shade300,
          description: 'Commercial entities participate in the energy marketplace',
          isMobile: true,
          tooltipDirection: TooltipDirection.right, // Tooltip appears to the right
          zIndex: 5, // Ensure high z-index
        ),
      ),
      
      // Bottom right node - push further to the right and bottom
      Positioned(
        bottom: 20, // Move lower down
        right: width * 0.05, // Push further right
        child: InteractiveEnergyNode(
          label: 'Energy Storage',
          icon: Icons.battery_charging_full,
          color: Colors.green.shade300,
          description: 'Advanced battery systems store excess energy for peak demand',
          isMobile: true,
          tooltipDirection: TooltipDirection.left, // Tooltip appears to the left
          zIndex: 5, // Ensure high z-index
        ),
      ),
    ],
  );
}

// Updated method for desktop energy nodes
Widget _buildDesktopEnergyNodes() {
  final width = MediaQuery.of(context).size.width;
  return Stack(
    children: [
      Positioned(
        top: 80,
        left: width * 0.15,
        child: InteractiveEnergyNode(
          label: 'Residential',
          icon: Icons.home,
          color: Colors.amber,
          description: 'Homes generate and consume energy from renewable sources',
          tooltipDirection: TooltipDirection.bottomRight,
        ),
      ),
      
      Positioned(
        top: 80,
        right: width * 0.15,
        child: InteractiveEnergyNode(
          label: 'Solar Array',
          icon: Icons.solar_power,
          color: Colors.orange,
          description: 'Clean energy generation with optimal sun tracking',
          tooltipDirection: TooltipDirection.bottomLeft,
        ),
      ),
      
      Positioned(
        bottom: 140,
        left: width * 0.15,
        child: InteractiveEnergyNode(
          label: 'Business',
          icon: Icons.business,
          color: Colors.blue.shade300,
          description: 'Commercial entities participate in the energy marketplace',
          tooltipDirection: TooltipDirection.topRight,
        ),
      ),
      
      Positioned(
        bottom: 140,
        right: width * 0.15,
        child: InteractiveEnergyNode(
          label: 'Energy Storage',
          icon: Icons.battery_charging_full,
          color: Colors.green.shade300,
          description: 'Advanced battery systems store excess energy for peak demand',
          tooltipDirection: TooltipDirection.topLeft,
        ),
      ),
    ],
  );
}

  Widget _buildMobileTransformationBenefits() {
    final benefits = _getTransformationBenefits();
    return Column(
      children: [
        for (int i = 0; i < benefits.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < benefits.length - 1 ? 20.0 : 0.0),
            child: FadeSlideAnimation(
              delay: Duration(milliseconds: 300 + (i * 100)),
              direction: SlideDirection.fromBottom,
              child: _buildBenefitCard(benefits[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTransformationBenefits() {
    final benefits = _getTransformationBenefits();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < benefits.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? 15.0 : 0.0,
                right: i < benefits.length - 1 ? 15.0 : 0.0,
              ),
              child: FadeSlideAnimation(
                delay: Duration(milliseconds: 300 + (i * 100)),
                direction: SlideDirection.fromBottom,
                child: _buildBenefitCard(benefits[i]),
              ),
            ),
          ),
      ],
    );
  }

  List<BenefitData> _getTransformationBenefits() {
    return [
      BenefitData(
        icon: Icons.power,
        title: 'Energy Independence',
        description: 'Break free from centralized grid limitations with resilient, local energy production',
      ),
      BenefitData(
        icon: Icons.savings,
        title: 'Cost Reduction',
        description: 'Lower energy expenses through direct trading and elimination of middlemen',
      ),
      BenefitData(
        icon: Icons.eco,
        title: 'Sustainability',
        description: 'Promote renewable energy adoption and reduce reliance on fossil fuels',
      ),
    ];
  }

  Widget _buildBenefitCard(BenefitData benefit) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.7),
                  Colors.deepPurple.withOpacity(0.0),
                ],
                stops: const [0.2, 1.0],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              benefit.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            benefit.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            benefit.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTechnologySection() {
    return Container(
      key: _technologyKey,
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 32),
      child: Column(
        children: [
          // Section title with animated reveal
          const RevealText(
            'Advanced Technology Stack',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Description with animated fade in
          const FadeSlideAnimation(
            delay: Duration(milliseconds: 300),
            child: SizedBox(
              width: 800,
              child: Text(
                'PIONEER integrates cutting-edge technologies into a seamless ecosystem. Blockchain, AI, and IoT work together to create a secure, efficient, and autonomous energy trading platform.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                  height: 1.6,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 100),
          
          // 3D Tech stack visualization
          SizedBox(
            height: 500,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background energy field
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: TechFieldPainter(
                          animation: _rotateController.value,
                        ),
                      );
                    },
                  ),
                ),
                
                // Center core tech hub
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.5 + 0.3 * _pulseController.value),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3 + 0.2 * _pulseController.value),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hub,
                              color: Colors.white,
                              size: 40 + 4 * _pulseController.value,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'PIONEER Core',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Orbiting technology items
                ...List.generate(8, (index) {
                  final techItem = _getTechItems()[index];
                  final angle = (index / 8) * 2 * math.pi;
                  
                  return AnimatedBuilder(
                    animation: _orbitController,
                    builder: (context, child) {
                      // Calculate position on orbit
                      final orbitRadius = 220.0;
                      final adjustedAngle = angle + _orbitController.value * 2 * math.pi * (index % 2 == 0 ? 1 : -0.7);
                      
                      final position = Offset(
                        orbitRadius * math.cos(adjustedAngle),
                        orbitRadius * math.sin(adjustedAngle),
                      );
                      
                      return Positioned(
                        left: MediaQuery.of(context).size.width / 2 - 60 + position.dx,
                        top: 250 - 60 + position.dy,
                        child: TechOrbitalItem(
                          icon: techItem.icon,
                          label: techItem.label,
                          color: techItem.color,
                          description: techItem.description,
                          pulseController: _pulseController,
                        ),
                      );
                    },
                  );
                }),
                
                // Connection lines between core and orbitals
                AnimatedBuilder(
                  animation: Listenable.merge([_orbitController, _waveController]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 500),
                      painter: OrbitalConnectionsPainter(
                        orbitController: _orbitController.value,
                        waveController: _waveController.value,
                        techItems: _getTechItems(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 80),
          
          // Technology advantages
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1100;
              
              if (isMobile) {
                return _buildMobileTechAdvantages();
              } else if (isTablet) {
                return _buildTabletTechAdvantages();
              } else {
                return _buildDesktopTechAdvantages();
              }
            },
          ),
        ],
      ),
    );
  }

  List<TechItemData> _getTechItems() {
    return [
      TechItemData(
        icon: Icons.link,
        label: 'Blockchain',
        color: Colors.blue,
        description: 'Secure, transparent transaction ledger for energy trading',
      ),
      TechItemData(
        icon: Icons.psychology,
        label: 'AI Optimization',
        color: Colors.purple,
        description: 'Machine learning algorithms for energy prediction and optimization',
      ),
      TechItemData(
        icon: Icons.devices_other,
        label: 'IoT Network',
        color: Colors.teal,
        description: 'Connected smart devices for real-time monitoring and control',
      ),
      TechItemData(
        icon: Icons.memory,
        label: 'Edge Computing',
        color: Colors.deepOrange,
        description: 'Distributed processing for low-latency operation',
      ),
      TechItemData(
        icon: Icons.security,
        label: 'Cryptography',
        color: Colors.red,
        description: 'Military-grade security protocols protect all transactions',
      ),
      TechItemData(
        icon: Icons.account_balance_wallet,
        label: 'Smart Contracts',
        color: Colors.green,
        description: 'Self-executing agreements for automatic energy trading',
      ),
      TechItemData(
        icon: Icons.storage,
        label: 'Distributed Storage',
        color: Colors.amber,
        description: 'Resilient data management across the network',
      ),
      TechItemData(
        icon: Icons.api,
        label: 'Microservices',
        color: Colors.indigo,
        description: 'Modular architecture for scalability and robustness',
      ),
    ];
  }

  Widget _buildMobileTechAdvantages() {
    final advantages = _getTechAdvantages();
    return Column(
      children: [
        for (int i = 0; i < advantages.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < advantages.length - 1 ? 20.0 : 0.0),
            child: FadeSlideAnimation(
              delay: Duration(milliseconds: 300 + (i * 100)),
              direction: SlideDirection.fromBottom,
              child: _buildAdvantageCard(advantages[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletTechAdvantages() {
    final advantages = _getTechAdvantages();
    return Column(
      children: [
        for (int i = 0; i < advantages.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < advantages.length ? 20.0 : 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FadeSlideAnimation(
                    delay: Duration(milliseconds: 300 + (i * 100)),
                    direction: SlideDirection.fromBottom,
                    child: _buildAdvantageCard(advantages[i]),
                  ),
                ),
                const SizedBox(width: 20),
                if (i + 1 < advantages.length)
                  Expanded(
                    child: FadeSlideAnimation(
                      delay: Duration(milliseconds: 300 + ((i + 1) * 100)),
                      direction: SlideDirection.fromBottom,
                      child: _buildAdvantageCard(advantages[i + 1]),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTechAdvantages() {
    final advantages = _getTechAdvantages();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < advantages.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? 15.0 : 0.0,
                right: i < advantages.length - 1 ? 15.0 : 0.0,
              ),
              child: FadeSlideAnimation(
                delay: Duration(milliseconds: 300 + (i * 100)),
                direction: SlideDirection.fromBottom,
                child: _buildAdvantageCard(advantages[i]),
              ),
            ),
          ),
      ],
    );
  }

  List<AdvantageData> _getTechAdvantages() {
    return [
      AdvantageData(
        icon: Icons.verified_user,
        title: 'Unhackable Security',
        description: 'Blockchain verification ensures tamper-proof transactions',
      ),
      AdvantageData(
        icon: Icons.speed,
        title: 'Real-time Processing',
        description: 'Near-instantaneous energy trading and settlement',
      ),
      AdvantageData(
        icon: Icons.trending_up,
        title: 'Predictive Analytics',
        description: 'AI forecasts energy needs and optimizes grid stability',
      ),
      AdvantageData(
        icon: Icons.device_hub,
        title: 'Seamless Integration',
        description: 'Works with existing infrastructure and renewable sources',
      ),
    ];
  }

  Widget _buildAdvantageCard(AdvantageData advantage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.7),
                  Colors.deepPurple.withOpacity(0.0),
                ],
                stops: const [0.2, 1.0],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              advantage.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            advantage.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            advantage.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFeaturesSection() {
    return Container(
      key: _featuresKey,
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 50,
            spreadRadius: -10,
            offset: const Offset(0, -30),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section title with animated reveal
          const RevealText(
            'Revolutionary Features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Description with animated fade in
          const FadeSlideAnimation(
            delay: Duration(milliseconds: 300),
            child: SizedBox(
              width: 800,
              child: Text(
                'PIONEER offers a comprehensive suite of futuristic features that redefine how energy is managed, traded, and optimized in decentralized networks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                  height: 1.6,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 100),
          
          // Interactive Feature Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1100;
              
              if (isMobile) {
                return _buildMobileFeatureCards();
              } else if (isTablet) {
                return _buildTabletFeatureCards();
              } else {
                return _buildDesktopFeatureCards();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureCards() {
    final features = _getFeatures();
    return Column(
      children: [
        for (int i = 0; i < features.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < features.length - 1 ? 30.0 : 0.0),
            child: FadeSlideAnimation(
              delay: Duration(milliseconds: 300 + (i * 150)),
              direction: SlideDirection.fromBottom,
              child: _buildInteractiveFeatureCard(features[i], i),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletFeatureCards() {
    final features = _getFeatures();
    return Column(
      children: [
        for (int i = 0; i < features.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < features.length ? 30.0 : 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FadeSlideAnimation(
                    delay: Duration(milliseconds: 300 + (i * 150)),
                    direction: SlideDirection.fromBottom,
                    child: _buildInteractiveFeatureCard(features[i], i),
                  ),
                ),
                const SizedBox(width: 30),
                if (i + 1 < features.length)
                  Expanded(
                    child: FadeSlideAnimation(
                      delay: Duration(milliseconds: 300 + ((i + 1) * 150)),
                      direction: SlideDirection.fromBottom,
                      child: _buildInteractiveFeatureCard(features[i + 1], i + 1),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopFeatureCards() {
    final features = _getFeatures();
    return Column(
      children: [
        for (int row = 0; row < 2; row++)
          Padding(
            padding: EdgeInsets.only(bottom: row < 1 ? 30.0 : 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int col = 0; col < 3; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: col > 0 ? 15.0 : 0.0,
                        right: col < 2 ? 15.0 : 0.0,
                      ),
                      child: FadeSlideAnimation(
                        delay: Duration(milliseconds: 300 + ((row * 3 + col) * 150)),
                        direction: SlideDirection.fromBottom,
                        child: _buildInteractiveFeatureCard(
                          features[row * 3 + col],
                          row * 3 + col,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<FeatureData> _getFeatures() {
    return [
      FeatureData(
        icon: Icons.swap_horiz,
        title: 'P2P Energy Trading',
        description: 'Trade excess energy directly with neighbors through secure, automated smart contracts',
        stats: [
          FeatureStat(value: 'High', label: 'Efficiency'),
          FeatureStat(value: 'Great', label: 'Cost Reduction'),
        ],
      ),
      FeatureData(
        icon: Icons.timeline,
        title: 'Real-time Monitoring',
        description: 'Monitor energy production, consumption, and market activity with millisecond precision',
        stats: [
          FeatureStat(value: 'Low', label: 'Response Time'),
          FeatureStat(value: 'High', label: 'Accuracy'),
        ],
      ),
      FeatureData(
        icon: Icons.auto_graph,
        title: 'AI Predictions',
        description: 'Advanced neural networks predict energy needs and optimize trading strategies',
        stats: [
          FeatureStat(value: 'High', label: 'Accuracy'),
          FeatureStat(value: 'Increased', label: 'Efficiency Gain'),
        ],
      ),
      FeatureData(
        icon: Icons.security,
        title: 'Military-grade Security',
        description: 'End-to-end encryption and blockchain verification protect all transactions',
        stats: [
          FeatureStat(value: 'Fortified', label: 'Encryption'),
          FeatureStat(value: 'No', label: 'Breaches'),
        ],
      ),
      FeatureData(
        icon: Icons.currency_exchange,
        title: 'Dynamic Pricing',
        description: 'Market-based pricing engine that adapts to real-time supply and demand conditions',
        stats: [
          FeatureStat(value: 'Real-time', label: 'Market Updates'),
          FeatureStat(value: 'Decreased', label: 'Price Volatility'),
        ],
      ),
      FeatureData(
        icon: Icons.chat,
        title: 'Negotiation Chat Support',
        description: 'Allows you to chat with other uses to create offers, or negotiate prices',
        stats: [
          FeatureStat(value: 'Increased', label: 'Efficiency'),
          FeatureStat(value: 'More', label: 'Versatility'),
        ],
      ),
    ];
  }

  Widget _buildInteractiveFeatureCard(FeatureData feature, int index) {
    return StatefulBuilder(
      builder: (context, setState) {
        final isHovered = _hoveredFeature == index;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredFeature = index),
          onExit: (_) => setState(() => _hoveredFeature = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            height: 300,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(isHovered ? 0.5 : 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHovered 
                    ? Colors.deepPurple.withOpacity(0.7)
                    : Colors.deepPurple.withOpacity(0.2),
                width: isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered
                      ? Colors.deepPurple.withOpacity(0.3)
                      : Colors.deepPurple.withOpacity(0.1),
                  blurRadius: isHovered ? 30 : 20,
                  spreadRadius: isHovered ? 2 : -5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with glowing effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHovered 
                        ? Colors.deepPurple.withOpacity(0.3)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    feature.icon,
                    color: isHovered ? Colors.white : Colors.deepPurple.shade200,
                    size: 36,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title with animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isHovered ? Colors.white : Colors.white.withOpacity(0.9),
                  ),
                  child: Text(feature.title),
                                ),
                
                const SizedBox(height: 15),
                
                // Description
                Expanded(
                  child: Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isHovered ? Colors.white.withOpacity(0.9) : Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
                
                // Stats that appear on hover
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  height: isHovered ? 60 : 0,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: feature.stats.map((stat) => Column(
                          children: [
                            Text(
                              stat.value,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              stat.label,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactSection() {
  final isMobile = Responsive.isMobile(context);
  final isTablet = Responsive.isTablet(context);
  
  return Container(
    key: _contactKey,
    padding: EdgeInsets.symmetric(
      vertical: isMobile ? 70 : (isTablet ? 90 : 120),
      horizontal: isMobile ? 16 : 32
    ),
    child: Column(
      children: [
        // Section title with animated reveal
        RevealText(
          'Connect With Us',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, isMobile ? 32 : 42),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        
        SizedBox(height: isMobile ? 30 : 40),
        
        // Description with animated fade in
        FadeSlideAnimation(
          delay: const Duration(milliseconds: 300),
          child: SizedBox(
            width: isMobile ? double.infinity : (isTablet ? 600 : 800),
            child: Text(
              'Interested in learning more about PIONEER? Get in touch with our team to discuss how decentralized energy trading can transform your community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, isMobile ? 14 : 18),
                color: Colors.white70,
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ),
        ),
        
        SizedBox(height: isMobile ? 50 : 80),
        
        // Futuristic contact card
        FadeSlideAnimation(
          delay: const Duration(milliseconds: 500),
          child: Container(
            width: isMobile ? double.infinity : (isTablet ? 550 : 650),
            padding: EdgeInsets.all(isMobile ? 30 : 50),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated holographic email button - FIXED FOR MOBILE
                GestureDetector(
                  onTap: _launchEmail,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _rotateController]),
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 30,
                          vertical: isMobile ? 15 : 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.3 + 0.2 * _pulseController.value),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.2 + 0.1 * _pulseController.value),
                              blurRadius: 15 + 5 * _pulseController.value,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: isMobile
                            ? _buildMobileEmailContent()
                            : _buildDesktopEmailContent(),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: isMobile ? 40 : 60),
                
                // About section
                Column(
                  children: [
                    Text(
                      'About Equilux Energy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, isMobile ? 20 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isMobile ? 15 : 20),
                    Text(
                      'We are a team of innovative engineers and energy experts committed to transforming how energy is distributed, traded, and consumed. Our mission is to create a more sustainable, efficient, and equitable energy ecosystem through cutting-edge technology.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, isMobile ? 14 : 16),
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 40 : 60),
                
                // Action button
                GestureDetector(
                  onTap: _launchEmail,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 28 : 36,
                          vertical: isMobile ? 14 : 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.8 + 0.2 * _pulseController.value),
                              Colors.deepPurple.shade900.withOpacity(0.8 + 0.2 * _pulseController.value),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3 + 0.2 * _pulseController.value),
                              blurRadius: 15 + 5 * _pulseController.value,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send,
                              color: Colors.white,
                              size: isMobile ? 16 : 20,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.getFontSize(context, isMobile ? 14 : 16),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: isMobile ? 70 : 100),
        
        // Footer
        FadeSlideAnimation(
          delay: const Duration(milliseconds: 700),
          child: Text(
            '© 2025 Equilux Energy. All rights reserved.',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, isMobile ? 12 : 14),
              color: Colors.white38,
            ),
          ),
        ),
      ],
    ),
  );
}

// Add these methods to handle different layouts for the email section
Widget _buildMobileEmailContent() {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.email_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'equilux.energy.dev@gmail.com',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  );
}

Widget _buildDesktopEmailContent() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.email_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
      const SizedBox(width: 20),
      const Text(
        'equilux.energy.dev@gmail.com',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  );
}
}

// ========== CUSTOM WIDGETS ==========

class FutureText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  
  const FutureText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.deepPurple.shade200,
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade200,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(
          color: Colors.white,
          shadows: [
            const Shadow(
              color: Colors.deepPurple,
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
            const Shadow(
              color: Colors.white,
              blurRadius: 10,
              offset: Offset(0, 0),
            ),
          ],
        ),
        textAlign: textAlign,
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  
  const TypewriterText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _displayedText = '';
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.text.length * 50),
    );
    
    _controller.addListener(() {
      final int newLength = (widget.text.length * _controller.value).round();
      if (newLength != _displayedText.length) {
        setState(() {
          _displayedText = widget.text.substring(0, newLength);
        });
      }
    });
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: _getMainAlignment(),
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _displayedText,
            style: widget.style,
            textAlign: widget.textAlign,
          ),
        ),
        AnimatedOpacity(
          opacity: _controller.isCompleted ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            '|',
            style: widget.style,
          ),
        ),
      ],
    );
  }
  
  MainAxisAlignment _getMainAlignment() {
    switch (widget.textAlign) {
      case TextAlign.center:
        return MainAxisAlignment.center;
      case TextAlign.right:
        return MainAxisAlignment.end;
      case TextAlign.left:
      default:
        return MainAxisAlignment.start;
    }
  }
}

class StaggeredTextAnimation extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  
  const StaggeredTextAnimation({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  State<StaggeredTextAnimation> createState() => _StaggeredTextAnimationState();
}

class _StaggeredTextAnimationState extends State<StaggeredTextAnimation> with TickerProviderStateMixin {
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    final words = widget.text.split(' ');
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: words.length * 100 + 500),
    );
    
    _opacityAnimations = List.generate(
      words.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index / words.length * 0.7,
            (index + 1) / words.length * 0.7,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    
    _slideAnimations = List.generate(
      words.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index / words.length * 0.7,
            (index + 1) / words.length * 0.7,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(' ');
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RichText(
          textAlign: widget.textAlign,
          text: TextSpan(
            style: widget.style,
            children: List.generate(
              words.length,
              (index) {
                return WidgetSpan(
                  child: FadeTransition(
                    opacity: _opacityAnimations[index],
                    child: SlideTransition(
                      position: _slideAnimations[index],
                      child: Padding(
                        padding: EdgeInsets.only(right: index < words.length - 1 ? 4.0 : 0.0),
                        child: Text(
                          words[index],
                          style: widget.style,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class RevealText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  
  const RevealText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
    ).animate(
      onPlay: (controller) => controller.forward(),
    ).fadeIn(
      duration: const Duration(milliseconds: 800),
    ).slideY(
      begin: 0.3,
      end: 0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuint,
    ).shimmer(
      duration: const Duration(milliseconds: 1200),
      color: Colors.white.withOpacity(0.8),
      size: 3,
      delay: const Duration(milliseconds: 800),
    );
  }
}

class FadeSlideAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final SlideDirection direction;
  
  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.direction = SlideDirection.fromBottom,
  });

  @override
  Widget build(BuildContext context) {
    double dx = 0.0;
    double dy = 0.0;
    
    switch (direction) {
      case SlideDirection.fromLeft:
        dx = -0.3;
        break;
      case SlideDirection.fromRight:
        dx = 0.3;
        break;
      case SlideDirection.fromTop:
        dy = -0.3;
        break;
      case SlideDirection.fromBottom:
        dy = 0.3;
        break;
    }
    
    return child.animate(
      onPlay: (controller) => controller.forward(),
    ).fadeIn(
      duration: const Duration(milliseconds: 800),
      delay: delay,
    ).slideX(
      begin: dx,
      end: 0,
      duration: const Duration(milliseconds: 800),
      delay: delay,
      curve: Curves.easeOutQuint,
    ).slideY(
      begin: dy,
      end: 0,
      duration: const Duration(milliseconds: 800),
      delay: delay,
      curve: Curves.easeOutQuint,
    );
  }
}

// Define an enum for tooltip directions
// Expand tooltip directions for more flexibility
enum TooltipDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  left,
  right,
  top,
  bottom,
}

class InteractiveEnergyNode extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final bool isMobile;
  final TooltipDirection tooltipDirection;
  final int zIndex; // Add z-index property
  
  const InteractiveEnergyNode({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    this.isMobile = false,
    this.tooltipDirection = TooltipDirection.bottomRight,
    this.zIndex = 1, // Default z-index
  });

  @override
  State<InteractiveEnergyNode> createState() => _InteractiveEnergyNodeState();
}

class _InteractiveEnergyNodeState extends State<InteractiveEnergyNode> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false; // Track press for mobile
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = widget.isMobile ? 0.8 : 1.0; // Scale for mobile
    
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(60 * size),
        onTap: () {
          // Toggle pressed state for mobile tooltip display
          setState(() {
            _isPressed = !_isPressed;
          });
        },
        onHover: (isHovering) {
          setState(() {
            _isHovered = isHovering;
          });
          if (isHovering) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        },
        child: Container(
          // Set higher Z-index when hovered or pressed
          foregroundDecoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Node
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(20 * size),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withOpacity((_isHovered || _isPressed) ? 0.8 : 0.5),
                          width: (_isHovered || _isPressed) ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity((_isHovered || _isPressed) ? 0.5 : 0.2),
                            blurRadius: (_isHovered || _isPressed) ? 20 : 10,
                            spreadRadius: (_isHovered || _isPressed) ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 30 * size,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12 * size),
                  
                  // Label
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * size,
                      vertical: 6 * size,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: widget.color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 14 * size,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Description tooltip with improved positioning
              if ((_isHovered || _isPressed) && widget.description.isNotEmpty)
                _buildPositionedTooltip(size),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPositionedTooltip(double size) {
    // Calculate position based on tooltip direction
    // Improved positioning to avoid central hub overlap
    switch (widget.tooltipDirection) {
      case TooltipDirection.left:
        return Positioned(
          right: 100 * size, // Push further left
          top: 20 * size,
          child: _buildTooltip(size),
        );
      
      case TooltipDirection.right:
        return Positioned(
          left: 100 * size, // Push further right
          top: 20 * size,
          child: _buildTooltip(size),
        );
      
      case TooltipDirection.top:
        return Positioned(
          bottom: 100 * size, // Push further up
          left: 0,
          child: _buildTooltip(size),
        );
      
      case TooltipDirection.bottom:
        return Positioned(
          top: 100 * size, // Push further down
          left: 0,
          child: _buildTooltip(size),
        );
        
      case TooltipDirection.topLeft:
        return Positioned(
          bottom: 90 * size,
          right: 20 * size,
          child: _buildTooltip(size),
        );
        
      case TooltipDirection.topRight:
        return Positioned(
          bottom: 90 * size,
          left: 20 * size,
          child: _buildTooltip(size),
        );
        
      case TooltipDirection.bottomLeft:
        return Positioned(
          top: 90 * size,
          right: 20 * size,
          child: _buildTooltip(size),
        );
        
      case TooltipDirection.bottomRight:
      default:
        return Positioned(
          top: 90 * size,
          left: 20 * size,
          child: _buildTooltip(size),
        );
    }
  }
  
  Widget _buildTooltip(double size) {
    // Higher elevation tooltip with better visibility
    return Material(
      elevation: 8, // Add elevation to ensure it appears above other elements
      color: Colors.transparent,
      child: AnimatedOpacity(
        opacity: (_isHovered || _isPressed) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.isMobile ? 150 : 200,
            minHeight: 0,
          ),
          // Improved tooltip styling for visibility
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.color.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
          child: Text(
            widget.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: widget.isMobile ? 10 : 12,
            ),
          ),
        ),
      ),
    );
  }
}

class TechOrbitalItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String description;
  final AnimationController pulseController;
  final bool isMobile;
  
  const TechOrbitalItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
    required this.pulseController,
    this.isMobile = false,
  });

  @override
  State<TechOrbitalItem> createState() => _TechOrbitalItemState();
}

class _TechOrbitalItemState extends State<TechOrbitalItem> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final size = widget.isMobile ? 0.8 : 1.0; // Scale for mobile
    
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node
          AnimatedBuilder(
            animation: widget.pulseController,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(16 * size),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withOpacity(_isHovered ? 0.8 : 0.5 + 0.3 * widget.pulseController.value),
                    width: _isHovered ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(_isHovered ? 0.5 : 0.2 + 0.2 * widget.pulseController.value),
                      blurRadius: _isHovered ? 20 : 10 + 5 * widget.pulseController.value,
                      spreadRadius: _isHovered ? 3 : 1 + widget.pulseController.value,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 24 * size,
                ),
              );
            },
          ),
          
          SizedBox(height: 10 * size),
          
          // Label
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * size,
              vertical: 5 * size,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w500,
                fontSize: 12 * size,
              ),
            ),
          ),
          
          // Description tooltip - FIXED for mobile
          AnimatedOpacity(
            opacity: _isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_isHovered,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: widget.isMobile ? 140 : 180,
                  minHeight: 0,
                  maxHeight: _isHovered ? double.infinity : 0,
                ),
                margin: EdgeInsets.only(top: 8 * size),
                padding: EdgeInsets.all(_isHovered ? (widget.isMobile ? 8 : 10) : 0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: _isHovered ? Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: widget.isMobile ? 10 : 12,
                  ),
                ) : const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== PAINTERS ==========

class NeospacePlasmaBackgroundPainter extends CustomPainter {
  final double animation;

  NeospacePlasmaBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Deep space background gradient
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0D0221),
        const Color(0xFF1A1A40),
        const Color(0xFF270082),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(animation * math.pi * 2),
    ).createShader(rect);
    
    final backgroundPaint = Paint()..shader = backgroundGradient;
    canvas.drawRect(rect, backgroundPaint);
    
    // Plasma effect blobs
    _drawPlasmaBlobs(canvas, size);
    
    // Nebula overlay
    _drawNebula(canvas, size);
    
    // Starfield overlay
    _drawStarfield(canvas, size);
  }
  
  void _drawPlasmaBlobs(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistency
    
    for (int i = 0; i < 5; i++) {
      final centerX = size.width * (0.2 + 0.6 * random.nextDouble());
      final centerY = size.height * (0.2 + 0.6 * random.nextDouble());
      final radius = math.min(size.width, size.height) * (0.1 + 0.2 * random.nextDouble());
      
      // Animated positions
      final dx = math.sin(animation * math.pi * 2 + i) * radius * 0.2;
      final dy = math.cos(animation * math.pi * 2 + i * 0.5) * radius * 0.2;
      
      final center = Offset(centerX + dx, centerY + dy);
      
      // Determine blob color based on position
      final hue = (i * 60) % 360;
      final color = HSLColor.fromAHSL(
        0.15 + 0.05 * math.sin(animation * math.pi * 2 + i),
        hue.toDouble(),
        0.5,
        0.3,
      ).toColor();
      
      final blobPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: center,
          radius: radius,
        ));
      
      canvas.drawCircle(center, radius, blobPaint);
    }
  }
  
  void _drawNebula(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.sin(animation * math.pi * 2) * 0.2,
          math.cos(animation * math.pi * 2) * 0.2,
        ),
        radius: 1.0,
        colors: [
          Colors.deepPurple.withOpacity(0.0),
          Colors.deepPurple.withOpacity(0.05),
          Colors.deepPurple.withOpacity(0.1),
          Colors.deepPurple.withOpacity(0.05),
          Colors.deepPurple.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.screen;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), cloudPaint);
  }
  
  void _drawStarfield(Canvas canvas, Size size) {
    final random = math.Random(23); // Different seed for stars
    
    // Draw stars
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;
      
      // Star twinkle effect
      final brightness = 0.5 + 0.5 * math.sin(animation * math.pi * 10 + i * 5);
      
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.5 + 0.5 * brightness)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius * brightness, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NeospacePlasmaBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class EnergyGridPainter extends CustomPainter {
  final double animation;

  EnergyGridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final gridSpacing = 40.0;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x < size.width; x += 5) {
        final waveHeight = 3.0 * math.sin(x / 100 + animation * math.pi * 2 + y / 50);
        path.lineTo(x, y + waveHeight);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      final path = Path();
      path.moveTo(x, 0);
      
      for (double y = 0; y < size.height; y += 5) {
        final waveOffset = 3.0 * math.sin(y / 100 + animation * math.pi * 2 + x / 50);
        path.lineTo(x + waveOffset, y);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw glowing nodes at intersections
    final random = math.Random(42);
    final nodePaint = Paint()
      ..style = PaintingStyle.fill;
    
    for (double x = gridSpacing; x < size.width; x += gridSpacing) {
      for (double y = gridSpacing; y < size.height; y += gridSpacing) {
        if (random.nextDouble() > 0.7) {
          final pulseValue = (math.sin(animation * math.pi * 2 + x / 50 + y / 50) + 1) / 2;
          
          nodePaint.color = Colors.deepPurple.withOpacity(0.1 + 0.2 * pulseValue);
          canvas.drawCircle(Offset(x, y), 2.0 + pulseValue * 1.0, nodePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant EnergyGridPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class HolographicParticlesPainter extends CustomPainter {
  final double animation;
  final Offset? mousePosition;

  HolographicParticlesPainter({
    required this.animation,
    this.mousePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    // Generate particles
    for (int i = 0; i < 150; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final radius = 1.0 + random.nextDouble() * 2.0;
      
      // Animated position
      final dx = math.sin(animation * math.pi * 2 + i) * 5.0;
      final dy = math.cos(animation * math.pi * 2 + i * 0.5) * 5.0;
      
      var x = baseX + dx;
      var y = baseY + dy;
      
      // Add mouse interaction if mouse position is available
      if (mousePosition != null) {
        final distance = math.sqrt(
          math.pow(x - mousePosition!.dx, 2) + 
          math.pow(y - mousePosition!.dy, 2)
        );
        
        if (distance < 150) {
          final repelFactor = (150 - distance) / 150 * 40;
          final angle = math.atan2(y - mousePosition!.dy, x - mousePosition!.dx);
          
          x += math.cos(angle) * repelFactor;
          y += math.sin(angle) * repelFactor;
        }
      }
      
      // Color based on position
      final hue = (x / size.width * 360) % 360;
      final brightness = 0.5 + 0.5 * math.sin(animation * math.pi * 2 + i);
      
      final color = HSLColor.fromAHSL(
        0.5 + 0.2 * brightness,
        hue,
        0.7,
        0.5,
      ).toColor();
      
      final particlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius * brightness, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HolographicParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.mousePosition != mousePosition;
  }
}

class EnergyFieldPainter extends CustomPainter {
  final double rotationValue;
  final double pulseValue;

  EnergyFieldPainter({
    required this.rotationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw concentric energy rings
    for (int i = 0; i < 5; i++) {
      final radius = 100.0 + i * 50.0 + pulseValue * 20.0;
      
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.deepPurple.withOpacity(0.3 - i * 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawCircle(center, radius, ringPaint);
    }
    
    // Draw energy field lines
    for (int i = 0; i < 36; i++) {
      final angle = (i / 36) * 2 * math.pi + rotationValue * math.pi * 2;
      final innerRadius = 80.0;
      final outerRadius = 350.0 + pulseValue * 30.0;
      
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.deepPurple.withOpacity(0.2 + 0.1 * math.sin(angle * 3 + rotationValue * math.pi * 2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      final path = Path();
      path.moveTo(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      
      // Curved energy line
      final controlPoint1 = Offset(
        center.dx + (innerRadius + outerRadius) / 3 * math.cos(angle + 0.1),
        center.dy + (innerRadius + outerRadius) / 3 * math.sin(angle + 0.1),
      );
      
      final controlPoint2 = Offset(
        center.dx + (innerRadius + outerRadius) * 2 / 3 * math.cos(angle - 0.1),
        center.dy + (innerRadius + outerRadius) * 2 / 3 * math.sin(angle - 0.1),
      );
      
      final endPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        endPoint.dx, endPoint.dy,
      );
      
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant EnergyFieldPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue || 
           oldDelegate.pulseValue != pulseValue;
  }
}

class OrbitalEnergyPainter extends CustomPainter {
  final double animation;

  OrbitalEnergyPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw orbiting energy spheres
    for (int i = 0; i < 5; i++) {
      final orbitRadius = 60.0 + i * 40.0;
      final sphereRadius = 5.0 + i * 1.5;
      final speed = 1.0 - i * 0.15;
      final angle = animation * math.pi * 2 * speed + i * (math.pi / 3);
      
      final sphereCenter = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );
      
      // Glow effect
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.7),
            Colors.deepPurple.withOpacity(0.5),
            Colors.deepPurple.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: sphereCenter,
          radius: sphereRadius * 3,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      
      // Core
      final corePaint = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(sphereCenter, sphereRadius * 3, glowPaint);
      canvas.drawCircle(sphereCenter, sphereRadius, corePaint);
      
      // Draw orbit path
      final orbitPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.deepPurple.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      
      canvas.drawCircle(center, orbitRadius, orbitPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitalEnergyPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class EnergyFlowPainter extends CustomPainter {
  final double animation;
  final double pulseValue;

  EnergyFlowPainter({
    required this.animation,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 250);
    
    // Background grid
    _drawNetworkGrid(canvas, size);
    
    // Energy flow paths
    _drawEnergyFlowPaths(canvas, size, center);
    
    // Glowing nodes
    _drawNodes(canvas, size, center);
  }
  
  void _drawNetworkGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.teal.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    const gridSpacing = 30.0;
    
    // Draw horizontal grid lines with wave effect
    for (double y = 0; y < size.height; y += gridSpacing) {
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x < size.width; x += 5) {
        final waveHeight = 2.0 * math.sin(x / 100 + animation * math.pi * 2 + y / 50);
        path.lineTo(x, y + waveHeight);
      }
      
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw vertical grid lines with wave effect
    for (double x = 0; x < size.width; x += gridSpacing) {
      final path = Path();
      path.moveTo(x, 0);
      
      for (double y = 0; y < size.height; y += 5) {
        final waveOffset = 2.0 * math.sin(y / 100 + animation * math.pi * 2 + x / 50);
        path.lineTo(x + waveOffset, y);
      }
      
      canvas.drawPath(path, gridPaint);
    }
  }
  
  void _drawEnergyFlowPaths(Canvas canvas, Size size, Offset center) {
    // Define node positions
    final nodePositions = [
      Offset(size.width * 0.15, 80),                // Top left
      Offset(size.width * 0.85, 120),               // Top right
      Offset(size.width * 0.2, size.height - 120),  // Bottom left
      Offset(size.width * 0.8, size.height - 140),  // Bottom right
    ];
    
    // Draw flow paths between nodes and center
    for (final nodePos in nodePositions) {
      final pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.teal.withOpacity(0.3 + 0.2 * pulseValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      final path = Path();
      
      // Calculate control points for a curved path
      final midPoint = Offset(
        (nodePos.dx + center.dx) / 2,
        (nodePos.dy + center.dy) / 2,
      );
      
      final controlPoint1 = Offset(
        midPoint.dx + (nodePos.dy - center.dy) * 0.2,
        midPoint.dy - (nodePos.dx - center.dx) * 0.2,
      );
      
      final controlPoint2 = Offset(
        midPoint.dx - (nodePos.dy - center.dy) * 0.2,
        midPoint.dy + (nodePos.dx - center.dx) * 0.2,
      );
      
      path.moveTo(nodePos.dx, nodePos.dy);
      path.quadraticBezierTo(
        nodePos.dx == center.dx ? controlPoint1.dx : (nodePos.dx + center.dx) / 2,
        nodePos.dy == center.dy ? controlPoint1.dy : (nodePos.dy + center.dy) / 2,
        center.dx,
        center.dy,
      );
      
      canvas.drawPath(path, pathPaint);
      
      // Draw energy pulses along the path
      _drawEnergyPulses(canvas, nodePos, center, controlPoint1);
    }
  }
  
  void _drawEnergyPulses(Canvas canvas, Offset start, Offset end, Offset control) {
    // Define multiple pulses along each path
    for (int i = 0; i < 3; i++) {
      final t = ((animation * 3) + (i / 3)) % 1.0;
      
      // Quadratic bezier point calculation
      final mt = 1 - t;
      final pt = Offset(
        mt * mt * start.dx + 2 * mt * t * control.dx + t * t * end.dx,
        mt * mt * start.dy + 2 * mt * t * control.dy + t * t * end.dy,
      );
      
      final pulsePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.teal.withOpacity(0.7 * (1 - math.pow(t - 0.5, 2) * 2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      
      canvas.drawCircle(pt, 3.0 + 2.0 * pulseValue, pulsePaint);
    }
  }
  
  void _drawNodes(Canvas canvas, Size size, Offset center) {
    final random = math.Random(42);
    
    // Draw small glowing nodes throughout the grid
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      final nodePulse = 0.5 + 0.5 * math.sin(animation * math.pi * 2 + x / 50 + y / 50);
      
      final nodePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.teal.withOpacity(0.1 + 0.2 * nodePulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(Offset(x, y), 2.0 + nodePulse * 2.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant EnergyFlowPainter oldDelegate) {
    return oldDelegate.animation != animation || 
           oldDelegate.pulseValue != pulseValue;
  }
}

class EnergyPulsePainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Offset currentPoint;
  final Color color;
  final bool directionToHub;

  EnergyPulsePainter({
    required this.startPoint,
    required this.endPoint,
    required this.currentPoint,
    required this.color,
    required this.directionToHub,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the path
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color.withOpacity(0.4);
    
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(endPoint.dx, endPoint.dy);
    
    canvas.drawPath(path, pathPaint);
    
    // Draw the pulse
    final pulsePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    
    canvas.drawCircle(currentPoint, 4.0, pulsePaint);
    
    // Draw direction arrow
    _drawArrow(canvas, currentPoint);
  }
  
  void _drawArrow(Canvas canvas, Offset position) {
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    
    // Calculate direction vector
    final dx = endPoint.dx - startPoint.dx;
    final dy = endPoint.dy - startPoint.dy;
    final angle = math.atan2(dy, dx) + (directionToHub ? math.pi : 0);
    
    // Arrow points
    final point1 = Offset(
      position.dx + 4 * math.cos(angle),
      position.dy + 4 * math.sin(angle),
    );
    
    final point2 = Offset(
      position.dx + 4 * math.cos(angle + 2.5),
      position.dy + 4 * math.sin(angle + 2.5),
    );
    
    final point3 = Offset(
      position.dx + 4 * math.cos(angle - 2.5),
      position.dy + 4 * math.sin(angle - 2.5),
    );
    
    final arrowPath = Path();
    arrowPath.moveTo(point1.dx, point1.dy);
    arrowPath.lineTo(point2.dx, point2.dy);
    arrowPath.lineTo(point3.dx, point3.dy);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant EnergyPulsePainter oldDelegate) {
    return oldDelegate.currentPoint != currentPoint ||
           oldDelegate.color != color;
  }
}

class TechFieldPainter extends CustomPainter {
  final double animation;

  TechFieldPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 250);
    
    // Draw concentric circles
    for (int i = 0; i < 4; i++) {
      final radius = 100.0 + i * 50.0;
      
      final circlePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.deepPurple.withOpacity(0.2 - i * 0.05);
      
      canvas.drawCircle(center, radius, circlePaint);
    }
    
    // Draw radial lines
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * math.pi + animation * math.pi;
      
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.deepPurple.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
      
      final path = Path();
      path.moveTo(
        center.dx + 80 * math.cos(angle),
        center.dy + 80 * math.sin(angle),
      );
      
      path.lineTo(
        center.dx + 250 * math.cos(angle),
        center.dy + 250 * math.sin(angle),
      );
      
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TechFieldPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class OrbitalConnectionsPainter extends CustomPainter {
  final double orbitController;
  final double waveController;
  final List<TechItemData> techItems;

  OrbitalConnectionsPainter({
    required this.orbitController,
    required this.waveController,
    required this.techItems,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 250);
    
    // Draw connections between core and orbitals
    for (int i = 0; i < techItems.length; i++) {
      final angle = (i / techItems.length) * 2 * math.pi;
      final adjustedAngle = angle + orbitController * 2 * math.pi * (i % 2 == 0 ? 1 : -0.7);
      
      final orbitRadius = 220.0;
      final position = Offset(
        orbitRadius * math.cos(adjustedAngle),
        orbitRadius * math.sin(adjustedAngle),
      );
      
      final orbitalCenter = Offset(
        center.dx + position.dx,
        center.dy + position.dy,
      );
      
      // Draw connection line with data flow animation
      _drawDataFlowLine(canvas, center, orbitalCenter, techItems[i].color, i);
    }
  }
  
  void _drawDataFlowLine(Canvas canvas, Offset center, Offset orbitalCenter, Color color, int index) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withOpacity(0.3);
    
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(orbitalCenter.dx, orbitalCenter.dy);
    
    canvas.drawPath(path, linePaint);
    
    // Draw data packet animations along the line
    for (int j = 0; j < 3; j++) {
      final t = ((waveController + j / 3 + index / techItems.length) % 1.0);
      
      final packetCenter = Offset(
        center.dx + (orbitalCenter.dx - center.dx) * t,
        center.dy + (orbitalCenter.dy - center.dy) * t,
      );
      
      final packetPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.7 * (1 - 4 * math.pow(t - 0.5, 2)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawCircle(packetCenter, 3.0, packetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitalConnectionsPainter oldDelegate) {
    return oldDelegate.orbitController != orbitController || 
           oldDelegate.waveController != waveController;
  }
}

// ========== DATA MODELS ==========

enum SlideDirection {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}

class BenefitData {
  final IconData icon;
  final String title;
  final String description;
  
  BenefitData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class TechItemData {
  final IconData icon;
  final String label;
  final Color color;
  final String description;
  
  TechItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
  });
}

class AdvantageData {
  final IconData icon;
  final String title;
  final String description;
  
  AdvantageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final List<FeatureStat> stats;
  
  FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.stats,
  });
}

class FeatureStat {
  final String value;
  final String label;
  
  FeatureStat({
    required this.value,
    required this.label,
  });
}

// Add this helper class at the bottom of your file
class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 650;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 650 && MediaQuery.of(context).size.width < 1100;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100;
  
  static double getWidth(BuildContext context) => MediaQuery.of(context).size.width;
  
  static double getFontSize(BuildContext context, double desktopSize) {
    if (isMobile(context)) {
      return math.max(desktopSize * 0.7, 10.0); // At least 10px
    } else if (isTablet(context)) {
      return math.max(desktopSize * 0.85, 12.0); // At least 12px
    }
    return desktopSize;
  }
  
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
  }
}

