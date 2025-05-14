import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Services/blockchain_service.dart';
import '../Services/cognito_service.dart';
import '../Services/theme_provider.dart';
import '../Widgets/animated_background.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../Widgets/animated_background_light.dart';

class TransactionPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TransactionPage({super.key, required this.userData});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  // Filter values
  RangeValues _priceRange = const RangeValues(0, 1000000);
  RangeValues _amountRange = const RangeValues(0, 1000000);
  String _searchQuery = '';
  String _filterType = 'All'; // All, Buy, Sell
  
  // Filtered offers list
  List<Map<String, dynamic>> _filteredOffers = [];

  // All offers list
  List<Map<String, dynamic>> _allOffers = [];
  
  // Mock offers data for fallback
  final List<Map<String, dynamic>> _offers = [
    {
      'id': '1',
      'offerType': 'Sell',
      'energyAmount': 200,
      'price': 80.0,
      'pricePerUnit': 0.40,
      'user': '0x7d5F...E34a',
      'description': 'Solar energy surplus from my home system',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'creatorUsername': '0x7d5F...E34a',
    },
    {
      'id': '2',
      'offerType': 'Buy',
      'energyAmount': 150,
      'price': 45.0,
      'pricePerUnit': 0.30,
      'user': '0x3c2B...A71c',
      'description': 'Looking for renewable energy for my business',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'creatorUsername': '0x3c2B...A71c',
    },
    {
      'id': '3',
      'offerType': 'Sell',
      'energyAmount': 75,
      'price': 22.5,
      'pricePerUnit': 0.30,
      'user': '0x8a1D...F52b',
      'description': 'Wind energy from community farm',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'creatorUsername': '0x8a1D...F52b',
    },
  ];

  // Add these variables to the _TransactionPageState class
  bool _showTransactionHistory = false;
  bool _isLoading = false; // Variable to track loading state
  bool _isLoadingAgreements = false;
  bool _showAvailableOffers = true;
  bool _showAgreements = true;
  List<Map<String, dynamic>> _userAgreements = [];
  final List<Map<String, dynamic>> _transactionHistory = [
    {
      'id': 'TX001',
      'type': 'Buy',
      'amount': 50.0,
      'price': 15.50,
      'totalPrice': 15.50,
      'counterparty': '0x8e4F...C23a',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'Completed',
    },
    {
      'id': 'TX002',
      'type': 'Sell',
      'amount': 120.0,
      'price': 0.29,
      'totalPrice': 34.80,
      'counterparty': '0x2c5D...A91b',
      'timestamp': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'Completed',
    },
    {
      'id': 'TX003',
      'type': 'Buy',
      'amount': 75.5,
      'price': 0.31,
      'totalPrice': 23.41,
      'counterparty': '0x7a3B...F42c',
      'timestamp': DateTime.now().subtract(const Duration(days: 14)),
      'status': 'Completed',
    },
  ];

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Offer creation variables
  String _offerType = 'Sell'; // Default to sell
  double _energyAmount = 0;
  double _price = 0; // Define _price variable
  double _pricePerUnit = 0;
  String _description = '';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _showOwnOffers = true;

  // Instance of blockchain service
  final BlockchainService _blockchainService = BlockchainService();

  // Loading indicator
  bool _isCreatingOffer = false;
  bool _isWalletConnected = false;
  String? _currentWalletAddress;
  int? _currentChainId;
  String? _currentBalance;

  @override
