import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/cognito_service.dart';
import '../Services/theme_provider.dart';
import '../Services/user_service.dart';
import '../Services/metamask.dart';
import '../Widgets/animated_background.dart';
import '../Widgets/animated_background_light.dart';
import '../Services/blockchain_service.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const ProfilePage({
    super.key, 
    required this.userData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  bool _showProfileIncompleteMessage = false;
  bool _isLoading = false;
  
  // User profile data - merge with Cognito data in initState
  late Map<String, dynamic> _userData;
  
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _landlineController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _apartmentController;
  late TextEditingController _walletAddressController;
  late TextEditingController _productionCapacityController;
  late TextEditingController _userIdController;

  // Add BlockchainService
  late final BlockchainService _blockchainService;
  bool _isWalletConnected = false;
  String? _currentWalletAddress;
  String? _currentBalance;
  int? _currentChainId;

  @override
  void initState() {
    super.initState();
    
    // Debug the userData contents to see what's available
    print("DEBUG - User data keys: ${widget.userData.keys.toList()}");
    
    // Extract user ID from multiple possible sources in Cognito tokens
    final userId = widget.userData['sub'] ?? 
                  widget.userData['user_id'] ??
                  widget.userData['cognito:sub'] ?? '';
                    
    print("DEBUG - User ID found: $userId"); // Debug user ID
    
    // Check if profile is incomplete
    _showProfileIncompleteMessage = _userService.isProfileIncomplete(widget.userData);
    
    // Get username from the correct place in userData
    final username = widget.userData['cognito:username'] ?? 
                    widget.userData['username'] ?? '';
                    
    print("DEBUG - Username found: $username"); // Debug print
    
    // Initialize with proper null checks for all values
    _userData = {
      // Personal information
      'firstName': widget.userData['first_name'] ?? '',
      'lastName': widget.userData['last_name'] ?? '',
      'email': widget.userData['email'] ?? '',
      'username': username, // Use the correctly extracted username
      'phone_number': widget.userData['phone_number'] ?? '',
      'landline': widget.userData['landline'] ?? '',
      'user_id': userId, // Store user ID from Cognito sub claim
      
      // Address information
      'street': widget.userData['street'] ?? '',
      'building': widget.userData['building'] ?? '',
      'apartment': widget.userData['apartment'] ?? '',
      'city': widget.userData['city'] ?? '',
      'province_state': widget.userData['province_state'] ?? '',
      'floor': widget.userData['floor']?.toString() ?? '',
      
      // Energy information
      'total_production_capacity': widget.userData['total_production_capacity']?.toString() ?? '0',
      'web_3_wallet_address': widget.userData['web_3_wallet_address'] ?? '',
      
      // Default profile picture if none is provided
      'profilePicUrl': 'https://i.pravatar.cc/150?img=11',
      
      // Additional data
      'user_id': widget.userData['user_id'] ?? '',
      // Default values for stats that might not be in the API response
      'address': widget.userData['web_3_wallet_address'] ?? 'Not connected',
      'energyProduced': 1240.5,
      'energyConsumed': 890.2,
      'tokensEarned': 250,
      'joinDate': DateTime(2024, 1, 15),
    };
    
    // Initialize all controllers with null safety
    _firstNameController = TextEditingController(text: _userData['firstName']);
    _lastNameController = TextEditingController(text: _userData['lastName']);
    _emailController = TextEditingController(text: _userData['email']);
    _usernameController = TextEditingController(text: username); // Set with correct username
    _phoneController = TextEditingController(text: _userData['phone_number']);
    _landlineController = TextEditingController(text: _userData['landline']);
    _streetController = TextEditingController(text: _userData['street']);
    _cityController = TextEditingController(text: _userData['city']);
    _provinceController = TextEditingController(text: _userData['province_state']);
    _buildingController = TextEditingController(text: _userData['building']);
    _floorController = TextEditingController(text: _userData['floor']);
    _apartmentController = TextEditingController(text: _userData['apartment']);
    _walletAddressController = TextEditingController(text: _userData['web_3_wallet_address']);
    _productionCapacityController = TextEditingController(text: _userData['total_production_capacity']);
    _userIdController = TextEditingController(text: userId);

    // Initialize blockchain service
    _blockchainService = BlockchainService();
    _blockchainService.addListener(_onBlockchainStateChanged);
    
    // Check if wallet is already connected (persistence)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWalletConnection();
    });
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _landlineController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _walletAddressController.dispose();
    _productionCapacityController.dispose();
    _userIdController.dispose();
    _blockchainService.removeListener(_onBlockchainStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return ChangeNotifierProvider<MetaMaskProvider>(
      create: (context) => MetaMaskProvider()..init(),
      builder: (context, child) {
        return Stack(
          children: [
            if (isDarkMode) const AnimatedBackground() else const AnimatedBackgroundLight(),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('User Profile', 
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: themeProvider.textColor)),
                                _isEditing 
                                  ? _buildEditingButtons() 
                                  : ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                      icon: const Icon(Icons.edit, color: Colors.white),
                                      label: const Text('Edit Profile'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5C005C),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Profile content
                            _buildProfileContent(context, isMobile),
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
  
  Widget _buildEditingButtons() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Row(
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isEditing = false;
              // Reset controllers to original values
              _firstNameController.text = _userData['firstName'];
              _lastNameController.text = _userData['lastName'];
              _emailController.text = _userData['email'];
              _usernameController.text = _userData['username'];
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: themeProvider.textColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Cancel', style: TextStyle(color: themeProvider.textColor)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C005C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
  
  Widget _buildProfileContent(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Profile incomplete banner
        if (_showProfileIncompleteMessage)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Your profile is incomplete. Please provide the missing information to complete your setup.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Complete Now'),
                ),
              ],
            ),
          ),
        
        // Existing layout builder
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              // Desktop layout: side-by-side
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildUserInfoCard(),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        _buildAccountSecurityCard(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Mobile layout: stacked
              return Column(
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 24),
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildAccountSecurityCard(),
                ],
              );
            }
          }
        ),
      ],
    );
  }
  
  Widget _buildUserInfoCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A0030).withOpacity(0.7),
              const Color(0xff5e0b8b).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture section
            Center(
              child: Column(
                children: [
                  // Profile picture with edit option
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(_userData['profilePicUrl']),
                      ),
                      if (_isEditing)
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF5C005C),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: () {
                              // Add photo upload functionality
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Use the complete form here
            _buildProfileForm(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String? value, {bool isAddress = false}) {
  // Ensure value is never null
  final displayValue = value ?? 'Not provided';
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        displayValue,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: isAddress ? 'monospace' : null,
        ),
        overflow: isAddress ? TextOverflow.ellipsis : TextOverflow.clip,
      ),
    ],
  );
}
  
  Widget _buildStatsCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A0030).withOpacity(0.7),
              const Color(0xff5e0b8b).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              icon: Icons.energy_savings_leaf,
              title: 'Energy Produced',
              value: '${_userData['energyProduced']} kWh',
              iconColor: Colors.green,
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildStatItem(
              icon: Icons.electric_bolt,
              title: 'Energy Consumed',
              value: '${_userData['energyConsumed']} kWh',
              iconColor: Colors.orange,
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildStatItem(
              icon: Icons.token,
              title: 'Tokens Earned',
              value: '${_userData['tokensEarned']}',
              iconColor: Colors.blue,
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildStatItem(
              icon: Icons.calendar_month,
              title: 'Member Since',
              value: '${_userData['joinDate'].day}/${_userData['joinDate'].month}/${_userData['joinDate'].year}',
              iconColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAccountSecurityCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A0030).withOpacity(0.7),
              const Color(0xff5e0b8b).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildSecurityItem(
              title: 'Change Password',
              subtitle: 'Last changed 30 days ago',
              icon: Icons.lock,
            ),
            _buildSecurityItem(
              title: 'Two-Factor Authentication',
              subtitle: 'Enabled',
              icon: Icons.security,
              isEnabled: true,
            ),
            _buildSecurityItem(
              title: 'Recovery Email',
              subtitle: 'Set up a backup email',
              icon: Icons.email,
              isEnabled: false,
            ),
            _buildSecurityItem(
              title: 'Login Notifications',
              subtitle: 'Get notified of new logins',
              icon: Icons.notifications,
              isEnabled: true,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isEnabled = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          trailing: isEnabled
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          onTap: () {
            // If it's the password change item, show the dialog
            if (title == 'Change Password') {
              showChangePasswordDialog(context);
            }
          },
        ),
        if (!isLast)
          const Divider(color: Colors.white24, height: 1),
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
    
    if (_isWalletConnected) {
      // Connected state
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
      // Disconnected state
      return IconButton(
        icon: Icon(Icons.wallet, color: themeProvider.textColor),
        onPressed: _connectWallet,
      );
    }
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
              _buildNavItem(context, 'Dashboard', Icons.dashboard, false,"/home"),
              _buildNavItem(context, 'User Profile', Icons.person, true,"/profile"),
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
        // Example of navigation from HomePage to ProfilePage with userData
        Navigator.pushNamed(
          context, 
          route,
          arguments: widget.userData
        );
      },
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,  // Use controller instead of initialValue
                  decoration: const InputDecoration(labelText: 'First Name'),
                  enabled: _isEditing,
                  validator: _isEditing ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  } : null,
                  style: const TextStyle(color: Colors.white), // Change text color to white
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,  // Use controller instead of initialValue
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  enabled: _isEditing,
                  validator: _isEditing ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  } : null,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.userData['email'] ?? '',
            decoration: const InputDecoration(labelText: 'Email'),
            enabled: false, // Email shouldn't be editable as it's the primary identifier
            style: const TextStyle(color: Colors.white),
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController, // Use the controller instead of initialValue
            decoration: const InputDecoration(labelText: 'Username'),
            enabled: false, // Username shouldn't be editable
            style: const TextStyle(color: Colors.white),
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.userData['phone_number'] ?? '',
            decoration: const InputDecoration(labelText: 'Phone Number'),
            enabled: _isEditing,
            style: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 16),
          TextFormField(
            controller: _landlineController,  // Use controller instead of initialValue
            decoration: const InputDecoration(labelText: 'Landline Number'),
            enabled: _isEditing,
            style: const TextStyle(color: Colors.white),
          ),
          
          // const SizedBox(height: 16),
          // TextFormField(
          //   initialValue: widget.userData['user_id'] ?? '',
          //   decoration: const InputDecoration(labelText: 'User ID'),
          //   enabled: false, // User ID should never be editable
          // ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _userIdController,
            decoration: const InputDecoration(labelText: 'User ID'),
            enabled: false, // User ID should never be editable
            style: const TextStyle(color: Colors.white),
          ),
          
          // Address Information
          const SizedBox(height: 24),
          const Text(
            'Address Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(labelText: 'Street'),
            enabled: _isEditing,
            validator: _isEditing ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your street';
              }
              return null;
            } : null,
            style: const TextStyle(color: Colors.white),
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _buildingController,  // Use controller instead of initialValue
            decoration: const InputDecoration(labelText: 'Building'),
            enabled: _isEditing,
            validator: _isEditing ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your building';
              }
              return null;
            } : null,
            style: const TextStyle(color: Colors.white),
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _apartmentController,  // Use controller instead of initialValue
            decoration: const InputDecoration(labelText: 'Apartment'),
            enabled: _isEditing,
            validator: _isEditing ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your apartment';
              }
              return null;
            } : null,
            style: const TextStyle(color: Colors.white),
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  enabled: _isEditing,
                  validator: _isEditing ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  } : null,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(labelText: 'Province/State'),
                  enabled: _isEditing,
                  validator: _isEditing ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your province/state';
                    }
                    return null;
                  } : null,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _floorController,
            decoration: const InputDecoration(labelText: 'Floor'),
            enabled: _isEditing,
            validator: _isEditing ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your floor';
              }
              return null;
            } : null,
            style: const TextStyle(color: Colors.white),
          ),
          
          // Energy Information
          const SizedBox(height: 24),
          const Text(
            'Energy Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _productionCapacityController,
            decoration: const InputDecoration(labelText: 'Total Production Capacity'),
            enabled: _isEditing, // This is typically controlled by the system
            style: const TextStyle(color: Colors.white),
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _walletAddressController,
            decoration: const InputDecoration(labelText: 'Web3 Wallet Address'),
            enabled: _isEditing,
            validator: _isEditing ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your web3 wallet address';
              }
              return null;
            } : null,
            style: const TextStyle(color: Colors.white),
          ),
          
          // Action buttons
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isEditing && !_isLoading ? _saveProfile : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C005C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : const Text('Save Changes'),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _isEditing && !_isLoading ? () {
            setState(() {
              _isEditing = false;
            });
          } : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _saveProfile() async {
  if (_formKey.currentState!.validate()) {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final username = _usernameController.text;
      
      if (username.isEmpty) {
        throw Exception('Username is required');
      }
      
      // Prepare profile data for API
      final profileData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone_number': _phoneController.text,
        'landline': _landlineController.text,
        'street': _streetController.text,
        'city': _cityController.text,
        'province_state': _provinceController.text,
        'building': _buildingController.text,
        'floor': int.tryParse(_floorController.text ?? '') ?? 0,
        'apartment': _apartmentController.text,
        'web_3_wallet_address': _walletAddressController.text,
        'total_production_capacity': int.tryParse(
            _productionCapacityController.text.replaceAll(' kWh', '').trim() ?? '0'
        ) ?? 0,
      };

      debugPrint("Profile data to be sent: $profileData");
      
      // Call API to update profile
      final updatedData = await _userService.updateUserProfile(
        username,
        profileData,
      );
      
      // Clear cached data and reload it to ensure consistency
      await _userService.clearUserData();
      final refreshedData = await _userService.getUserData(username);
      
      // Update local data
      setState(() {
        _isLoading = false;
        _isEditing = false;
        _showProfileIncompleteMessage = false;
        
        // Update userData with refreshed data
        if (refreshedData != null) {
          widget.userData.clear();
          widget.userData.addAll(refreshedData);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Add this as a shared utility method or extension
Future<void> showChangePasswordDialog(BuildContext context) async {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A0030),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Change Password', 
              style: TextStyle(color: Colors.white)
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        helperText: 'Must be at least 8 characters with letters, numbers, and symbols',
                        helperStyle: TextStyle(color: Colors.grey),
                      ),
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        // Password regex pattern for AWS Cognito
                        final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');
                        if (!regex.hasMatch(value)) {
                          return 'Password must be at least 8 characters with uppercase, lowercase, numbers, and symbols';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading 
                  ? null 
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        
                        try {
                          final cognitoService = CognitoService();
                          final result = await cognitoService.changePassword(
                            currentPassword: _currentPasswordController.text,
                            newPassword: _newPasswordController.text,
                          );
                          
                          if (result) {
                            Navigator.pop(context, true);
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = e.toString();
                          });
                        }
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C005C),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Change Password'),
              ),
            ],
          );
        }
      );
    },
  );
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
}