// home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Services/chart_card.dart';
import '../Services/cognito_service.dart';
import '../Services/metamask.dart';
import '../Services/theme_provider.dart';
import '../Services/user_service.dart';
import '../Widgets/animated_background.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import '../Services/blockchain_service.dart';

import '../Widgets/animated_background_light.dart';
import '../Widgets/long_term_consumption_chart.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userService = UserService();
  bool _showProfileIncompleteMessage = false;
  
  // Add BlockchainService
  late final BlockchainService _blockchainService;
  bool _isWalletConnected = false;
  String? _currentWalletAddress;
  String? _currentBalance;
  int? _currentChainId;

  // Add these variables to your _HomePageState class
  bool _isLoadingPredictions = false;
  String? _predictionError;
  Map<String, double>? _consumptionPredictions;

  // Add these with your other state variables
  bool _isLoadingProduction = false;
  String? _productionError;
  Map<String, dynamic>? _productionData;

  // Add these with your other state variables
  bool _isLoadingEnergyHistory = false;
  String? _energyHistoryError;
  List<dynamic>? _energyHistoryData;
  int _energyHistoryLimit = 24;  // Default to 24 hours

  // Add these with your other state variables in _HomePageState
  bool _isLoadingAveragePrice = false;
  String? _averagePriceError;
  double? _averageWeeklyPrice;
  
  @override
  void initState() {
    super.initState();
    _showProfileIncompleteMessage = _userService.isProfileIncomplete(widget.userData);
    
    // Initialize blockchain service
    _blockchainService = BlockchainService();
    _blockchainService.addListener(_onBlockchainStateChanged);
    
    // Check if wallet is already connected (persistence)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWalletConnection();
    });

      _fetchConsumptionPredictions();
      _fetchProductionData();
      _fetchEnergyHistoryData();
      _fetchAverageWeeklyPrice();
  }
  
  @override
  void dispose() {
    _blockchainService.removeListener(_onBlockchainStateChanged);
    super.dispose();
  }
  
  // Add these methods
  Future<void> _checkWalletConnection() async {
    final isConnected = _blockchainService.isConnected;
    
    if (isConnected) {
      setState(() {
        _isWalletConnected = true;
        _currentWalletAddress = _blockchainService.currentAddress;
        _currentBalance = _blockchainService.currentBalance;
        _currentChainId = _blockchainService.currentChainId;
      });
    }
  }
  
  void _onBlockchainStateChanged() {
    setState(() {
      _isWalletConnected = _blockchainService.isConnected;
      _currentWalletAddress = _blockchainService.currentAddress;
      _currentBalance = _blockchainService.currentBalance;
      _currentChainId = _blockchainService.currentChainId;
    });

    if (_blockchainService.isConnected) {
      _fetchAverageWeeklyPrice();
    }
  }
  
  Future<void> _connectWallet() async {
    try {
      final success = await _blockchainService.connectWallet();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet connected successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect wallet'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting wallet: $e'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Now you can use userData to display personalized content
    final String username = widget.userData['cognito:username'] ?? 'User';

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
                Image.asset('assets/PIONEAR/1.png', width: 192, height: 32),
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
      Text('PIONEAR Dashboard', 
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
    
    if (_isWalletConnected) {
      // Connected state
      String displayText = _currentBalance!.substring(0,6) ?? '\$0.00';
      
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () {
          // Show wallet options menu
          _showWalletOptions(context);
        },
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
            displayText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      // Disconnected state
      return IconButton(
        icon: Icon(Icons.wallet, color: themeProvider.textColor),
        onPressed: _connectWallet,
      );
    }
  }

  Widget _buildMobileWalletButton(BuildContext context) {
    // Similar implementation as _buildWalletButton but for mobile view
    if (_isWalletConnected) {
      String displayText = _currentBalance ?? '\$0.00';
      
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () {
          _showWalletOptions(context);
        },
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
            displayText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.wallet, color: Colors.white),
        onPressed: _connectWallet,
      );
    }
  }
  
  // Add wallet options menu
  void _showWalletOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0030),
        title: const Text('Wallet Options', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address: ${_currentWalletAddress ?? 'Not connected'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Network ID: ${_currentChainId ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Copy Address', style: TextStyle(color: Colors.purple)),
            onPressed: () {
              if (_currentWalletAddress != null) {
                // Copy to clipboard functionality would go here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied to clipboard')),
                );
              }
            },
          ),
          TextButton(
            child: const Text('Switch to Holesky', style: TextStyle(color: Colors.purple)),
            onPressed: () {
            },
          ),
          TextButton(
            child: const Text('Close', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/PIONEAR/1.png', width: 192, height: 32),
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
              icon: Icons.price_change,
              iconColor: Colors.purple,
              title: 'Average Price',
              value: _isLoadingAveragePrice 
                  ? 'Loading...' 
                  : _averagePriceError != null 
                      ? 'Error' 
                      : '\$${_averageWeeklyPrice?.toStringAsFixed(3) ?? '0.000'}/kWh',
              subtitle: 'Past 7 days',
              isPositiveTrend: _averageWeeklyPrice != null && _averageWeeklyPrice! < 0.05,
            ),
            // _buildStatsCard(
            //   context,
            //   icon: Icons.eco,
            //   iconColor: Colors.blue,
            //   title: 'Carbon Offset',
            //   value: '24 kg',
            //   subtitle: '+30% than last month',
            //   isPositiveTrend: true,
            // ),
            // _buildStatsCard(
            //   context,
            //   icon: Icons.account_balance,
            //   iconColor: Colors.orange,
            //   title: 'Token Balance',
            //   value: '1,245',
            //   subtitle: '+3% this week',
            //   isPositiveTrend: true,
            // ),
            // _buildStatsCard(
            //   context,
            //   icon: Icons.bolt,
            //   iconColor: Colors.red,
            //   title: 'Peak Power',
            //   value: '3.2 kW',
            //   subtitle: '-8% this month',
            //   isPositiveTrend: true,
            // ),
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
    return Column(
      children: [
        _buildEnergyHistoryCard(), // Add this line at the top
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: const LongTermConsumptionChart(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildProductionPredictionCard(),
                  const SizedBox(height: 16),
                  _buildTokenDistributionChart(context),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _buildConsumptionPredictionCard(),
            ),
          ],
        ),
      ],
    );
  } else {
    return Column(
      children: [
        _buildEnergyHistoryCard(), // Add this line at the top
        const SizedBox(height: 16),
        LongTermConsumptionChart(),
        const SizedBox(height: 16),
        _buildTokenDistributionChart(context),
        const SizedBox(height: 16),
        _buildConsumptionPredictionCard(),
        const SizedBox(height: 16),
        _buildProductionPredictionCard(),
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
          borderRadius: BorderRadius.circular(8)),
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

  // Add this method to your _HomePageState class
  Future<void> _fetchConsumptionPredictions() async {
    if (_isLoadingPredictions) return;
    
    setState(() {
      _isLoadingPredictions = true;
      _predictionError = null;
    });
    
    try {
      final predictions = await CognitoService().getShortTermConsumptionPrediction();
      
      setState(() {
        _consumptionPredictions = predictions;
        _isLoadingPredictions = false;
      });
    } catch (e) {
      setState(() {
        _predictionError = e.toString();
        _isLoadingPredictions = false;
      });
    }
  }
  Widget _buildConsumptionPredictionCard() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  // Get the current time to calculate hour ranges
  final now = DateTime.now();
  
  // Function to format hour ranges from "Hour X" labels
  String formatHourRange(String hourLabel) {
    // Extract the hour number from the label (e.g., "Hour 1" -> 1)
    final hourMatch = RegExp(r'Hour (\d+)').firstMatch(hourLabel);
    if (hourMatch != null) {
      final hourOffset = int.parse(hourMatch.group(1)!);
      
      // Calculate the start and end times
      final startTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        now.hour + hourOffset - 1
      );
      
      final endTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        now.hour + hourOffset
      );
      
      // Format as "HH:00 - HH:00"
      return "${DateFormat('HH:00').format(startTime)} - ${DateFormat('HH:00').format(endTime)}";
    }
    
    return hourLabel; // Return original if no match
  }
  
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Short-Term Consumption Prediction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: themeProvider.textColorSecondary),
                onPressed: _fetchConsumptionPredictions,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPredictions)
            const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
          else if (_predictionError != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load prediction data',
                    style: TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: _fetchConsumptionPredictions,
                    child: const Text('Try Again', style: TextStyle(color: Colors.purple)),
                  )
                ],
              ),
            )
          else if (_consumptionPredictions == null || _consumptionPredictions!.isEmpty)
            Center(
              child: Text(
                'No prediction data available',
                style: TextStyle(color: themeProvider.textColorSecondary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                    ),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Time Period',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Predicted (kWh)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (var entry in _consumptionPredictions!.entries)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              formatHourRange(entry.key),
                              style: TextStyle(color: themeProvider.textColorSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              entry.value.toStringAsFixed(2),
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Forecast updated: ${DateFormat('HH:mm, MMM d').format(now)}',
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.textColorSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    ),
  );
}

  // Add this method to your _HomePageState class
  Future<void> _fetchProductionData() async {
    if (_isLoadingProduction) return;
    
    setState(() {
      _isLoadingProduction = true;
      _productionError = null;
    });
    
    try {
      final data = await CognitoService().getProductionPrediction();
      
      setState(() {
        _productionData = data;
        _isLoadingProduction = false;
      });
    } catch (e) {
      setState(() {
        _productionError = e.toString();
        _isLoadingProduction = false;
      });
    }
  }

  Widget _buildProductionPredictionCard() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  // Get the current time to calculate hour ranges
  final now = DateTime.now();
  
  // Function to format hour ranges from "Hour X" labels
  String formatHourRange(String hourLabel) {
    // Extract the hour number from the label (e.g., "Hour 1" -> 1)
    final hourMatch = RegExp(r'Hour (\d+)').firstMatch(hourLabel);
    if (hourMatch != null) {
      final hourOffset = int.parse(hourMatch.group(1)!);
      
      // Calculate the start and end times
      final startTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        now.hour + hourOffset - 1
      );
      
      final endTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        now.hour + hourOffset
      );
      
      // Format as "HH:00 - HH:00"
      return "${DateFormat('HH:00').format(startTime)} - ${DateFormat('HH:00').format(endTime)}";
    }
    
    return hourLabel; // Return original if no match
  }
  
  return Card(
    elevation: 8,
    shadowColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Container(
      decoration: BoxDecoration(
        gradient: themeProvider.cardGradient,
        borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energy Production Prediction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: themeProvider.textColorSecondary),
                onPressed: _fetchProductionData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingProduction)
            const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
          else if (_productionError != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load production data',
                    style: TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: _fetchProductionData,
                    child: const Text('Try Again', style: TextStyle(color: Colors.purple)),
                  )
                ],
              ),
            )
          else if (_productionData == null || !_productionData!.containsKey('predictions'))
            Center(
              child: Text(
                'No production data available',
                style: TextStyle(color: themeProvider.textColorSecondary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                    ),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Time Period',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Predicted (kWh)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (var hourLabel in (_productionData!['predictions'] as Map).keys)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              formatHourRange(hourLabel.toString()),
                              style: TextStyle(color: themeProvider.textColorSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              (_productionData!['predictions'][hourLabel] as num).toStringAsFixed(2),
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Forecast updated: ${DateFormat('HH:mm, MMM d').format(now)}',
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.textColorSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    ),
  );
}

