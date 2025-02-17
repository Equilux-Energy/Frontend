import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import '../Widgets/gradient_wave_background.dart';

/// This widget uses VisibilityDetector to monitor when its child scrolls into view.
/// When visible, after an optional delay it animates the child into view using
/// AnimatedOpacity, AnimatedSlide, and (optionally) AnimatedScale. When off-screen,
/// it immediately reverses the animations. The child’s space is maintained even when invisible.
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
  // _animate indicates whether the animated properties should be "in" (1.0) or "out" (0.0).
  bool _animate = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (VisibilityInfo info) {
        bool nowVisible = info.visibleFraction > 0;
        // When the widget becomes visible, trigger the "in" animation after the delay.
        if (nowVisible && !_animate) {
          Future.delayed(widget.delay, () {
            if (mounted && info.visibleFraction > 0) {
              setState(() {
                _animate = true;
              });
            }
          });
        }
        // When the widget is off screen, immediately reverse the animation.
        if (!nowVisible && _animate) {
          setState(() {
            _animate = false;
          });
        }
      },
      // Wrap in Visibility with maintain* properties so that the layout size remains constant.
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
                  // When not animated in, shift by the specified offsets.
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
  double _appBarOpacity = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    setState(() {
      _appBarOpacity = (_scrollController.offset / 100).clamp(0, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const FluidGradientBackground(),
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(),
                _buildProblemSection(),
                _buildFeaturesSection(),
                _buildTechStackSection(),
                _buildHowItWorks(),
                _buildBenefitsSection(),
                _buildCTASection(),
                _buildComplianceSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'PIONEER',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: false,
      backgroundColor: Colors.black.withOpacity(_appBarOpacity * 0.8),
      elevation: 0,
      actions: [
        _buildNavButton('About', '/about'),
        _buildNavButton('Features', '/features'),
        _buildNavButton('Contact', '/contact'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () => context.push('/signin'),
            child: const Text('Get Started', style: TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(String text, String route) {
    return TextButton(
      onPressed: () => context.push(route),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimateOnVisibility(
                key: const Key('hero-title'),
                slideYBegin: 0.2,
                child: const Text(
                  'PIONEER',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimateOnVisibility(
                key: const Key('hero-subtitle'),
                delay: Duration(milliseconds: 200),
                slideYBegin: 0.2,
                child: const Text(
                  'Peer-to-Peer Energy Exchange Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w300),
                ),
              ),
              const SizedBox(height: 48),
              AnimateOnVisibility(
                key: const Key('hero-button'),
                delay: Duration(milliseconds: 400),
                scale: true,
                child: ElevatedButton(
                  onPressed: () => context.push('/signup'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20)),
                  child: const Text('Join the Energy Revolution', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemSection() {
    return AnimateOnVisibility(
      key: const Key('problem-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('problem-title'),
              child: const Text(
                'The Energy Crisis in Lebanon',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AnimateOnVisibility(
                  key: const Key('stat-card-0'),
                  slideYBegin: 0.2,
                  child: _buildStatCard('70%+', 'Households rely on private generators'),
                ),
                AnimateOnVisibility(
                  key: const Key('stat-card-1'),
                  slideYBegin: 0.2,
                  child: _buildStatCard('\$200/mo', 'Average energy costs per household'),
                ),
                AnimateOnVisibility(
                  key: const Key('stat-card-2'),
                  slideYBegin: 0.2,
                  child: _buildStatCard('4-6 hrs/day', 'National grid availability'),
                ),
                AnimateOnVisibility(
                  key: const Key('stat-card-3'),
                  slideYBegin: 0.2,
                  child: _buildStatCard('15%', 'Grid transmission efficiency'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return AnimateOnVisibility(
      key: const Key('features-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('features-title'),
              child: const Text(
                'Platform Features',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 60),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AnimateOnVisibility(
                  key: const Key('feature-card-0'),
                  slideXBegin: 0.2,
                  child: const _FeatureCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Blockchain Trading',
                    description: 'Secure P2P transactions using Hyperledger Fabric',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('feature-card-1'),
                  slideXBegin: 0.2,
                  child: const _FeatureCard(
                    icon: Icons.solar_power,
                    title: 'Renewable Integration',
                    description: 'Combine solar panels with existing generators',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('feature-card-2'),
                  slideXBegin: 0.2,
                  child: const _FeatureCard(
                    icon: Icons.psychology,
                    title: 'AI Predictions',
                    description: 'Machine learning for energy forecasting',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('feature-card-3'),
                  slideXBegin: 0.2,
                  child: const _FeatureCard(
                    icon: Icons.bolt,
                    title: 'Microgrid Support',
                    description: 'Islanding capability & grid synchronization',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('feature-card-4'),
                  slideXBegin: 0.2,
                  child: const _FeatureCard(
                    icon: Icons.security,
                    title: 'Military-Grade Security',
                    description: 'End-to-end encrypted communications',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('feature-card-5'),
                  slideXBegin: 0.2,
                  child: const _FeatureCard(
                    icon: Icons.currency_exchange,
                    title: 'Dynamic Pricing',
                    description: 'Real-time market-based pricing engine',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStackSection() {
    return AnimateOnVisibility(
      key: const Key('tech-stack-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900.withOpacity(0.6),
              Colors.purple.shade900.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('tech-stack-title'),
              child: const Text(
                'Powered By Cutting-Edge Technology',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(techPills.length, (i) {
                return AnimateOnVisibility(
                  key: Key('tech-pill-$i'),
                  delay: Duration(milliseconds: 50 * i),
                  child: _TechPill(techPills[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHowItWorks() {
    return AnimateOnVisibility(
      key: const Key('how-it-works-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('how-it-works-title'),
              child: const Text(
                'How It Works',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimateOnVisibility(
                  key: const Key('step-card-1'),
                  slideYBegin: 0.2,
                  child: const _StepCard(
                    step: 1,
                    title: 'Generate Energy',
                    description: 'Install solar panels or use existing generators',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('step-card-2'),
                  slideYBegin: 0.2,
                  child: const _StepCard(
                    step: 2,
                    title: 'Connect Devices',
                    description: 'Install smart meters and IoT controllers',
                  ),
                ),
                AnimateOnVisibility(
                  key: const Key('step-card-3'),
                  slideYBegin: 0.2,
                  child: const _StepCard(
                    step: 3,
                    title: 'Start Trading',
                    description: 'Buy/sell energy through our secure platform',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return AnimateOnVisibility(
      key: const Key('benefits-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('benefits-title'),
              child: const Text(
                'Community Benefits',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AnimateOnVisibility(
                  key: const Key('benefit-card-0'),
                  slideXBegin: 0.2,
                  child: _buildBenefitCard(Icons.savings, '40% Cost Reduction', 'Through direct P2P trading and optimized pricing'),
                ),
                AnimateOnVisibility(
                  key: const Key('benefit-card-1'),
                  slideXBegin: 0.2,
                  child: _buildBenefitCard(Icons.eco, 'Sustainable Future', 'Promote renewable energy adoption in your community'),
                ),
                AnimateOnVisibility(
                  key: const Key('benefit-card-2'),
                  slideXBegin: 0.2,
                  child: _buildBenefitCard(Icons.security, 'Energy Security', 'Microgrid islanding during national grid failures'),
                ),
                AnimateOnVisibility(
                  key: const Key('benefit-card-3'),
                  slideXBegin: 0.2,
                  child: _buildBenefitCard(Icons.trending_up, 'Earn Income', 'Sell excess energy to neighbors and businesses'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection() {
    return AnimateOnVisibility(
      key: const Key('cta-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900.withOpacity(0.8),
              Colors.purple.shade900.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('cta-title'),
              child: const Text(
                'Ready to Transform Energy in Lebanon?',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            AnimateOnVisibility(
              key: const Key('cta-button'),
              scale: true,
              child: ElevatedButton(
                onPressed: () => context.push('/signup'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20)),
                child: const Text('Start Trading Now', style: TextStyle(fontSize: 20, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 20),
            AnimateOnVisibility(
              key: const Key('cta-cost'),
              child: const Text('Demo System Cost: \$590', style: TextStyle(fontSize: 18, color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceSection() {
    return AnimateOnVisibility(
      key: const Key('compliance-section'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        child: Column(
          children: [
            AnimateOnVisibility(
              key: const Key('compliance-title'),
              child: const Text(
                'Compliant & Certified',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(complianceBadges.length, (i) {
                return AnimateOnVisibility(
                  key: Key('compliance-badge-$i'),
                  delay: Duration(milliseconds: 50 * i),
                  child: _ComplianceBadge(complianceBadges[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  final List<String> complianceBadges = [
    'IEEE 1547',
    'ISO 50001',
    'NIST CSF',
    'GDPR Compliant',
    'UL 1741',
    'IEC 62109',
  ];

  Widget _buildStatCard(String value, String label) {
    return Card(
      color: Colors.black.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 16),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String description) {
    return Card(
      color: Colors.black.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _TechPill(String tech) {
    return Chip(
      label: Text(tech, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black.withOpacity(0.3),
      side: const BorderSide(color: Colors.amber),
    );
  }

  // _ComplianceBadge widget to display compliance information.
  Widget _ComplianceBadge(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue.shade900.withOpacity(0.6),
      side: const BorderSide(color: Colors.amber),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.amber),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade300)),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String description;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber,
            ),
            child: Text(step.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