void initState() {
  super.initState();
  
  // Initialize tabs
  _showAvailableOffers = true;
  _showAgreements = false;
  _showTransactionHistory = false;
  
  _initializeBlockchain();
}

  Future<void> _initializeBlockchain() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _blockchainService.initialize();
      
      // Setup listener for blockchain connection changes
      _blockchainService.addListener(_onBlockchainStateChanged);
      
      setState(() {
        _isWalletConnected = _blockchainService.isConnected;
        _currentWalletAddress = _blockchainService.currentAddress;
        _currentChainId = _blockchainService.currentChainId;
        _currentBalance = _blockchainService.currentBalance;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing blockchain: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onBlockchainStateChanged() {
  final wasConnected = _isWalletConnected;
  final isNowConnected = _blockchainService.isConnected;
  
  setState(() {
    _isWalletConnected = isNowConnected;
    _currentWalletAddress = _blockchainService.currentAddress;
    _currentChainId = _blockchainService.currentChainId;
    _currentBalance = _blockchainService.currentBalance;
  });
  
  // If wallet just got connected, load offers
  if (!wasConnected && isNowConnected) {
    _loadActiveOffers();
  }
}
  
  @override
  void dispose() {
    // Remove listener when widget is disposed
    _blockchainService.removeListener(_onBlockchainStateChanged);
    super.dispose();
  }
  
  Future<void> _connectWallet() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final success = await _blockchainService.connectWallet();
    
    if (success) {
      setState(() {
        _isWalletConnected = true;
        _currentWalletAddress = _blockchainService.currentAddress;
        _currentChainId = _blockchainService.currentChainId;
        _currentBalance = _blockchainService.currentBalance;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet connected successfully')),
      );
      
      // Load offers after successful connection
      _loadActiveOffers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect wallet')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error connecting wallet: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  
  Future<void> _switchNetwork(int targetChainId) async {
    try {
      final success = await _blockchainService.switchNetwork(targetChainId);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch network')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching network: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

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
                        
                        // Create offer section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Energy Transactions', 
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: themeProvider.textColor)),
                            ElevatedButton.icon(
                              onPressed: _isWalletConnected ? _showCreateOfferDialog : _connectWallet,
                              icon: Icon(_isWalletConnected ? Icons.add : Icons.wallet, color: Colors.white),
                              label: Text(_isWalletConnected ? 'Create Offer' : 'Connect Wallet'),
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
                        
                        // Filter section
                        _buildFilterSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Offers list
                        _buildOffersSection(isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isWalletConnected ? _showCreateOfferDialog : _connectWallet,
            label: Text(_isWalletConnected ? 'Create Offer' : 'Connect Wallet', style: TextStyle(color: Colors.white)),
            icon: Icon(_isWalletConnected ? Icons.add : Icons.wallet, color: Colors.white),
            backgroundColor: const Color(0xFF5C005C),
          ),
        ),
      ],
    );
  }

  void _showCreateOfferDialog() {
  // Reset form values
  _offerType = 'Sell';
  _energyAmount = 0;
  _pricePerUnit = 0;
  _description = '';
  _startDate = DateTime.now().add(const Duration(days: 1));
  _endDate = DateTime.now().add(const Duration(days: 7));
  
  // Create controllers for the form fields
  final TextEditingController amountController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF2A0030),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Energy Offer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Offer Type
                    Row(
                      children: [
                        const Text('Offer Type:', style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 16),
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF5C005C),
                          selectedBorderColor: const Color(0xFF5C005C),
                          borderColor: Colors.grey,
                          constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
                          isSelected: [_offerType == 'Sell', _offerType == 'Buy'],
                          onPressed: (index) {
                            setState(() {
                              _offerType = index == 0 ? 'Sell' : 'Buy';
                            });
                          },
                          children: const [
                            Text('Sell', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Energy Amount
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Energy Amount (kWh)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple.shade800),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _energyAmount = double.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Price per Unit
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Price per kWh (tokens)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple.shade800),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _pricePerUnit = double.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple.shade800),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      onSaved: (value) {
                        _description = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Range
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.dark(
                                            primary: Colors.purple.shade300,
                                            onPrimary: Colors.white,
                                            surface: const Color(0xFF2A0030),
                                            onSurface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  
                                  if (pickedDate != null) {
                                    setState(() {
                                      _startDate = pickedDate;
                                      // Ensure end date is after start date
                                      if (_endDate.isBefore(_startDate)) {
                                        _endDate = _startDate.add(const Duration(days: 1));
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.purple.shade800),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(_startDate),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Date', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: _startDate,
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.dark(
                                            primary: Colors.purple.shade300,
                                            onPrimary: Colors.white,
                                            surface: const Color(0xFF2A0030),
                                            onSurface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  
                                  if (pickedDate != null) {
                                    setState(() {
                                      _endDate = pickedDate;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.purple.shade800),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(_endDate),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Total Price Display
                    if (amountController.text.isNotEmpty && priceController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Total: ${(double.tryParse(amountController.text) ?? 0) * (double.tryParse(priceController.text) ?? 0)} tokens',
                          style: TextStyle(color: Colors.purple.shade300, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                    const SizedBox(height: 24),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isCreatingOffer 
                              ? null 
                              : () => _createOffer(context),
                          child: _isCreatingOffer
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Offer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Future<void> _createOffer(BuildContext dialogContext) async {
    // Check form validity
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Save form values
    _formKey.currentState?.save();
    
    setState(() {
      _isCreatingOffer = true;
    });
    
    try {
      // Check if wallet is connected
      if (!_isWalletConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please connect your wallet first')),
        );
        setState(() {
          _isCreatingOffer = false;
        });
        return;
      }

      // Check if on correct network (Holesky testnet has chain ID 17000)
      if (_currentChainId != 17000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please switch to Holesky testnet')),
        );
        
        // Attempt to switch networks
        await _switchNetwork(17000);
        
        setState(() {
          _isCreatingOffer = false;
        });
        return;
      }
      
      // Calculate total price (amount * price per unit)
      final totalPrice = _energyAmount * _pricePerUnit;
      
      // Convert to appropriate format for blockchain (assuming energy amount and price as BigInt with 18 decimals)
      final energyAmountBigInt = BigInt.from(_energyAmount);
      final pricePerUnitBigInt = BigInt.from(_pricePerUnit * 1e18);
      
      // Convert dates to Unix timestamps (seconds since epoch)
      final startTimeBigInt = BigInt.from(_startDate.millisecondsSinceEpoch ~/ 1000);
      final endTimeBigInt = BigInt.from(_endDate.millisecondsSinceEpoch ~/ 1000);
      
      // Map offer type to integer enum value (0 for Sell, 1 for Buy)
      final offerTypeInt = _offerType == 'Sell' ? 1 : 0;
      
      // Call the createOffer function
      final txHash = await _blockchainService.createOffer(
        offerTypeInt,
        energyAmountBigInt,
        pricePerUnitBigInt,
        startTimeBigInt,
        endTimeBigInt
      );
      
      setState(() {
        _isCreatingOffer = false;
      });
      
      // Close the dialog
      Navigator.pop(dialogContext);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer created successfully! Transaction: ${txHash.substring(0, 10)}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Use the current chain ID to determine which explorer to use
              final explorerUrl = _currentChainId == 17000
                  ? 'https://holesky.etherscan.io/tx/$txHash'
                  : 'https://etherscan.io/tx/$txHash';
              launch(explorerUrl);
            },
          ),
        ),
      );
      
      // Refresh the offers list
      _loadActiveOffers();
      
    } catch (e) {
      setState(() {
        _isCreatingOffer = false;
      });
      
      String errorMessage = e.toString();
      // Clean up error message for display
      if (errorMessage.contains('execution reverted')) {
        errorMessage = 'Transaction rejected by the blockchain. Check your parameters.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating offer: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      debugPrint('Detailed error creating offer: $e');
    }
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
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _showCreateOfferDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Offer'),
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
    
    if (_isWalletConnected && _currentWalletAddress != null) {
      // Connected state
      
      debugPrint('Balance from page: $_currentBalance');
      String displayAddress = (_currentBalance!.length>7) ?_currentBalance!.substring(0,6): _currentBalance!;
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
            displayAddress,
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
              Navigator.pop(context);
              _switchNetwork(17000); // Holesky testnet
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
  
  // Mobile version of wallet button
  Widget _buildMobileWalletButton(BuildContext context) {
    if (_isWalletConnected && _currentWalletAddress != null) {
      String displayAddress = '${_currentWalletAddress!.substring(0, 6)}...${_currentWalletAddress!.substring(_currentWalletAddress!.length - 4)}';
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
            displayAddress,
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
              _buildNavItem(context, 'Dashboard', Icons.dashboard, false,"/home"),
              _buildNavItem(context, 'User Profile', Icons.person, false,"/profile"),
              _buildNavItem(context, 'Analytics', Icons.analytics, false,""),
              _buildNavItem(context, 'Wallet', Icons.account_balance_wallet, false,""),
              _buildNavItem(context, 'Transactions', Icons.history, true,"/transactions"),
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
  
  
  
  Widget _buildEnergyAmountField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Energy Amount (kWh)',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        prefixIcon: const Icon(Icons.bolt, color: Colors.yellow),
        suffixText: 'kWh',
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _energyAmount = double.tryParse(value) ?? 0;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }
  
  Widget _buildPriceField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Price (USD)',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          _price = double.tryParse(value) ?? 0;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      },
    );
  }
  
  Widget _buildFilterSection() {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Offers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                
                if (isMobile) {
                  return Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 16),
                      _buildTypeFilter(),
                      const SizedBox(height: 16),
                      _buildPriceRangeFilter(),
                      const SizedBox(height: 16),
                      _buildAmountRangeFilter(),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 3, child: _buildSearchField()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildTypeFilter()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildPriceRangeFilter()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildAmountRangeFilter()),
                        ],
                      ),
                    ],
                  );
                }
              }
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _showOwnOffers,
                  activeColor: Colors.purple,
                  checkColor: Colors.white,
                  onChanged: (bool? value) {
                    setState(() {
                      _showOwnOffers = value ?? true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Show my own offers',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      // Reset filter values
                      _priceRange = const RangeValues(0, 1000000);
                      _amountRange = const RangeValues(0, 1000000);
                      _searchQuery = '';
                      _filterType = 'All';
                      _showOwnOffers = true;
                      
                      // Reset filtered offers to show all offers
                      _filteredOffers = List.from(_allOffers);
                    });
                  },
                  child: const Text('Reset Filters'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C005C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    // Apply the filters
                    _applyFilters();
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Found ${_filteredOffers.length} matching offers'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.filter_list),
                      SizedBox(width: 8),
                      Text('Apply Filters'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by address or description',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }
  
  Widget _buildTypeFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          dropdownColor: const Color(0xFF2A0030),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              _filterType = newValue!;
            });
          },
          items: <String>['All', 'Buy', 'Sell']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Range (USD)', 
          style: TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('\$${_priceRange.start.toInt()}', 
              style: const TextStyle(color: Colors.white)),
            Expanded(
              child: RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000000,
                divisions: 100,
                activeColor: Colors.purple,
                inactiveColor: Colors.purple.withOpacity(0.2),
                labels: RangeLabels(
                  '\$${_priceRange.start.toInt()}',
                  '\$${_priceRange.end.toInt()}',
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
              ),
            ),
            Text('\$${_priceRange.end.toInt()}', 
              style: const TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Energy Amount (kWh)', 
          style: TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('${_amountRange.start.toInt()}', 
              style: const TextStyle(color: Colors.white)),
            Expanded(
              child: RangeSlider(
                values: _amountRange,
                min: 0,
                max: 1000000,
                divisions: 50,
                activeColor: Colors.purple,
                inactiveColor: Colors.purple.withOpacity(0.2),
                labels: RangeLabels(
                  '${_amountRange.start.toInt()} kWh',
                  '${_amountRange.end.toInt()} kWh',
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _amountRange = values;
                  });
                },
              ),
            ),
            Text('${_amountRange.end.toInt()}', 
              style: const TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }
  
    Widget _buildOffersSection(bool isMobile) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab switcher with 3 tabs
          Row(
            children: [
              Expanded(
                child: _buildTabSelector(
                  title: "Available Offers",
                  isActive: _showAvailableOffers,
                  onTap: () {
                    setState(() {
                      _showAvailableOffers = true;
                      _showAgreements = false;
                      _showTransactionHistory = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildTabSelector(
                  title: "Agreements",
                  isActive: _showAgreements,
                  onTap: () {
                    setState(() {
                      _showAvailableOffers = false;
                      _showAgreements = true;
                      _showTransactionHistory = false;
                    });
                    
                    // Load agreements when tab is selected
                    if (_isWalletConnected) {
                      _loadUserAgreements();
                    }
                  },
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildTabSelector(
                  title: "Transaction History",
                  isActive: _showTransactionHistory,
                  onTap: () {
                    setState(() {
                      _showAvailableOffers = false;
                      _showAgreements = false;
                      _showTransactionHistory = true;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Different content based on selected tab
          if (_showAvailableOffers)
            _buildAvailableOffersSection(isMobile)
          else if (_showAgreements)
            _buildAgreementsSection(isMobile)
          else
            _buildTransactionHistorySection(isMobile),
        ],
      ),
    ),
  );
}

Widget _buildTabSelector({required String title, required bool isActive, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFF5C005C)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.white30,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}

// Split the original offers section content into a new method
// Modify the _buildAvailableOffersSection method

Widget _buildAvailableOffersSection(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Available Offers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              // Show refresh button only when connected
              if (_isWalletConnected)
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoading ? Colors.purple.shade300 : Colors.white,
                  ),
                  tooltip: 'Refresh offers',
                  onPressed: _isLoading
                      ? null
                      : _loadActiveOffers,
                ),
              const SizedBox(width: 8),
              Text(
                '${_filteredOffers.length} offers found',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Show connection prompt if wallet not connected
      if (!_isWalletConnected)
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wallet,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect your wallet to view available energy offers',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C005C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _connectWallet,
              ),
            ],
          ),
        )
      else
        isMobile ? _buildOffersCardList() : _buildOffersTable(),
    ],
  );
}

