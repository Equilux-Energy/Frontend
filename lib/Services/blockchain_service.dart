import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'dart:html' as html;
import 'dart:js_util';
import '../models/blockchain_models.dart';

@JS('window.energyDapp.isMetaMaskInstalled')
external bool isMetaMaskInstalled();

@JS('window.energyDapp.connect')
external dynamic connect();

@JS('window.energyDapp.checkConnectedState')
external dynamic checkConnectedState();

@JS('window.energyDapp.getChainId')
external dynamic getChainId();

@JS('window.energyDapp.switchNetwork')
external dynamic switchNetwork(int chainId);

@JS('window.energyDapp.callContractFunction')
external dynamic callContractFunction(String contractAddress, dynamic contractAbi, String method, dynamic args);

@JS('window.energyDapp.sendContractTransaction')
external dynamic sendContractTransaction(String address, dynamic abi, String method, dynamic args, String? value);

@JS('window.energyDapp.setupEventHandlers')
external void setupEventHandlers(dynamic accountsChangedCallback, dynamic chainChangedCallback);

class BlockchainService with ChangeNotifier {
  // Contract addresses
  late String _tokenContractAddress;
  String _marketContractAddress = '0x23Ab54Aac277e66f3d84E088fBb966d76aB56082';
  
  // Contract ABIs
  dynamic _tokenContractAbi;
  dynamic _marketContractAbi;
  
  // Current connected account
  String? _currentAddress;
  int? _currentChainId;
  String? _currentBalance;
  bool _isConnected = false;
  
  BlockchainService() {
    // Set default contract addresses right away to prevent late init errors
    _tokenContractAddress = '0x52e12c26029ed061de7568e2b1acd9a39277e3ef';
    _marketContractAddress = '0x23Ab54Aac277e66f3d84E088fBb966d76aB56082';
    
    // Then proceed with async initialization
    _initializeDapp();
    
    // Load contract ABIs
    _loadContractABIs();
  }

  // Separate method just for loading ABIs
  Future<void> _loadContractABIs() async {
    try {
      // Load token contract ABI
      final tokenAbiString = await rootBundle.loadString('assets/tokencontractabi.txt');
      _tokenContractAbi = tokenAbiString;
      
      // Load market contract ABI
      final marketAbiString = await rootBundle.loadString('assets/marketcontractabi.txt');
      _marketContractAbi = marketAbiString;
    } catch (e) {
      debugPrint('Error loading contract ABIs: $e');
    }
  }

  // Getters
  bool get isConnected => _isConnected;
  String? get currentAddress => _currentAddress;
  int? get currentChainId => _currentChainId;
  String? get currentBalance => _currentBalance;
  String get marketContractAddress {
  // Ensure contract address is set - always return a valid string even if not initialized
  if (_marketContractAddress.isEmpty) {
    _marketContractAddress = '0x23Ab54Aac277e66f3d84E088fBb966d76aB56082';
  }
  return _marketContractAddress;
}
  
  // Initialize the service
  Future<void> initialize() async {
    // Check if MetaMask is installed
    if (!isMetaMaskInstalled()) {
      throw Exception('MetaMask is not installed');
    }

    _initializeDapp();
    
    // Load contract ABIs and addresses
    await _loadContracts();
    
    // Setup event listeners for account/chain changes
    //_setupEventListeners();
  }
  
  // Setup event listeners for MetaMask
  void _setupEventListeners() {
    // Create JS interoperable callbacks
    final accountsChangedCallback = allowInterop((dynamic accounts) {
      _handleAccountsChanged(accounts);
    });
    
    final chainChangedCallback = allowInterop((dynamic chainId) {
      _handleChainChanged(chainId);
    });
    
    // Register callbacks with JavaScript
    setupEventHandlers(accountsChangedCallback, chainChangedCallback);
  }
  
  // Handle account changes
  void _handleAccountsChanged(dynamic accounts) {
    if (accounts is List && accounts.isNotEmpty) {
      _currentAddress = accounts[0];
    } else {
      _currentAddress = null;
      _isConnected = false;
    }
    notifyListeners();
  }
  
