import 'dart:convert';
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
  late String _marketContractAddress;
  
  // Contract ABIs
  dynamic _tokenContractAbi;
  dynamic _marketContractAbi;
  
  // Current connected account
  String? _currentAddress;
  int? _currentChainId;
  String? _currentBalance;
  bool _isConnected = false;
  
  BlockchainService() {
    // Call your initialize method right away
    _initializeDapp();
  }

  // Getters
  bool get isConnected => _isConnected;
  String? get currentAddress => _currentAddress;
  int? get currentChainId => _currentChainId;
  String? get currentBalance => _currentBalance;
  
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
    _tokenContractAbi = jsonDecode(tokenAbiString);
    
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

    try {
      final result = await promiseToFuture<dynamic>(
        callContractFunction(
          _marketContractAddress, 
          _marketContractAbi, 
          'getUserAgreements', 
          jsify([userAddress])
        )
      );
      // Convert the JavaScript array to a Dart list of strings
      return List<String>.from(result);
    } catch (e) {
      throw Exception('Failed to get user agreements: $e');
    }
  }
}