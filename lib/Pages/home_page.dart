// home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/chart_card.dart';
import '../Services/cognito_service.dart';
import '../Services/metamask.dart';
import '../Services/theme_provider.dart';
import '../Services/user_service.dart';
import '../Widgets/animated_background.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;

import '../Widgets/animated_background_light.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userService = UserService();
  bool _showProfileIncompleteMessage = false;
  
  @override
  void initState() {
    super.initState();
    _showProfileIncompleteMessage = _userService.isProfileIncomplete(widget.userData);
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Now you can use userData to display personalized content
    final String username = widget.userData['cognito:username'] ?? 'User';

    return ChangeNotifierProvider<MetaMaskProvider>(
      create: (context) => MetaMaskProvider()..init(),
      builder: (context, child) {
        return Stack(
          children: [
            if (themeProvider.isDarkMode) 
              const AnimatedBackground() 
            else 
              const AnimatedBackgroundLight(),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: isMobile ? _buildAppBar(context) : null,
              drawer: isMobile ? _buildDrawer(context) : null,
              body: Column(
                children: [
                  // Profile completion banner
                  if (_showProfileIncompleteMessage)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: Colors.orange.shade800,
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Your profile is incomplete. Please complete your profile to use all features.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade800,
                            ),
                            child: const Text('Complete Now'),
                          ),
                        ],
                      ),
                    ),
                  
                  // Your existing content
                  Expanded(
                    child: Row(
                      children: [
                        if (!isMobile) _buildSidebar(context),
                        
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMobile)
                                    _buildTopBar(context),
                                    
                                  const SizedBox(height: 16),
                                  Text('Dashboard', 
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: themeProvider.textColor)),
                                  const SizedBox(height: 24),
                                  
                                  _buildStatsCards(),
                                  
                                  const SizedBox(height: 24),
                                  
                                  _buildChartsSection(context),
                                  
                                  const SizedBox(height: 24),
                                  
                                  _buildTableSection(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
  
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
      title: Row(
        children: [
          const FlutterLogo(size: 32),
          const SizedBox(width: 8),
          Text('PIONEER'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
        _buildMobileWalletButton(context),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await CognitoService().signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/signin');
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildTopBar(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('PIONEER Dashboard', 
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeProvider.textColor)),
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.search, color: themeProvider.textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: themeProvider.textColor),
            onPressed: () {},
          ),
          _buildWalletButton(context),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.logout, color: themeProvider.textColor),
            onPressed: () async {
              await CognitoService().signOut(); // Clear tokens first
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
          ),
        ],
      ),
    ],
  );
}

  
  Widget _buildWalletButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<MetaMaskProvider>(
      builder: (context, provider, child) {
        if (provider.isConnected && provider.isInOperatingChain) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
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
          );
        } else if (provider.isEnabled) {
          return IconButton(
            icon: Icon(Icons.wallet, color: themeProvider.textColor),
            onPressed: () => context.read<MetaMaskProvider>().connect(),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildMobileWalletButton(BuildContext context) {
    return Consumer<MetaMaskProvider>(
      builder: (context, provider, child) {
        if (provider.isConnected && provider.isInOperatingChain) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
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
          );
        } else if (provider.isEnabled) {
          return IconButton(
            icon: const Icon(Icons.wallet, color: Colors.white),
            onPressed: () => context.read<MetaMaskProvider>().connect(),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
  
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2A0030), // Match sidebar background color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: _buildDrawerContent(context),
    );
  }
  
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF2A0030),
      child: _buildDrawerContent(context),
    );
  }
  
  Widget _buildDrawerContent(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A0030), Color(0xff5e0b8b)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlutterLogo(size: 32),
                SizedBox(width: 8),
                Text(
                  'PIONEER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildNavItem(context, 'Dashboard', Icons.dashboard, true,"/home"),
              _buildNavItem(context, 'User Profile', Icons.person, false,"/profile"),
              _buildNavItem(context, 'Analytics', Icons.analytics, false,""),
              _buildNavItem(context, 'Wallet', Icons.account_balance_wallet, false,""),
              _buildNavItem(context, 'Transactions', Icons.history, false,"/transactions"),
              _buildNavItem(context, 'Chat', Icons.chat, false,"/chat"),
              _buildNavItem(context, 'Settings', Icons.settings, false,"/settings"),
              _buildNavItem(context, 'Support', Icons.support, false,""),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C005C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await CognitoService().signOut(); // Clear tokens first
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNavItem(BuildContext context, String title, IconData icon, bool isActive, String route) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isActive ? Colors.white : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? Colors.purple.withOpacity(0.3) : Colors.transparent,
      onTap: () {
        // Example of navigation from HomePage to ProfilePage with userData
        Navigator.pushNamed(
          context, 
          route,
          arguments: widget.userData
        );
      },
    );
  }
  
  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 768 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatsCard(
              context,
              icon: Icons.energy_savings_leaf,
              iconColor: Colors.green,
              title: 'Energy Used',
              value: '149.5 kWh',
              subtitle: '+15% than last week',
              isPositiveTrend: false,
            ),
            _buildStatsCard(
              context,
              icon: Icons.eco,
              iconColor: Colors.blue,
              title: 'Carbon Offset',
              value: '24 kg',
              subtitle: '+30% than last month',
              isPositiveTrend: true,
            ),
            _buildStatsCard(
              context,
              icon: Icons.account_balance,
              iconColor: Colors.orange,
              title: 'Token Balance',
              value: '1,245',
              subtitle: '+3% this week',
              isPositiveTrend: true,
            ),
            _buildStatsCard(
              context,
              icon: Icons.bolt,
              iconColor: Colors.red,
              title: 'Peak Power',
              value: '3.2 kW',
              subtitle: '-8% this month',
              isPositiveTrend: true,
            ),
          ],
        );
      }
    );
  }
  
  // Then modify the stats cards