  // Handle chain changes
  void _handleChainChanged(dynamic chainId) {
    _currentChainId = chainId is int ? chainId : 0;
    notifyListeners();
  }
  
  // Load contract ABIs and addresses
  Future<void> _loadContracts() async {
    // Load token contract ABI
    final tokenAbiString = await rootBundle.loadString('tokencontractabi.txt');
    _tokenContractAbi = tokenAbiString;
    
    // Load market contract ABI
    final marketAbiString = await rootBundle.loadString('marketcontractabi.txt');
    _marketContractAbi = marketAbiString;
    
    // Set contract addresses (replace with your actual contract addresses)
    _tokenContractAddress = '0x52e12c26029ed061de7568e2b1acd9a39277e3ef';
    _marketContractAddress = '0x23Ab54Aac277e66f3d84E088fBb966d76aB56082';
  }
  
  // Connect to MetaMask
  Future<bool> connectWallet() async {
    try {
      // Request accounts from MetaMask using our JS bridge
      final result = await promiseToFuture(connect());
      
      _currentAddress = result.address;
      _currentChainId = result.chainId;
      _currentBalance = result.balance;
      _isConnected = true;
      _marketContractAddress = '0x23Ab54Aac277e66f3d84E088fBb966d76aB56082';
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error connecting to MetaMask: $e');
      return false;
    }
  }
  
  // Switch network
  Future<bool> switchNetwork(int chainId) async {
    try {
      // Convert chain ID to hex format (e.g., 0x1 for Ethereum Mainnet)
      final chainIdHex = '0x${chainId.toRadixString(16)}';
      final result = await promiseToFuture<bool>(switchNetwork(chainId));
      return result;
    } catch (e) {
      print('Error switching network: $e');
      return false;
    }
  }
  
  // TOKEN CONTRACT FUNCTIONS
  