// Add a new section for transaction history
Widget _buildTransactionHistorySection(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaction History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${_transactionHistory.length} transactions',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      const SizedBox(height: 16),
      isMobile 
          ? _buildTransactionHistoryCardList() 
          : _buildTransactionHistoryTable(),
    ],
  );
}

Widget _buildTransactionHistoryTable() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      
      return Container(
        width: availableWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF5C005C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth),
            child: DataTable(
              columnSpacing: 16,
              dataRowHeight: 70,
              headingRowHeight: 56,
              horizontalMargin: 24,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF5C005C).withOpacity(0.2),
              ),
              columns: const [
                DataColumn(
                  label: Text('Transaction ID', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Type', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Amount (kWh)', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Price/kWh', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Total', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Counterparty', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Date', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Status', style: TextStyle(color: Colors.white)),
                ),
              ],
              rows: _transactionHistory.map((tx) => _buildTransactionRow(tx)).toList(),
            ),
          ),
        ),
      );
    }
  );
}

DataRow _buildTransactionRow(Map<String, dynamic> tx) {
  final isBuyType = tx['type'] == 'Buy';
  final formattedTime = _formatTimestamp(tx['timestamp']);
  
  return DataRow(
    cells: [
      DataCell(
        Text(
          tx['id'],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isBuyType ? Colors.blue : Colors.green).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tx['type'],
            style: TextStyle(
              color: isBuyType ? Colors.blue : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          '${tx['amount'].toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      DataCell(
        Text(
          '\$${tx['price'].toStringAsFixed(3)}/kWh',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          '\$${tx['totalPrice'].toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      DataCell(
        Text(
          tx['counterparty'],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      DataCell(
        Text(
          formattedTime,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(tx['status']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tx['status'],
            style: TextStyle(
              color: _getStatusColor(tx['status']),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTransactionHistoryCardList() {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _transactionHistory.length,
    itemBuilder: (context, index) {
      final tx = _transactionHistory[index];
      final isBuyType = tx['type'] == 'Buy';
      final formattedTime = _formatTimestamp(tx['timestamp']);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.black.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isBuyType ? Colors.blue : Colors.green).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tx['type'],
                      style: TextStyle(
                        color: isBuyType ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tx['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tx['status'],
                      style: TextStyle(
                        color: _getStatusColor(tx['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tx['id'],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${tx['amount'].toStringAsFixed(1)} kWh',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total: \$${tx['totalPrice'].toStringAsFixed(2)} (\$${tx['price'].toStringAsFixed(3)}/kWh)',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'With: ${tx['counterparty']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'failed':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
  
  Widget _buildOffersTable() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate width available for table
      final availableWidth = constraints.maxWidth;
      
      return Container(
        width: availableWidth, // Use the exact available width
        decoration: BoxDecoration(
          color: const Color(0xFF5C005C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth), // Force minimum width
            child: DataTable(
              columnSpacing: 16,
              dataRowHeight: 70,
              headingRowHeight: 56,
              horizontalMargin: 24,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF5C005C).withOpacity(0.2),
              ),
              columns: const [
                DataColumn(
                  label: Text('Type', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Amount (kWh)', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Price (USD)', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Price/kWh', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('User', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Description', style: TextStyle(color: Colors.white)),
                  // Make description column take more space
                  tooltip: 'Energy offer description',
                ),
                DataColumn(
                  label: Text('Posted', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Actions', style: TextStyle(color: Colors.white)),
                ),
              ],
              rows: _filteredOffers.map((offer) => _buildOfferRow(offer)).toList(),
            ),
          ),
        ),
      );
    }
  );
}
  
  DataRow _buildOfferRow(Map<String, dynamic> offer) {
    final isSellType = offer['offerType'] == 'Sell';
    final formattedTime = _formatTimestamp(offer['createdAt']);
    
    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isSellType ? Colors.green : Colors.blue).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              offer['offerType'] == 'Sell' ? 'Buy' : 'Sell',
              style: TextStyle(
                color: isSellType ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '${offer['energyAmount'].toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            '\$${offer['price'].toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            '\$${offer['pricePerUnit'].toStringAsFixed(3)}/kWh',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            offer['user'],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              offer['description'],
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            formattedTime,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        DataCell(
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Check if this offer belongs to the current user
                  offer['creator'].toString().toLowerCase() == _currentWalletAddress?.toLowerCase()
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Your Offer', style: TextStyle(color: Colors.white))
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C005C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            if (isSellType) {
                              _buyEnergy(offer); // This now calls acceptOfferDirectly
                            } else {
                              
                              _buyEnergy(offer); // This now calls acceptOfferDirectly
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   const SnackBar(content: Text('Selling to buy offers not yet implemented')),
                              // );
                            }
                          },
                          child: Text(isSellType ? 'Sell' : 'Buy'),
                        ),
                        // Chat button remains unchanged
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOffersCardList() {
  if (_isLoading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C005C)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading offers from blockchain...',
            style: TextStyle(color: Colors.white, fontSize: 16)
          )
        ],
      ),
    );
  }
  
  if (_filteredOffers.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No offers found matching your criteria',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Offers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C005C),
              foregroundColor: Colors.white,
            ),
            onPressed: _loadActiveOffers,
          ),
        ],
      ),
    );
  }
  
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _filteredOffers.length,
    itemBuilder: (context, index) {
      final offer = _filteredOffers[index];
      final isSellType = offer['offerType'] == 'Sell';
      final formattedTime = _formatTimestamp(offer['createdAt']);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.black.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isSellType ? Colors.green : Colors.blue).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      offer['offerType'],
                      style: TextStyle(
                        color: isSellType ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${offer['energyAmount'].toStringAsFixed(1)} kWh',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '\$${offer['price'].toStringAsFixed(2)} (\$${offer['pricePerUnit'].toStringAsFixed(3)}/kWh)',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    offer['user'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                offer['description'],
                style: const TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              offer['creator'].toString().toLowerCase() == _currentWalletAddress?.toLowerCase()
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Your Offer', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  )
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C005C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (isSellType) {
                                _buyEnergy(offer);
                              } else {
                                
                                _buyEnergy(offer);
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(content: Text('Selling to buy offers not yet implemented')),
                                // );
                              }
                            },
                            child: Text(isSellType ? 'Buy Now' : 'Sell Now'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Existing chat navigation code
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'user': offer['user'],
                            'offerId': offer['id'],
                            'offerType': offer['offerType'],
                          },
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Starting chat with ${offer["user"]} about ${offer["offerType"]} offer'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}
  
  String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) {
    return 'N/A'; // Return a placeholder for null timestamps
  }
  
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  
  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return DateFormat('MMM d, yyyy').format(timestamp);
  }
}

  Future<void> _loadActiveOffers() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Check if wallet is connected - attempt to connect if not
    if (!_isWalletConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your wallet to view offers')),
      );
      setState(() {
        _isLoading = false;
        _allOffers = _offers; // Use mock data as fallback
        _applyFilters();
      });
      return;
    }

    // Get active offer IDs
    final activeOfferIds = await _blockchainService.getActiveOffers();
    
    if (activeOfferIds.isEmpty) {
      setState(() {
        _isLoading = false;
        _allOffers = [];
        _filteredOffers = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active offers found on the blockchain')),
      );
      return;
    }
    
    List<Map<String, dynamic>> offers = [];
    
    // Loop through each offer ID and get details
    for (final offerId in activeOfferIds) {
      try {
        final offerDetails = await _blockchainService.getOfferDetails(offerId);
        
        // Convert the offer details to match our UI format
        final offerTypeInt = offerDetails['offerType'] as int;
        final offerStatusInt = offerDetails['status'] as int;
        
        // Convert timestamp from seconds to milliseconds for DateTime
        final createdAtDateTime = DateTime.fromMillisecondsSinceEpoch(
          (offerDetails['createdAt'] as BigInt).toInt() * 1000
        );
        
        // Convert blockchain values properly
        final energyAmount = (offerDetails['energyAmount'] as BigInt).toDouble();
        final pricePerUnit = (offerDetails['pricePerUnit'] as BigInt).toDouble() / 1e18;
        
        // Calculate USD price correctly instead of using blockchain's totalPrice
        final totalPrice = energyAmount * pricePerUnit;
        
        // Format creator address for display
        final creatorAddress = offerDetails['creator'];
        final shortAddress = '${creatorAddress.substring(0, 6)}...${creatorAddress.substring(creatorAddress.length - 4)}';
        final startDateTime = DateTime.fromMillisecondsSinceEpoch(
          (offerDetails['startTime'] as BigInt).toInt() * 1000
        );
        final endDateTime = DateTime.fromMillisecondsSinceEpoch(
          (offerDetails['endTime'] as BigInt).toInt() * 1000
        );
        
        final offer = {
          'id': offerId,
          'offerType': offerTypeInt == 0 ? 'Sell' : 'Buy',
          'energyAmount': energyAmount,
          'pricePerUnit': pricePerUnit,
          'price': totalPrice, // Use correctly calculated price
          'description': 'Energy ${offerTypeInt == 0 ? "sell" : "buy"} offer',
          'startTime': startDateTime,
          'endTime': endDateTime,
          'creator': offerDetails['creator'],
          'creatorUsername': offerDetails['creatorUsername'].toString().isEmpty ? shortAddress : offerDetails['creatorUsername'],
          'user': offerDetails['creatorUsername'].toString().isEmpty ? shortAddress : offerDetails['creatorUsername'],
          'status': offerStatusInt == 0 ? 'Active' : (offerStatusInt == 1 ? 'Accepted' : 'Cancelled'),
          'createdAt': createdAtDateTime,
          'timestamp': createdAtDateTime,
        };
        
        if (offerStatusInt == 0) { // Only add active offers
          offers.add(offer);
        }
      } catch (e) {
        print('Error loading offer $offerId: $e');
        // Continue with next offer
      }
    }
    
    setState(() {
      _allOffers = offers;
      _applyFilters(); // Apply filters to the loaded offers
      _isLoading = false;
    });
    
    if (offers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active offers found')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully loaded ${offers.length} offers')),
      );
    }
    
  } catch (e) {
    print('Error loading offers: $e');
    setState(() {
      _isLoading = false;
      
      // If we failed to load offers from blockchain, show at least the mock data
      _allOffers = _offers; // Use the mock data defined earlier
      _applyFilters();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading active offers: ${e.toString().substring(0, min(50, e.toString().length))}...'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

void _applyFilters() {
  // Start with all offers
  List<Map<String, dynamic>> filtered = List.from(_allOffers);
  
  // Apply owner filter if needed
  if (!_showOwnOffers && _currentWalletAddress != null) {
    filtered = filtered.where((offer) => 
      offer['creator'].toString().toLowerCase() != _currentWalletAddress!.toLowerCase()
    ).toList();
  }

  // Apply search query filter
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((offer) {
      return offer['creatorUsername'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             offer['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  // Apply offer type filter
  if (_filterType != 'All') {
    filtered = filtered.where((offer) => offer['offerType'] == _filterType).toList();
  }
  
  // Apply price range filter
  filtered = filtered.where((offer) {
    final price = offer['pricePerUnit'] as double;
    return price >= _priceRange.start && price <= _priceRange.end;
  }).toList();
  
  // Apply amount range filter - FIX HERE: Change from 'as int' to 'as double'
  filtered = filtered.where((offer) {
    final amount = offer['energyAmount'] as double; // Changed from int to double
    return amount >= _amountRange.start && amount <= _amountRange.end;
  }).toList();
  
  setState(() {
    _filteredOffers = filtered;
  });
}

Future<void> _buyEnergy(Map<String, dynamic> offer) async {
  if (!_isWalletConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please connect your wallet first')),
    );
    return;
  }
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Check if on correct network
    if (_currentChainId != 17000) { // 17000 is Holesky testnet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please switch to Holesky testnet')),
      );
      
      await _switchNetwork(17000);
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // Get the offer ID
    final offerId = offer['id'];
    
    // Call acceptOfferDirectly from the smart contract
    final txHash = await _blockchainService.acceptOfferDirectly(offerId);
    
    // Create transaction record
    final newTransaction = {
      'id': 'TX${(1000 + _transactionHistory.length).toString()}',
      'type': offer['offerType'] == 'Sell' ? 'Buy' : 'Sell',
      'amount': offer['energyAmount'],
      'price': offer['pricePerUnit'],
      'totalPrice': offer['price'],
      'counterparty': offer['user'],
      'timestamp': DateTime.now(),
      'status': 'Agreed',
      'txHash': txHash,
    };
    
    // Add to transaction history
    setState(() {
      _transactionHistory.insert(0, newTransaction);
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully accepted offer! Transaction: ${txHash.substring(0, 10)}...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            final explorerUrl = _currentChainId == 17000
                ? 'https://holesky.etherscan.io/tx/$txHash'
                : 'https://etherscan.io/tx/$txHash';
            launch(explorerUrl);
          },
        ),
      ),
    );
    
    // Switch to transaction history tab
    setState(() {
      _showTransactionHistory = true;
      _isLoading = false;
    });
    
    // Refresh offers
    _loadActiveOffers();
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    String errorMessage = e.toString();
    if (errorMessage.contains('execution reverted')) {
      errorMessage = 'Transaction rejected by the blockchain. Check your parameters.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error accepting offer: $errorMessage'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
    
    debugPrint('Detailed error accepting offer: $e');
  }
}

Future<void> _loadUserAgreements() async {
  if (!_isWalletConnected || _currentWalletAddress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please connect your wallet to view agreements')),
    );
    return;
  }
  
  setState(() {
    _isLoadingAgreements = true;
  });
  
  try {
    // Get agreement IDs for the current user
    final agreementIds = await _blockchainService.getUserAgreements(_currentWalletAddress!);
    
    if (agreementIds.isEmpty) {
      setState(() {
        _isLoadingAgreements = false;
        _userAgreements = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No agreements found for your account')),
      );
      return;
    }
    
    List<Map<String, dynamic>> agreements = [];
    
    // Loop through each agreement ID and get details
    for (final agreementId in agreementIds) {
      try {
        // Get full agreement details using the smart contract function
        final agreementDetails = await _blockchainService.getAgreementDetails(agreementId);
        
        // Format addresses for display
        final buyerAddress = agreementDetails['buyer'] as String;
        final buyerShortAddress = buyerAddress.isEmpty ? 'Unknown' : 
          '${buyerAddress.substring(0, 6)}...${buyerAddress.substring(buyerAddress.length - 4)}';
        
        final sellerAddress = agreementDetails['seller'] as String;
        final sellerShortAddress = sellerAddress.isEmpty ? 'Unknown' :
          '${sellerAddress.substring(0, 6)}...${sellerAddress.substring(sellerAddress.length - 4)}';
          
        // Determine if the current user is buyer or seller
        final isUserBuyer = buyerAddress.toLowerCase() == _currentWalletAddress!.toLowerCase();
        final role = isUserBuyer ? 'Buyer' : 'Seller';
        
        // Determine partner name and address
        final partner = isUserBuyer 
          ? (agreementDetails['sellerUsername'].toString().isEmpty 
              ? sellerShortAddress 
              : agreementDetails['sellerUsername'])
          : (agreementDetails['buyerUsername'].toString().isEmpty 
              ? buyerShortAddress 
              : agreementDetails['buyerUsername']);
              
        // Calculate price per unit from total price and energy amount
        final pricePerUnit = agreementDetails['finalEnergyAmount'] > 0
            ? agreementDetails['finalTotalPrice'] / agreementDetails['finalEnergyAmount']
            : 0.0;
            
        // Create timestamp from agreement time
        final agreedAtDateTime = DateTime.fromMillisecondsSinceEpoch(
          agreementDetails['agreedAt'] as int
        );
        
        // Create the agreement object with all necessary details
        final agreement = {
          'id': agreementId,
          'offerId': agreementDetails['offerId'],
          'buyer': agreementDetails['buyer'],
          'buyerUsername': agreementDetails['buyerUsername'].toString().isEmpty 
              ? buyerShortAddress 
              : agreementDetails['buyerUsername'],
          'seller': agreementDetails['seller'],
          'sellerUsername': agreementDetails['sellerUsername'].toString().isEmpty 
              ? sellerShortAddress 
              : agreementDetails['sellerUsername'],
          'energyAmount': agreementDetails['finalEnergyAmount'],
          'totalPrice': agreementDetails['finalTotalPrice'],
          'pricePerUnit': pricePerUnit,
          'agreedAt': agreedAtDateTime,
          'isActive': agreementDetails['isActive'],
          'funded': agreementDetails['funded'],
          'status': agreementDetails['isActive'] 
              ? (agreementDetails['funded'] ? 'Active' : 'Awaiting Payment') 
              : 'Completed',
          'role': role,
          'partner': partner,
          // Use agreed date for display calculations
          'startTime': agreedAtDateTime,
          'endTime': agreedAtDateTime.add(const Duration(days: 30)),
        };
        
        agreements.add(agreement);
      } catch (e) {
        print('Error loading agreement $agreementId: $e');
        // Continue with next agreement
      }
    }
    
    setState(() {
      _userAgreements = agreements;
      _isLoadingAgreements = false;
    });
    
    if (agreements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid agreements found for your account')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully loaded ${agreements.length} agreements')),
      );
    }
    
  } catch (e) {
    print('Error loading agreements: $e');
    setState(() {
      _isLoadingAgreements = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading agreements: ${e.toString().substring(0, min(50, e.toString().length))}...'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Widget _buildAgreementsSection(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Energy Agreements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              if (_isWalletConnected)
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoadingAgreements ? Colors.purple.shade300 : Colors.white,
                  ),
                  tooltip: 'Refresh agreements',
                  onPressed: _isLoadingAgreements
                      ? null
                      : _loadUserAgreements,
                ),
              const SizedBox(width: 8),
              Text(
                '${_userAgreements.length} agreements',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Show connection prompt if wallet not connected
      if (!_isWalletConnected)
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wallet,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect your wallet to view your energy agreements',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C005C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _connectWallet,
              ),
            ],
          ),
        )
      else if (_isLoadingAgreements)
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C005C)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your agreements...',
                style: TextStyle(color: Colors.white, fontSize: 16)
              )
            ],
          ),
        )
      else if (_userAgreements.isEmpty)
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.handshake,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'You don\'t have any energy agreements yet',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Buy or sell energy to create agreements',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C005C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _loadUserAgreements,
              ),
            ],
          ),
        )
      else
        isMobile ? _buildAgreementCardList() : _buildAgreementsTable(),
    ],
  );
}