Widget _buildStatsCard(BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String value,
  required String subtitle,
  required bool isPositiveTrend,
}) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  return Card(
    elevation: 8,
    shadowColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Container(
      decoration: BoxDecoration(
        gradient: themeProvider.cardGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.2),
                child: Icon(icon, color: iconColor),
              ),
              Icon(
                isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                color: isPositiveTrend ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isPositiveTrend ? Colors.green[300] : Colors.red[300],
            ),
          ),
        ],
      ),
    ),
  );
}

  
  Widget _buildChartsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    
    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: _buildEnergyConsumptionChart(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _buildTokenDistributionChart(context),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildEnergyConsumptionChart(),
          const SizedBox(height: 16),
          _buildTokenDistributionChart(context),
        ],
      );
    }
  }
  
  Widget _buildEnergyConsumptionChart() {
    return Container(
      height: 300, // Make sure it has sufficient height
      child: const EnergyConsumptionCard(),
    );
  }
  
  Widget _buildTokenDistributionChart(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  return Card(
    elevation: 8,
    shadowColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Container(
      decoration: BoxDecoration(
        gradient: themeProvider.cardGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Token Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("Pie chart placeholder",
                      style: TextStyle(color: themeProvider.textColorSecondary)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Staked', Colors.purple),
                    _buildLegendItem('Available', Colors.blue),
                    _buildLegendItem('Rewards', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
  
  Widget _buildTableSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    
    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: _buildTransactionsTable(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _buildTasksList(),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildTransactionsTable(),
          const SizedBox(height: 16),
          _buildTasksList(),
        ],
      );
    }
  }
  
  Widget _buildTransactionsTable() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                columnSpacing: 16,
                dataRowHeight: 60,
                headingRowColor: MaterialStateProperty.all(
                  Colors.purple.withOpacity(0.2),
                ),
                columns: const [
                  DataColumn(
                    label: Text('Date', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text('Type', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text('Amount', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text('Status', style: TextStyle(color: Colors.white)),
                  ),
                ],
                rows: [
                  _buildTransactionRow(
                    date: '08 Mar',
                    type: 'Purchase',
                    amount: '-123.00',
                    status: 'Completed',
                    statusColor: Colors.green,
                  ),
                  _buildTransactionRow(
                    date: '07 Mar',
                    type: 'Staking',
                    amount: '-500.00',
                    status: 'Completed',
                    statusColor: Colors.green,
                  ),
                  _buildTransactionRow(
                    date: '05 Mar',
                    type: 'Reward',
                    amount: '+45.20',
                    status: 'Completed',
                    statusColor: Colors.green,
                  ),
                  _buildTransactionRow(
                    date: '01 Mar',
                    type: 'Transfer',
                    amount: '-10.00',
                    status: 'Pending',
                    statusColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  DataRow _buildTransactionRow({
    required String date,
    required String type,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return DataRow(
      cells: [
        DataCell(Text(date, style: const TextStyle(color: Colors.white70))),
        DataCell(Text(type, style: const TextStyle(color: Colors.white70))),
        DataCell(Text(
          amount,
          style: TextStyle(
            color: amount.startsWith('+') ? Colors.green : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTasksList() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildTaskItem(
              title: 'Complete KYC verification',
              subtitle: 'Required for token withdrawals',
              isDone: true,
            ),
            _buildTaskItem(
              title: 'Set up 2FA security',
              subtitle: 'Enhance your account security',
              isDone: false,
            ),
            _buildTaskItem(
              title: 'Connect smart meter',
              subtitle: 'Enable automatic energy readings',
              isDone: false,
            ),
            _buildTaskItem(
              title: 'Stake your tokens',
              subtitle: 'Earn passive income on holdings',
              isDone: false,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C005C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Add New Task'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskItem({
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          activeColor: Colors.purple,
          onChanged: (value) {},
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.more_vert, color: Colors.grey),
      ),
    );
  }
}