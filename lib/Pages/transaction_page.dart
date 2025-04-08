import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/metamask.dart';
import '../Widgets/animated_background.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TransactionPage({super.key, required this.userData});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  // Filter values
  RangeValues _priceRange = const RangeValues(0, 1000);
  RangeValues _amountRange = const RangeValues(0, 500);
  String _searchQuery = '';
  String _filterType = 'All'; // All, Buy, Sell
  
  // Filtered offers list
  List<Map<String, dynamic>> _filteredOffers = [];

  // Add these variables to the _TransactionPageState class
  bool _showTransactionHistory = false;
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

  // Form values
  final _formKey = GlobalKey<FormState>();
  String _offerType = 'Sell';
  double _energyAmount = 0;
  double _price = 0;
  String _description = '';
  
  // Mock data for offers
  final List<Map<String, dynamic>> _offers = [
    {
      'id': '1',
      'type': 'Sell',
      'amount': 120.5,
      'price': 35.75,
      'pricePerUnit': 0.297,
      'user': '0x7a3B...F42c',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'description': 'Excess solar energy from residential panels',
      'status': 'Active',
    },
    {
      'id': '2',
      'type': 'Buy',
      'amount': 45.0,
      'price': 15.30,
      'pricePerUnit': 0.34,
      'user': '0x2c5D...A91b',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'description': 'Need extra power for EV charging station',
      'status': 'Active',
    },
    {
      'id': '3',
      'type': 'Sell',
      'amount': 300.0,
      'price': 81.00,
      'pricePerUnit': 0.27,
      'user': '0x8e4F...C23a',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'description': 'Community wind farm surplus',
      'status': 'Active',
    },
    {
      'id': '4', 
      'type': 'Buy',
      'amount': 200.0,
      'price': 70.00,
      'pricePerUnit': 0.35,
      'user': '0x5a1B...D82e',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'description': 'Small business looking for renewable energy',
      'status': 'Active',
    },
    {
      'id': '5',
      'type': 'Sell',
      'amount': 500.0,
      'price': 125.00,
      'pricePerUnit': 0.25,
      'user': '0x7a3B...F42c',
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
      'description': 'Industrial solar farm excess production',
      'status': 'Active',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize filtered offers with all offers
    _filteredOffers = List.from(_offers);
  }
  
  // Filter offers based on criteria
  void _applyFilters() {
    setState(() {
      _filteredOffers = _offers.where((offer) {
        // Filter by type
        if (_filterType != 'All' && offer['type'] != _filterType) {
          return false;
        }
        
        // Filter by price range
        if (offer['price'] < _priceRange.start || offer['price'] > _priceRange.end) {
          return false;
        }
        
        // Filter by amount range
        if (offer['amount'] < _amountRange.start || offer['amount'] > _amountRange.end) {
          return false;
        }
        
        // Filter by search query (check user or description)
        if (_searchQuery.isNotEmpty) {
          final String description = offer['description'].toString().toLowerCase();
          final String user = offer['user'].toString().toLowerCase();
          final String query = _searchQuery.toLowerCase();
          
          if (!description.contains(query) && !user.contains(query)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  // Check if an offer matches the current filters
  bool _offerMatchesFilters(Map<String, dynamic> offer) {
    // Filter by type
    if (_filterType != 'All' && offer['type'] != _filterType) {
      return false;
    }
    
    // Filter by price range
    if (offer['price'] < _priceRange.start || offer['price'] > _priceRange.end) {
      return false;
    }
    
    // Filter by amount range
    if (offer['amount'] < _amountRange.start || offer['amount'] > _amountRange.end) {
      return false;
    }
    
    // Filter by search query (check user or description)
    if (_searchQuery.isNotEmpty) {
      final String description = offer['description'].toString().toLowerCase();
      final String user = offer['user'].toString().toLowerCase();
      final String query = _searchQuery.toLowerCase();
      
      if (!description.contains(query) && !user.contains(query)) {
        return false;
      }
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;

    return ChangeNotifierProvider<MetaMaskProvider>(
      create: (context) => MetaMaskProvider()..init(),
      builder: (context, child) {
        return Stack(
          children: [
            const AnimatedBackground(),
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
                                const Text('Energy Transactions', 
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                                ElevatedButton.icon(
                                  onPressed: () => _showCreateOfferDialog(),
                                  icon: const Icon(Icons.add,color: Colors.white),
                                  label: const Text('Create Offer'),
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
              // In the Scaffold widget, add this right before the closing parenthesis:
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showCreateOfferDialog(),
                label: const Text('Create Offer',style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.add,color: Colors.white),
                backgroundColor: const Color(0xFF5C005C),
              ),
            ),
          ],
        );
      }
    );
  }

  void _showCreateOfferDialog() {
    // Reset form values
    _offerType = 'Sell';
    _energyAmount = 0;
    _price = 0;
    _description = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                    Row(
                      children: [
                        const Text('Offer Type:', style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 16),
                        StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return ToggleButtons(
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
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEnergyAmountField(),
                    const SizedBox(height: 16),
                    _buildPriceField(),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      onChanged: (value) {
                        _description = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C005C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Create new offer
                              final newOffer = {
                                'id': (_offers.length + 1).toString(),
                                'type': _offerType,
                                'amount': _energyAmount,
                                'price': _price,
                                'pricePerUnit': _price / _energyAmount,
                                'user': '0x7a3B...F42c', // Current user address
                                'timestamp': DateTime.now(),
                                'description': _description,
                                'status': 'Active',
                              };
                              
                              setState(() {
                                // Add to base offers list
                                _offers.insert(0, newOffer);
                                
                                // Check if it matches current filters before adding to filtered list
                                if (_offerMatchesFilters(newOffer)) {
                                  _filteredOffers.insert(0, newOffer);
                                }
                              });
                              
                              // Close dialog
                              Navigator.pop(context);
                              
                              // Show success notification
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Offer created successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 8),
                              Text('Create Offer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('PIONEER Dashboard', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            _buildWalletButton(context),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
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
              _buildNavItem(context, 'Dashboard', Icons.dashboard, false, "/home"),
              _buildNavItem(context, 'User Profile', Icons.person, false, ""),
              _buildNavItem(context, 'Analytics', Icons.analytics, false, ""),
              _buildNavItem(context, 'Wallet', Icons.account_balance_wallet, false, ""),
              _buildNavItem(context, 'Transactions', Icons.history, true, "/transactions"),
              _buildNavItem(context, 'Chat', Icons.chat, false, "/chat"),
              _buildNavItem(context, 'Settings', Icons.settings, false, ""),
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
                      _priceRange = const RangeValues(0, 1000);
                      _amountRange = const RangeValues(0, 500);
                      _searchQuery = '';
                      _filterType = 'All';
                      
                      // Reset filtered offers to show all offers
                      _filteredOffers = List.from(_offers);
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
                max: 1000,
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
                max: 500,
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
          // Tab switcher
          Row(
            children: [
              Expanded(
                child: _buildTabSelector(
                  title: "Available Offers",
                  isActive: !_showTransactionHistory,
                  onTap: () {
                    setState(() {
                      _showTransactionHistory = false;
                    });
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
                      _showTransactionHistory = true;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Different content based on selected tab
          _showTransactionHistory
              ? _buildTransactionHistorySection(isMobile)
              : _buildAvailableOffersSection(isMobile),
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
          Text(
            '${_filteredOffers.length} offers found',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      const SizedBox(height: 16),
      isMobile 
          ? _buildOffersCardList() 
          : _buildOffersTable(),
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
  final isSellType = offer['type'] == 'Sell';
  final formattedTime = _formatTimestamp(offer['timestamp']);
  
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
            offer['type'],
            style: TextStyle(
              color: isSellType ? Colors.green : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          '${offer['amount'].toStringAsFixed(1)}',
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
        Row(
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
              // In _buildOfferRow method, replace the onPressed callback for the Buy/Sell button:
              onPressed: () {
                // Create transaction
                final newTransaction = {
                  'id': 'TX${(1000 + _transactionHistory.length).toString()}',
                  'type': isSellType ? 'Buy' : 'Sell',
                  'amount': offer['amount'],
                  'price': offer['pricePerUnit'],
                  'totalPrice': offer['price'],
                  'counterparty': offer['user'],
                  'timestamp': DateTime.now(),
                  'status': 'Completed',
                };
                
                // Add to transaction history
                setState(() {
                  _transactionHistory.insert(0, newTransaction);
                });
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isSellType ? 'Bought' : 'Sold'} energy from offer ${offer['id']}'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Switch to transaction history tab
                setState(() {
                  _showTransactionHistory = true;
                });
              },
              child: Text(isSellType ? 'Buy' : 'Sell'),
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
                // Navigate to chat or open chat dialog
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'user': offer['user'],
                    'offerId': offer['id'],
                    'offerType': offer['type'],
                  },
                );
                
                // Show confirmation toast
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting chat with ${offer["user"]} about ${offer["type"]} offer'),
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
  
  Widget _buildOffersCardList() {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _filteredOffers.length,
    itemBuilder: (context, index) {
      final offer = _filteredOffers[index];
      final isSellType = offer['type'] == 'Sell';
      final formattedTime = _formatTimestamp(offer['timestamp']);
      
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
                      offer['type'],
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
                    '${offer['amount'].toStringAsFixed(1)} kWh',
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
                        // Handle the transaction
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${isSellType ? 'Buying' : 'Selling'} energy from offer ${offer['id']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(isSellType ? 'Buy Now' : 'Sell Now'),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      // Navigate to chat
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'user': offer['user'],
                          'offerId': offer['id'],
                          'offerType': offer['type'],
                        },
                      );
                      
                      // Show confirmation toast
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Starting chat with ${offer["user"]} about ${offer["type"]} offer'),
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
  
  String _formatTimestamp(DateTime timestamp) {
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
}