  // Get token name
  Future<String> getTokenName() async {
    if (!_isConnected) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final result = await promiseToFuture<String>(
        callContractFunction(_tokenContractAddress, _tokenContractAbi, 'name', null)
      );
      return result;
    } catch (e) {
      throw Exception('Failed to get token name: $e');
    }
  }
  
  // Get token symbol
  Future<String> getTokenSymbol() async {
    if (!_isConnected) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final result = await promiseToFuture<String>(
        callContractFunction(_tokenContractAddress, _tokenContractAbi, 'symbol', null)
      );
      return result;
    } catch (e) {
      throw Exception('Failed to get token symbol: $e');
    }
  }
  
  // Get token balance for current account
  Future<BigInt> getTokenBalance() async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final result = await promiseToFuture<String>(
        callContractFunction(_tokenContractAddress, _tokenContractAbi, 'balanceOf', jsify([_currentAddress]))
      );
      return BigInt.parse(result);
    } catch (e) {
      throw Exception('Failed to get token balance: $e');
    }
  }
  
  // Buy tokens
  Future<String> buyTokens(BigInt weiAmount) async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final txHash = await promiseToFuture<String>(
        sendContractTransaction(
          _tokenContractAddress, 
          _tokenContractAbi, 
          'buyTokens', 
          jsify([]), 
          '0x${weiAmount.toRadixString(16)}'
        )
      );
      return txHash;
    } catch (e) {
      throw Exception('Failed to buy tokens: $e');
    }
  }
  
  // Transfer tokens
  Future<String> transferTokens(String recipient, BigInt amount) async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final txHash = await promiseToFuture<String>(
        sendContractTransaction(
          _tokenContractAddress, 
          _tokenContractAbi, 
          'transfer', 
          jsify([recipient, amount.toString()]),
          null
        )
      );
      return txHash;
    } catch (e) {
      throw Exception('Failed to transfer tokens: $e');
    }
  }
  
  // MARKET CONTRACT FUNCTIONS
  
  // List energy for sale
  Future<String> listEnergyForSale(BigInt amount, BigInt pricePerUnit) async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final txHash = await promiseToFuture<String>(
        sendContractTransaction(
          _marketContractAddress, 
          _marketContractAbi, 
          'listEnergyForSale', 
          jsify([amount.toString(), pricePerUnit.toString()]),
          null
        )
      );
      return txHash;
    } catch (e) {
      throw Exception('Failed to list energy for sale: $e');
    }
  }
  
  // Buy energy from market
  Future<String> buyEnergy(BigInt listingId, BigInt amount) async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final txHash = await promiseToFuture<String>(
        sendContractTransaction(
          _marketContractAddress, 
          _marketContractAbi, 
          'buyEnergy', 
          jsify([listingId.toString(), amount.toString()]),
          null
        )
      );
      return txHash;
    } catch (e) {
      throw Exception('Failed to buy energy: $e');
    }
  }
  
  // Get market listing count
  Future<List<String>> getActiveOffers() async {
    if (!_isConnected) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final result = await promiseToFuture<dynamic>(
        callContractFunction(_marketContractAddress, _marketContractAbi, 'getActiveOffers', null)
      );
      debugPrint(result.toString());
      // Convert the JavaScript array to a Dart list of strings
      return List<String>.from(result);
    } catch (e) {
      throw Exception('Failed to get active offers: $e');
    }
  }
  
  // Get market listing details by ID
  Future<Map<String, dynamic>> getOfferDetails(String offerId) async {
  if (!_isConnected) {
    throw Exception('Not connected to blockchain');
  }

  try {
    final result = await promiseToFuture<dynamic>(
      callContractFunction(_marketContractAddress, _marketContractAbi, 'getOfferDetails', jsify([offerId]))
    );

    // Parse the result based on your contract's return structure
    return {
      'id': result[0], // bytes32
      'creator': result[1], // address
      'creatorUsername': result[2], // string
      'offerType': int.parse(result[3].toString()), // OfferType enum (0 for Sell, 1 for Buy)
      'energyAmount': BigInt.parse(result[4].toString()), // uint256
      'pricePerUnit': BigInt.parse(result[5].toString()), // uint256
      'totalPrice': BigInt.parse(result[6].toString()), // uint256
      'startTime': BigInt.parse(result[7].toString()), // uint256 (timestamp)
      'endTime': BigInt.parse(result[8].toString()), // uint256 (timestamp)
      'status': int.parse(result[9].toString()), // OfferStatus enum (e.g., 0 for Active)
      'counterparty': result[10], // address
      'counterpartyUsername': result[11], // string
      'createdAt': BigInt.parse(result[12].toString()), // uint256 (timestamp)
    };
  } catch (e) {
    throw Exception('Failed to get listing: $e');
  }
}

  // Create energy offer
  Future<String> createOffer(
    int offerType,
    BigInt energyAmount,
    BigInt pricePerUnit,
    BigInt startTime,
    BigInt endTime
  ) async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      debugPrint(_marketContractAbi.toString());
      final txHash = await promiseToFuture<String>(
        sendContractTransaction(
          _marketContractAddress,
          _marketContractAbi,
          'createOffer',
          jsify([
            offerType,
            energyAmount.toString(),
            pricePerUnit.toString(),
            startTime.toString(),
            endTime.toString()
          ]),
          null
        )
      );
      return txHash;
    } catch (e) {
      throw Exception('Failed to create energy offer: $e');
    }
  }

  Future<void> initializeDapp() async {
    _initializeDapp();
  }

  Future<void> _initializeDapp() async {
  // First check if there's an existing connection
  try {
    final result = await promiseToFuture(
      checkConnectedState()
    );
    
    if (result != null) {
      // MetaMask is already connected from a previous session
      _currentAddress = result.address as String;
      _currentChainId = result.chainId as int;
      _currentBalance = result.balance as String;
      debugPrint('Balance from block: $_currentBalance');
      _isConnected = true;
      notifyListeners();
    }
  } catch (e) {
    debugPrint('Failed to check for existing connection: $e');
  }
  
  // Listen for account changes
  html.window.addEventListener('accountsChanged', (event) {
    final accounts = (event as html.CustomEvent).detail;
    if (accounts is List && accounts.isEmpty) {
      // User disconnected their wallet
      _isConnected = false;
      _currentAddress = null;
    } else if (accounts is List && accounts.isNotEmpty) {
      // User switched accounts
      _currentAddress = accounts[0];
      _isConnected = true;
    }
    notifyListeners();
  });
  
  // Listen for chain changes
  html.window.addEventListener('chainChanged', (event) {
    final chainId = (event as html.CustomEvent).detail;
    _currentChainId = int.parse(chainId, radix: 16);
    notifyListeners();
  });
}