// Add this method to your _HomePageState class
Future<void> _fetchEnergyHistoryData() async {
  if (_isLoadingEnergyHistory) return;
  
  setState(() {
    _isLoadingEnergyHistory = true;
    _energyHistoryError = null;
  });
  
  try {
    final data = await CognitoService().getEnergyHistoryData(limit: _energyHistoryLimit);
    
    setState(() {
      _energyHistoryData = data;
      _isLoadingEnergyHistory = false;
    });
  } catch (e) {
    setState(() {
      _energyHistoryError = e.toString();
      _isLoadingEnergyHistory = false;
    });
  }
}

// Helper methods for the energy history chart
List<fl_chart.FlSpot> _getConsumptionSpots() {
  if (_energyHistoryData == null || _energyHistoryData!.isEmpty) return [];
  
  // Sort the data by timestamp (oldest first)
  _energyHistoryData!.sort((a, b) {
    DateTime timestampA = DateTime.parse(a['timestamp']);
    DateTime timestampB = DateTime.parse(b['timestamp']);
    return timestampA.compareTo(timestampB);
  });
  
  // Convert to FlSpot list
  List<fl_chart.FlSpot> spots = [];
  for (int i = 0; i < _energyHistoryData!.length; i++) {
    final item = _energyHistoryData![i];
    final consumptionStr = item['messageData']['consumption']['S'];
    double consumption = double.tryParse(consumptionStr) ?? 0;
    spots.add(fl_chart.FlSpot(i.toDouble(), consumption));
  }
  
  return spots;
}

