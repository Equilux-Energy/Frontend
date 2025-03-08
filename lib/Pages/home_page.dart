// home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/chart_card.dart';

import '../Services/metamask.dart';
import '../Widgets/animated_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
  return ChangeNotifierProvider<MetaMaskProvider>(
    create: (context) => MetaMaskProvider()..init(),
    builder: (context, child) {
      return Stack(
        children: [
          const AnimatedBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
              title: const Row(
                children: [
                  FlutterLogo(size: 32),
                  SizedBox(width: 8), // Add some space between the logo and the text
                  Text('PIONEER Dashboard'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
                ),
                Consumer<MetaMaskProvider>(
                  builder: (context, provider, child) {
                    if (provider.isConnected && provider.isInOperatingChain) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Make the button background transparent
                          shadowColor: Colors.transparent, // Remove the shadow
                        ),
                        onPressed: () {},
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5C005C), Color(0xFF240029)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            '${provider.currentBalance} USD',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ); // connected
                    } else if (provider.isEnabled) {
                      return IconButton(
                        icon: const Icon(Icons.wallet),
                        onPressed: () => context.read<MetaMaskProvider>().connect(), // call metamask on click
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
            drawer: Drawer(
              shape: const RoundedRectangleBorder( // Add this
                borderRadius: BorderRadius.only(
                  topRight: Radius.zero,
                  bottomRight: Radius.zero,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(
                    height: 66, // Adjust the height as needed
                    child: DrawerHeader(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2A0030), Color(0xff5e0b8b)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_support),
                    title: const Text('Support'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/support');
                    },
                  ),
                ],
              ),
            ),
            body: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to PIONEER', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 24),
                  Expanded(child: GridDashboard()),
                ],
              ),
            ),
          ),
        ],
      );
    }
  );
  }
}

class GridDashboard extends StatelessWidget {
  const GridDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.5,
      children: [
        const EnergyConsumptionCard(),
        _buildDashboardCard(Icons.analytics, 'Analytics', Colors.green),
        _buildDashboardCard(Icons.account_balance_wallet, 'Wallet', Colors.orange),
        _buildDashboardCard(Icons.history, 'Transaction History', Colors.purple),
        _buildDashboardCard(Icons.settings, 'Settings', Colors.grey),
        _buildDashboardCard(Icons.help, 'Support', Colors.red),
      ],
    );
  }

  Widget _buildDashboardCard(IconData icon, String title, Color color) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      child: Container(
        decoration: BoxDecoration(
      color: Colors.purple.withOpacity(0.1), // Add a slight purple tint
      borderRadius: BorderRadius.circular(4), // Match the Card's border radius
    ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}