// Add this utility function to your BlockchainService class
BigInt _toBigInt(dynamic value) {
  if (value == null) return BigInt.zero;
  
  // Handle JavaScript BigInt
  if (value is JSObject || value.toString().contains('n')) {
    // Convert JavaScript BigInt to string without the 'n' suffix
    String numStr = value.toString();
    if (numStr.endsWith('n')) {
      numStr = numStr.substring(0, numStr.length - 1);
    }
    return BigInt.parse(numStr);
  } 
  
  // If it's already a Dart BigInt
  if (value is BigInt) {
    return value;
  }
  
  // For other number types
  return BigInt.from(value);
}

// Add this utility method to safely convert JS BigInts to Dart values
dynamic _convertJSValue(dynamic value) {
  if (value == null) {
    return null;
  }
  
  // For JS BigInt values
  if (value.toString().contains('n')) {
    // Convert to string and remove 'n' suffix
    String numStr = value.toString();
    if (numStr.endsWith('n')) {
      numStr = numStr.substring(0, numStr.length - 1);
    }
    
    // Parse number - as double if for display, as BigInt if needed for calculations
    try {
      return double.parse(numStr);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Return original value for other types
  return value;
}

Future<Map<String, dynamic>> getAgreementDetails(String agreementId) async {
  if (!_isConnected) {
    throw Exception('Not connected to blockchain');
  }

  debugPrint('Fetching details for agreement: $agreementId');

  try {
    final result = await promiseToFuture<dynamic>(
      callContractFunction(
        _marketContractAddress, 
        _marketContractAbi, 
        'getAgreementDetails', 
        jsify([agreementId])
      )
    );
    
    debugPrint('Raw agreement details: ${result.toString()}');

    debugPrint('Result type: ${result[6].runtimeType}');
    
    // Safely convert the numeric values from JS BigInt
    final energyAmount = int.parse(result[6].toString());
    final totalPrice = int.parse(result[7].toString());
    final timestamp = _convertJSValue(result[8]);
    
    debugPrint('Converted values - Energy: $energyAmount, ${energyAmount.runtimeType}, Price: $totalPrice, Timestamp: $timestamp');
    
    // Create millisecond timestamp for DateTime
    int timestampMs = 0;
    if (timestamp is double) {
      timestampMs = (timestamp * 1000).toInt();
    } else {
      try {
        timestampMs = int.parse(timestamp.toString()) * 1000;
      } catch (e) {
        debugPrint('Error parsing timestamp: $e');
        timestampMs = 0;
      }
    }
    
    // Format the final values
    int finalEnergyAmount = energyAmount;
    int finalTotalPrice = totalPrice;
    
    final mappedResult = {
      'id': result[0],
      'offerId': result[1],
      'buyer': result[2],
      'buyerUsername': result[3],
      'seller': result[4],
      'sellerUsername': result[5],
      'finalEnergyAmount': finalEnergyAmount,
      'finalTotalPrice': finalTotalPrice,
      'agreedAt': timestampMs,
      'isActive': result[9],
      'funded': result[10]
    };
    
    debugPrint('Processed agreement details: $mappedResult');
    
    return mappedResult;
  } catch (e) {
    debugPrint('Error fetching agreement details: $e');
    throw Exception('Failed to get agreement details: $e');
  }
}

  Future<String> acceptOfferDirectly(String offerId) async {
    if (!_isConnected || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    try {
      final txHash = await promiseToFuture<String>(
        sendContractTransaction(
          _marketContractAddress, 
          _marketContractAbi, 
          'acceptOfferDirectly', 
          jsify([offerId]),
          null
        )
      );
      return txHash;
    } catch (e) {
      throw Exception('Failed to accept offer: $e');
    }
  }

  Future<List<String>> getUserAgreements(String userAddress) async {
  if (!_isConnected) {
    throw Exception('Not connected to blockchain');
  }

  debugPrint('Fetching agreements for user: $userAddress');
  
  try {
    final result = await promiseToFuture<dynamic>(
      callContractFunction(
        _marketContractAddress, 
        _marketContractAbi, 
        'getUserAgreements', 
        jsify([userAddress])
      )
    );
    
    // Log the retrieved agreements
    debugPrint('User agreements retrieved: ${result.toString()}');
    
    // Convert the JavaScript array to a Dart list of strings
    return List<String>.from(result);
  } catch (e) {
    debugPrint('Error fetching user agreements: $e');
    throw Exception('Failed to get user agreements: $e');
  }
}

  Future<String> approveTokens(String spender, BigInt amount) async {
  if (!_isConnected || _currentAddress == null) {
    throw Exception('Not connected to blockchain');
  }
  
  try {
    final txHash = await promiseToFuture<String>(
      sendContractTransaction(
        _tokenContractAddress, 
        _tokenContractAbi, 
        'approve', 
        jsify([spender, amount.toString()]),
        null
      )
    );
    return txHash;
  } catch (e) {
    throw Exception('Failed to approve tokens: $e');
  }
}

Future<String> fundAgreement(String agreementId) async {
  if (!_isConnected || _currentAddress == null) {
    throw Exception('Not connected to blockchain');
  }
  
  try {
    final txHash = await promiseToFuture<String>(
      sendContractTransaction(
        _marketContractAddress, 
        _marketContractAbi, 
        'fundAgreement', 
        jsify([agreementId]),
        null
      )
    );
    return txHash;
  } catch (e) {
    throw Exception('Failed to fund agreement: $e');
  }
}

// Add to your BlockchainService class
Future<double> getAveragePriceLastWeek() async {
  if (!_isConnected) {
    throw Exception('Not connected to blockchain');
  }

  try {
    final result = await promiseToFuture<dynamic>(
      callContractFunction(
        _marketContractAddress, 
        _marketContractAbi, 
        'getAveragePriceLastWeek', 
        jsify([])
      )
    );

    debugPrint('Average price result: $result');
    
    // Convert the result (BigInt) to a double and divide by 1e18 (token decimals)
    double averagePrice = 0.0;
    try {
      // Handle JavaScript BigInt
      String valueStr = result.toString().replaceAll('n', '');
      averagePrice = double.parse(valueStr) / 1e18;
    } catch (e) {
      print('Error parsing average price: $e');
      averagePrice = 0.0;
    }
    
    return averagePrice;
  } catch (e) {
    print('Error fetching average price: $e');
    throw Exception('Failed to get average price: $e');
  }
}

// Add this method to your BlockchainService class
Future<Map<String, dynamic>> getUserStats(String userAddress) async {
  if (!_isConnected) {
    throw Exception('Not connected to blockchain');
  }

  try {
    final result = await promiseToFuture<dynamic>(
      callContractFunction(
        _marketContractAddress, 
        _marketContractAbi, 
        'getUserStats', 
        jsify([userAddress])
      )
    );
    
    debugPrint('Raw user stats: $result');
    
    // Convert numeric values safely
    final Map<String, dynamic> stats = {
      'username': result[0],
      'offersCreated': int.parse(result[1].toString().replaceAll('n', '')),
      'offersCountered': int.parse(result[2].toString().replaceAll('n', '')),
      'agreementsCompleted': int.parse(result[3].toString().replaceAll('n', '')),
      'agreementsCancelled': int.parse(result[4].toString().replaceAll('n', '')),
      'disputesInitiated': int.parse(result[5].toString().replaceAll('n', '')),
      'disputesWon': int.parse(result[6].toString().replaceAll('n', '')),
      'totalEnergyTraded': double.parse(result[7].toString().replaceAll('n', '')) / 1e18,
      'totalValueTraded': double.parse(result[8].toString().replaceAll('n', '')) / 1e18,
      'lastActivityTimestamp': int.parse(result[9].toString().replaceAll('n', '')),
    };
    
    debugPrint('Processed user stats: $stats');
    return stats;
  } catch (e) {
    debugPrint('Error fetching user stats: $e');
    throw Exception('Failed to get user stats: $e');
  }
}

}