List<fl_chart.FlSpot> _getProductionSpots() {
  if (_energyHistoryData == null || _energyHistoryData!.isEmpty) return [];
  
  // Sort the data by timestamp (oldest first)
  _energyHistoryData!.sort((a, b) {
    DateTime timestampA = DateTime.parse(a['timestamp']);
    DateTime timestampB = DateTime.parse(b['timestamp']);
    return timestampA.compareTo(timestampB);
  });
  
  // Convert to FlSpot list
  List<fl_chart.FlSpot> spots = [];
  for (int i = 0; i < _energyHistoryData!.length; i++) {
    final item = _energyHistoryData![i];
    final productionStr = item['messageData']['production']['S'];
    double production = double.tryParse(productionStr) ?? 0;
    spots.add(fl_chart.FlSpot(i.toDouble(), production));
  }
  
  return spots;
}

List<String> _getTimeLabels() {
  if (_energyHistoryData == null || _energyHistoryData!.isEmpty) return [];
  
  // Sort the data by timestamp (oldest first)
  _energyHistoryData!.sort((a, b) {
    DateTime timestampA = DateTime.parse(a['timestamp']);
    DateTime timestampB = DateTime.parse(b['timestamp']);
    return timestampA.compareTo(timestampB);
  });
  
  // Get formatted time labels
  List<String> labels = [];
  for (var item in _energyHistoryData!) {
    final timestampStr = item['timestamp'];
    final timestamp = DateTime.parse(timestampStr);
    labels.add(DateFormat('HH:mm').format(timestamp));
  }
  
  return labels;
}