Widget _buildAgreementsTable() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      
      return Container(
        width: availableWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF5C005C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth),
            child: DataTable(
              columnSpacing: 16,
              dataRowHeight: 70,
              headingRowHeight: 56,
              horizontalMargin: 24,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF5C005C).withOpacity(0.2),
              ),
              columns: const [
                DataColumn(
                  label: Text('ID', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Role', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Partner', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Amount (kWh)', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Price/kWh', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Total', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Status', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Valid Until', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Actions', style: TextStyle(color: Colors.white)),
                ),
              ],
              rows: _userAgreements.map((agreement) => _buildAgreementRow(agreement)).toList(),
            ),
          ),
        ),
      );
    }
  );
}

DataRow _buildAgreementRow(Map<String, dynamic> agreement) {
  final formattedDate = DateFormat('MMM dd, yyyy').format(agreement['agreedAt']);
  final shortId = '${agreement['id'].toString().substring(0, 6)}...';
  
  return DataRow(
    cells: [
      DataCell(
        Tooltip(
          message: agreement['id'],
          child: Text(
            shortId,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: agreement['role'] == 'Seller' ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            agreement['role'],
            style: TextStyle(
              color: agreement['role'] == 'Seller' ? Colors.green : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          agreement['partner'],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      DataCell(
        Text(
          '${agreement['energyAmount'].toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      DataCell(
        Text(
          '\$${(agreement['pricePerUnit']/1e18).toStringAsFixed(3)}/kWh',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          '\$${(agreement['totalPrice']/1e18).toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(agreement['status']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            agreement['status'],
            style: TextStyle(
              color: _getStatusColor(agreement['status']),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          formattedDate,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show funding button for buyers with unfunded agreements
            if (agreement['role'] == 'Buyer' && !agreement['funded'] && agreement['isActive'])
              ElevatedButton(
                onPressed: () => _fundAgreement(agreement),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Fund'),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'user': agreement['partner'],
                    'offerId': agreement['id'],
                    'offerType': agreement['role'] == 'Seller' ? 'Sell' : 'Buy',
                  },
                );
                
                // Show confirmation toast
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting chat with ${agreement["partner"]} about your agreement'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildAgreementCardList() {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _userAgreements.length,
    itemBuilder: (context, index) {
      final agreement = _userAgreements[index];
      final formattedDate = DateFormat('MMM dd, yyyy').format(agreement['agreedAt']);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.black.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: agreement['role'] == 'Seller' ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      agreement['role'],
                      style: TextStyle(
                        color: agreement['role'] == 'Seller' ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(agreement['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      agreement['status'],
                      style: TextStyle(
                        color: _getStatusColor(agreement['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agreement ID: ${agreement['id'].toString().substring(0, 10)}...',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Partner: ${agreement['partner']}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${agreement['energyAmount'].toStringAsFixed(1)} kWh',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total: \$${agreement['totalPrice'].toStringAsFixed(2)} (\$${agreement['pricePerUnit'].toStringAsFixed(3)}/kWh)',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Agreed on: $formattedDate',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              
              // Add funding button for buyers with unfunded agreements
              if (agreement['role'] == 'Buyer' && !agreement['funded'] && agreement['isActive']) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _fundAgreement(agreement),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet),
                      SizedBox(width: 8),
                      Text('Fund Agreement'),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat with Partner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'user': agreement['partner'],
                      'offerId': agreement['id'],
                      'offerType': agreement['role'] == 'Seller' ? 'Sell' : 'Buy',
                    },
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting chat with ${agreement["partner"]} about your agreement'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _fundAgreement(Map<String, dynamic> agreement) async {
  if (!_isWalletConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please connect your wallet first')),
    );
    return;
  }
  
  // Show confirmation dialog first
  bool proceedWithFunding = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF2A0030),
      title: const Text('Fund Agreement', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will require two transactions:',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Approve \$${agreement['totalPrice'].toStringAsFixed(2)} to be spent by the marketplace',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const Text(
            '2. Fund the agreement',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Text(
            'Do you want to proceed?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Proceed'),
        ),
      ],
    ),
  ) ?? false;
  
  if (!proceedWithFunding) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Check if on correct network
    if (_currentChainId != 17000) { // 17000 is Holesky testnet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please switch to Holesky testnet')),
      );
      
      await _switchNetwork(17000);
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // Step 1: Convert price to token amount with 18 decimals
    final tokenAmount = BigInt.from(agreement['totalPrice'] * 1e18);
    
    // Show approval processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0030),
        title: const Text('Approving Tokens', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            SizedBox(height: 16),
            Text(
              'Please confirm the approval in MetaMask...',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    
    // Step 2: Call approve on token contract
    final approvalTxHash = await _blockchainService.approveTokens(
      _blockchainService.marketContractAddress,
      tokenAmount
    );
    
    // Close the approval dialog
    if (context.mounted) Navigator.of(context).pop();
    
    // Show funding processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0030),
        title: const Text('Funding Agreement', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              'Please confirm the funding transaction in MetaMask...',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This will complete the funding process.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    
    // Step 3: Call fundAgreement on market contract
    final fundTxHash = await _blockchainService.fundAgreement(
      agreement['id']
    );
    
    // Close the funding dialog
    if (context.mounted) Navigator.of(context).pop();
    
    // Update local agreement state
    setState(() {
      // Find and update the agreement in the list
      final index = _userAgreements.indexWhere((a) => a['id'] == agreement['id']);
      if (index != -1) {
        _userAgreements[index]['funded'] = true;
        _userAgreements[index]['status'] = 'Active';
      }
      _isLoading = false;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Agreement successfully funded!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View Tx',
          textColor: Colors.white,
          onPressed: () {
            final explorerUrl = _currentChainId == 17000
                ? 'https://holesky.etherscan.io/tx/$fundTxHash'
                : 'https://etherscan.io/tx/$fundTxHash';
            launch(explorerUrl);
          },
        ),
      ),
    );
    
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    // Close any open dialogs
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    
    String errorMessage = e.toString();
    if (errorMessage.contains('execution reverted')) {
      if (errorMessage.contains('Funding deadline passed')) {
        errorMessage = 'The funding deadline for this agreement has passed.';
      } else if (errorMessage.contains('Agreement already funded')) {
        errorMessage = 'This agreement has already been funded.';
      } else if (errorMessage.contains('Token transfer failed')) {
        errorMessage = 'Token transfer failed. Please ensure you have enough tokens.';
      } else {
        errorMessage = 'Transaction failed: ${errorMessage.substring(errorMessage.indexOf('execution reverted:') + 19, min(errorMessage.length, errorMessage.indexOf('execution reverted:') + 100))}';
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error funding agreement: $errorMessage'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
      ),
    );
    
    debugPrint('Detailed error funding agreement: $e');
  }
}

}