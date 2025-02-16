import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../Widgets/gradient_wave_background.dart';

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
          const GradientWaveBackground(),
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
      title: const Text('PIONEER',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            onPressed: () => context.push('/signin'),
            child: const Text('Get Started',
                style: TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(String text, String route) {
    return TextButton(
      onPressed: () => context.push(route),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
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
              const Text('PIONEER',
                      style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                blurRadius: 10,
                                color: Colors.black,
                                offset: Offset(2, 2))
                          ]))
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 24),
              const Text('Peer-to-Peer Energy Exchange Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w300))
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.push('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 20),
                ),
                child: const Text('Join the Energy Revolution',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ).animate().scale(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Column(
        children: [
          const Text('The Energy Crisis in Lebanon',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            children: [
              _buildStatCard('70%+', 'Households rely on private generators'),
              _buildStatCard('\$200/mo', 'Average energy costs per household'),
              _buildStatCard('4-6 hrs/day', 'National grid availability'),
              _buildStatCard('15%', 'Grid transmission efficiency'),
            ].animate(interval: 100.ms).slideY(begin: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Column(
        children: [
          const Text('Platform Features',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 60),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            children: [
              _FeatureCard(
                icon: Icons.account_balance_wallet,
                title: 'Blockchain Trading',
                description: 'Secure P2P transactions using Hyperledger Fabric',
              ),
              _FeatureCard(
                icon: Icons.solar_power,
                title: 'Renewable Integration',
                description: 'Combine solar panels with existing generators',
              ),
              _FeatureCard(
                icon: Icons.psychology,
                title: 'AI Predictions',
                description: 'Machine learning for energy forecasting',
              ),
              _FeatureCard(
                icon: Icons.bolt,
                title: 'Microgrid Support',
                description: 'Islanding capability & grid synchronization',
              ),
              _FeatureCard(
                icon: Icons.security,
                title: 'Military-Grade Security',
                description: 'End-to-end encrypted communications',
              ),
              _FeatureCard(
                icon: Icons.currency_exchange,
                title: 'Dynamic Pricing',
                description: 'Real-time market-based pricing engine',
              ),
            ].animate(interval: 100.ms).slideX(begin: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackSection() {
    return Container(
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
          const Text('Powered By Cutting-Edge Technology',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _TechPill('Hyperledger Fabric'),
              _TechPill('TensorFlow Lite'),
              _TechPill('IoT Sensors'),
              _TechPill('AWS IoT Core'),
              _TechPill('Flutter Framework'),
              _TechPill('MPPT Controllers'),
              _TechPill('Machine Learning'),
              _TechPill('Smart Contracts'),
            ].animate(interval: 50.ms).fadeIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        children: [
          const Text('How It Works',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StepCard(
                step: 1,
                title: 'Generate Energy',
                description: 'Install solar panels or use existing generators',
              ),
              _StepCard(
                step: 2,
                title: 'Connect Devices',
                description: 'Install smart meters and IoT controllers',
              ),
              _StepCard(
                step: 3,
                title: 'Start Trading',
                description: 'Buy/sell energy through our secure platform',
              ),
            ].animate(interval: 100.ms).slideY(begin: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Column(
        children: [
          const Text('Community Benefits',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            children: [
              _buildBenefitCard(Icons.savings, '40% Cost Reduction',
                  'Through direct P2P trading and optimized pricing'),
              _buildBenefitCard(Icons.eco, 'Sustainable Future',
                  'Promote renewable energy adoption in your community'),
              _buildBenefitCard(Icons.security, 'Energy Security',
                  'Microgrid islanding during national grid failures'),
              _buildBenefitCard(Icons.trending_up, 'Earn Income',
                  'Sell excess energy to neighbors and businesses'),
            ].animate(interval: 100.ms).slideX(begin: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text('Compliant & Certified',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _ComplianceBadge('IEEE 1547'),
              _ComplianceBadge('ISO 50001'),
              _ComplianceBadge('NIST CSF'),
              _ComplianceBadge('GDPR Compliant'),
              _ComplianceBadge('UL 1741'),
              _ComplianceBadge('IEC 62109'),
            ].animate(interval: 50.ms).fadeIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
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
          const Text('Ready to Transform Energy in Lebanon?',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))
              .animate()
              .fadeIn(),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.push('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
            child: const Text('Start Trading Now',
                style: TextStyle(fontSize: 20, color: Colors.black)),
          ).animate().scale(),
          const SizedBox(height: 20),
          const Text('Demo System Cost: \$590',
                  style: TextStyle(fontSize: 18, color: Colors.white70))
              .animate()
              .fadeIn(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Card(
      color: Colors.black.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber)),
            const SizedBox(height: 16),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70)),
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
            Text(title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
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
            Text(title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade300)),
          ],
        ),
      ),
    ).animate().scale(
      delay: 200.ms,
      curve: Curves.easeOutBack,
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
            child: Text(step.toString(),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Text(description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}