double _getMaxYValue() {
  if (_energyHistoryData == null || _energyHistoryData!.isEmpty) return 5.0;
  
  double maxConsumption = 0;
  double maxProduction = 0;
  
  for (var item in _energyHistoryData!) {
    final consumptionStr = item['messageData']['consumption']['S'];
    final productionStr = item['messageData']['production']['S'];
    
    double consumption = double.tryParse(consumptionStr) ?? 0;
    double production = double.tryParse(productionStr) ?? 0;
    
    if (consumption > maxConsumption) maxConsumption = consumption;
    if (production > maxProduction) maxProduction = production;
  }
  
  double maxValue = maxConsumption > maxProduction ? maxConsumption : maxProduction;
  return maxValue * 1.2; // Add 20% padding
}

Widget _buildEnergyHistoryCard() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  // Get the current time for the updated timestamp
  final now = DateTime.now();
  
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energy History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              Row(
                children: [
                  DropdownButton<int>(
                    value: _energyHistoryLimit,
                    dropdownColor: themeProvider.isDarkMode ? Colors.black54 : Colors.white,
                    style: TextStyle(color: themeProvider.textColor),
                    underline: Container(
                      height: 1,
                      color: Colors.purple.withOpacity(0.5),
                    ),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _energyHistoryLimit = newValue;
                        });
                        _fetchEnergyHistoryData();
                      }
                    },
                    items: [
                      DropdownMenuItem<int>(value: 2, child: Text('2 hours')),
                      DropdownMenuItem<int>(value: 12, child: Text('12 hours')),
                      DropdownMenuItem<int>(value: 24, child: Text('24 hours')),
                      DropdownMenuItem<int>(value: 48, child: Text('48 hours')),
                      DropdownMenuItem<int>(value: 72, child: Text('72 hours')),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: themeProvider.textColorSecondary),
                    onPressed: _fetchEnergyHistoryData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingEnergyHistory)
            const Center(
              child: SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                ),
              ),
            )
          else if (_energyHistoryError != null)
            Center(
              child: SizedBox(
                height: 250,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load energy history',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _fetchEnergyHistoryData,
                      child: const Text('Try Again', style: TextStyle(color: Colors.purple)),
                    ),
                  ],
                ),
              ),
            )
          else if (_energyHistoryData == null || _energyHistoryData!.isEmpty)
            Center(
              child: SizedBox(
                height: 250,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: themeProvider.textColorSecondary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No energy history data available',
                      style: TextStyle(color: themeProvider.textColorSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 8, top: 8, bottom: 32),
                child: fl_chart.LineChart(
                  fl_chart.LineChartData(
                    gridData: fl_chart.FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => fl_chart.FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => fl_chart.FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    lineTouchData: fl_chart.LineTouchData(
                      touchTooltipData: fl_chart.LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => 
                          touchedSpot.barIndex == 0 ? Colors.purple : Colors.green,
                        getTooltipItems: (List<fl_chart.LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final type = spot.barIndex == 0 ? 'Consumption' : 'Production';
                            final timeLabel = _getTimeLabels()[spot.x.toInt()];
                            return fl_chart.LineTooltipItem(
                              '$type: ${spot.y.toStringAsFixed(1)} kWh\n$timeLabel',
                              TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: fl_chart.FlTitlesData(
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                  color: themeProvider.textColorSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final timeLabels = _getTimeLabels();
                            // Show fewer x-axis labels for readability
                            if (value.toInt() % (timeLabels.length > 12 ? 3 : 2) == 0 &&
                                value.toInt() < timeLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  timeLabels[value.toInt()],
                                  style: TextStyle(
                                    color: themeProvider.textColorSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(showTitles: false),
                      ),
                      rightTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                        left: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                      ),
                    ),
                    lineBarsData: [
                      // Consumption line
                      fl_chart.LineChartBarData(
                        spots: _getConsumptionSpots(),
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: fl_chart.FlDotData(
                          show: _energyHistoryData!.length < 24, // Only show dots for smaller datasets
                          getDotPainter: (spot, percent, barData, index) => fl_chart.FlDotCirclePainter(
                            radius: 4,
                            color: Colors.purple,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: fl_chart.BarAreaData(
                          show: true,
                          color: Colors.purple.withOpacity(0.15),
                        ),
                      ),
                      // Production line
                      fl_chart.LineChartBarData(
                        spots: _getProductionSpots(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: fl_chart.FlDotData(
                          show: _energyHistoryData!.length < 24, // Only show dots for smaller datasets
                          getDotPainter: (spot, percent, barData, index) => fl_chart.FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: fl_chart.BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.15),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: (_energyHistoryData!.length - 1).toDouble(),
                    minY: 0,
                    maxY: _getMaxYValue(),
                  ),
                ),
              ),
            ),
          if (!_isLoadingEnergyHistory && _energyHistoryError == null && 
              _energyHistoryData != null && _energyHistoryData!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEnergyLegendItem('Consumption', Colors.purple),
                  const SizedBox(width: 24),
                  _buildEnergyLegendItem('Production', Colors.green),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Updated: ${DateFormat('HH:mm, MMM d').format(now)}',
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.textColorSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    ),
  );
}

Widget _buildEnergyLegendItem(String label, Color color) {
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

// Add this method to your _HomePageState class
Future<void> _fetchAverageWeeklyPrice() async {
  if (!_isWalletConnected) {
    setState(() {
      _averagePriceError = "Wallet not connected";
      _isLoadingAveragePrice = false;
    });
    return;
  }
  
  setState(() {
    _isLoadingAveragePrice = true;
    _averagePriceError = null;
  });
  
  try {
    // Check if blockchain service is properly initialized
    if (!_blockchainService.isConnected || 
        _blockchainService.currentAddress == null) {
      setState(() {
        _averagePriceError = "Blockchain service not ready";
        _isLoadingAveragePrice = false;
      });
      return;
    }
    
    final price = await _blockchainService.getAveragePriceLastWeek();
    
    setState(() {
      _averageWeeklyPrice = price;
      _isLoadingAveragePrice = false;
    });
  } catch (e) {
    setState(() {
      _averagePriceError = e.toString();
      _isLoadingAveragePrice = false;
      print('Error loading average price: $e');
    });
  }
}

}