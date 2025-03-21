import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/metamask.dart';
import '../Services/theme_provider.dart';
import '../Widgets/animated_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User settings values
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _tradesNotifications = true;
  bool _marketingNotifications = false;
  bool _twoFactorAuth = true;
  bool _rememberLogin = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';
  double _chartUpdateFrequency = 15.0; // seconds
  bool _autoAcceptTrades = false;
  bool _showNetworkStats = true;

  List<String> languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese'];
  List<String> currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'BTC', 'ETH'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = themeProvider.textColor;
    final textColorSecondary = themeProvider.textColorSecondary;
    
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;

    return ChangeNotifierProvider<MetaMaskProvider>(
      create: (context) => MetaMaskProvider()..init(),
      builder: (context, child) {
        return Stack(
          children: [
            if (isDarkMode) const AnimatedBackground() else Container(color: Colors.grey[100]),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: isMobile ? _buildAppBar(context) : null,
              drawer: isMobile ? _buildDrawer(context) : null,
              body: Row(
                children: [
                  // Permanent sidebar for desktop
                  if (!isMobile) _buildSidebar(context),
                  
                  // Main content area
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top bar with profile and wallet for desktop
                            if (!isMobile)
                              _buildTopBar(context),
                              
                            const SizedBox(height: 16),
                            Text('Settings', 
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 24),
                            
                            // Settings content
                            _buildSettingsContent(textColor, textColorSecondary, themeProvider),
                          ],
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
    );
  }
  
  Widget _buildSettingsContent(Color textColor, Color textColorSecondary, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppearanceSection(textColor, textColorSecondary, themeProvider),
        const SizedBox(height: 24),
        _buildNotificationsSection(textColor, textColorSecondary),
        const SizedBox(height: 24),
        _buildSecuritySection(textColor, textColorSecondary),
        const SizedBox(height: 24),
        _buildPreferencesSection(textColor, textColorSecondary),
        const SizedBox(height: 24),
        _buildEnergyTradingSection(textColor, textColorSecondary),
      ],
    );
  }
  
  Widget _buildAppearanceSection(Color textColor, Color textColorSecondary, ThemeProvider themeProvider) {
    return _buildSettingsCard(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        _buildSwitchSettingTile(
          title: 'Dark Mode',
          subtitle: 'Switch between light and dark themes',
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme();
          },
          icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        ),
        const Divider(),
        _buildDropdownSettingTile(
          title: 'Language',
          subtitle: 'Select your preferred language',
          value: _selectedLanguage,
          items: languages.map((lang) => DropdownMenuItem(
            value: lang,
            child: Text(lang, style: TextStyle(color: themeProvider.textColor)),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value as String;
            });
          },
          icon: Icons.language,
        ),
        const Divider(),
        _buildDropdownSettingTile(
          title: 'Currency',
          subtitle: 'Select your preferred currency',
          value: _selectedCurrency,
          items: currencies.map((currency) => DropdownMenuItem(
            value: currency,
            child: Text(currency, style: TextStyle(color: themeProvider.textColor)),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCurrency = value as String;
            });
          },
          icon: Icons.attach_money,
        ),
      ],
    );
  }
  
  Widget _buildNotificationsSection(Color textColor, Color textColorSecondary) {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications_active,
      children: [
        _buildSwitchSettingTile(
          title: 'Email Notifications',
          subtitle: 'Receive important updates via email',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
          icon: Icons.email,
        ),
        const Divider(),
        _buildSwitchSettingTile(
          title: 'Push Notifications',
          subtitle: 'Receive notifications on your device',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
          icon: Icons.notifications,
        ),
        const Divider(),
        _buildSwitchSettingTile(
          title: 'Trade Notifications',
          subtitle: 'Get notified about new trade offers',
          value: _tradesNotifications,
          onChanged: (value) {
            setState(() {
              _tradesNotifications = value;
            });
          },
          icon: Icons.swap_horiz,
        ),
        const Divider(),
        _buildSwitchSettingTile(
          title: 'Marketing Notifications',
          subtitle: 'Receive news and promotional content',
          value: _marketingNotifications,
          onChanged: (value) {
            setState(() {
              _marketingNotifications = value;
            });
          },
          icon: Icons.campaign,
        ),
      ],
    );
  }
  
  Widget _buildSecuritySection(Color textColor, Color textColorSecondary) {
    return _buildSettingsCard(
      title: 'Security',
      icon: Icons.security,
      children: [
        _buildSwitchSettingTile(
          title: 'Two-Factor Authentication',
          subtitle: 'Add an extra layer of security',
          value: _twoFactorAuth,
          onChanged: (value) {
            setState(() {
              _twoFactorAuth = value;
            });
          },
          icon: Icons.verified_user,
        ),
        const Divider(),
        _buildSwitchSettingTile(
          title: 'Remember Login',
          subtitle: 'Stay logged in on this device',
          value: _rememberLogin,
          onChanged: (value) {
            setState(() {
              _rememberLogin = value;
            });
          },
          icon: Icons.login,
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_reset, color: Theme.of(context).primaryColor),
          ),
          title: Text('Change Password', style: TextStyle(color: textColor)),
          subtitle: Text('Update your account password', style: TextStyle(color: textColorSecondary)),
          trailing: Icon(Icons.arrow_forward_ios, color: textColorSecondary, size: 16),
          onTap: () {
            // Navigate to change password screen or show dialog
          },
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_forever, color: Colors.red),
          ),
          title: Text('Delete Account', style: TextStyle(color: Colors.red)),
          subtitle: Text('Permanently remove your account and data', style: TextStyle(color: textColorSecondary)),
          trailing: Icon(Icons.arrow_forward_ios, color: textColorSecondary, size: 16),
          onTap: () {
            // Show confirmation dialog
            _showDeleteAccountDialog();
          },
        ),
      ],
    );
  }
  
  Widget _buildPreferencesSection(Color textColor, Color textColorSecondary) {
    return _buildSettingsCard(
      title: 'Display Preferences',
      icon: Icons.desktop_windows,
      children: [
        _buildSwitchSettingTile(
          title: 'Network Statistics',
          subtitle: 'Show network stats on dashboard',
          value: _showNetworkStats,
          onChanged: (value) {
            setState(() {
              _showNetworkStats = value;
            });
          },
          icon: Icons.analytics,
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.speed, color: Theme.of(context).primaryColor),
          ),
          title: Text('Chart Update Frequency', style: TextStyle(color: textColor)),
          subtitle: Text('${_chartUpdateFrequency.toInt()} seconds', style: TextStyle(color: textColorSecondary)),
          onTap: () {},
        ),
        Slider(
          value: _chartUpdateFrequency,
          min: 5,
          max: 60,
          divisions: 11,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor.withOpacity(0.2),
          label: '${_chartUpdateFrequency.toInt()} seconds',
          onChanged: (value) {
            setState(() {
              _chartUpdateFrequency = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildEnergyTradingSection(Color textColor, Color textColorSecondary) {
    return _buildSettingsCard(
      title: 'Energy Trading',
      icon: Icons.bolt,
      children: [
        _buildSwitchSettingTile(
          title: 'Auto-Accept Optimal Trades',
          subtitle: 'Automatically accept trades that match your criteria',
          value: _autoAcceptTrades,
          onChanged: (value) {
            setState(() {
              _autoAcceptTrades = value;
            });
          },
          icon: Icons.auto_awesome,
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: Theme.of(context).primaryColor),
          ),
          title: Text('Trade Preferences', style: TextStyle(color: textColor)),
          subtitle: Text('Configure your trading parameters', style: TextStyle(color: textColorSecondary)),
          trailing: Icon(Icons.arrow_forward_ios, color: textColorSecondary, size: 16),
          onTap: () {
            // Navigate to trade preferences screen
          },
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payment, color: Theme.of(context).primaryColor),
          ),
          title: Text('Payment Methods', style: TextStyle(color: textColor)),
          subtitle: Text('Manage your payment options', style: TextStyle(color: textColorSecondary)),
          trailing: Icon(Icons.arrow_forward_ios, color: textColorSecondary, size: 16),
          onTap: () {
            // Navigate to payment methods screen
          },
        ),
      ],
    );
  }
  
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: TextStyle(color: themeProvider.textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: themeProvider.textColorSecondary)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
  
  Widget _buildDropdownSettingTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<Object?> onChanged,
    required IconData icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: TextStyle(color: themeProvider.textColor)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: TextStyle(color: themeProvider.textColorSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: themeProvider.isDarkMode 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: themeProvider.isDarkMode 
                  ? const Color(0xFF2A0030) 
                  : Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: themeProvider.textColor),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode 
            ? const Color(0xFF2A0030)
            : Colors.white,
        title: Text('Delete Account', 
          style: TextStyle(color: themeProvider.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: TextStyle(color: themeProvider.textColor),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type "DELETE" to confirm',
                hintStyle: TextStyle(color: themeProvider.textColorSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: themeProvider.isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
              style: TextStyle(color: themeProvider.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  AppBar _buildAppBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return AppBar(
      backgroundColor: themeProvider.isDarkMode ? Colors.black26 : Theme.of(context).primaryColor,
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
          SizedBox(width: 8),
          Text('PIONEER Dashboard'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
        _buildWalletButton(context),
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
              onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWalletButton(BuildContext context) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Drawer(
      backgroundColor: const Color(0xFF2A0030),
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
              _buildNavItem(context, 'Dashboard', Icons.dashboard, false, "/home"),
              _buildNavItem(context, 'User Profile', Icons.person, false, "/profile"),
              _buildNavItem(context, 'Analytics', Icons.analytics, false, ""),
              _buildNavItem(context, 'Wallet', Icons.account_balance_wallet, false, ""),
              _buildNavItem(context, 'Transactions', Icons.history, false, "/transactions"),
              _buildNavItem(context, 'Chat', Icons.chat, false, "/chat"),
              _buildNavItem(context, 'Settings', Icons.settings, true, "/settings"),
              _buildNavItem(context, 'Support', Icons.support, false, ""),
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
            onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
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
        // Handle navigation
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}