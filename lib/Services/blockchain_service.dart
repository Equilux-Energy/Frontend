import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import '../models/blockchain_models.dart';
import 'dart:js' as js;

class BlockchainService with ChangeNotifier {
  // Web3 client
  Web3Client? _web3client;
  
  // Contract instances
  DeployedContract? _tokenContract;
  DeployedContract? _marketContract;
  
  // Current connected account
  String? _currentAddress;
  int? _currentChainId;
  bool _isConnected = false;
  
  // Getters
  bool get isConnected => _isConnected;
  String? get currentAddress => _currentAddress;
  int? get currentChainId => _currentChainId;
  
  // Initialize the service
  Future<void> initialize() async {
    // Check if MetaMask is installed
    if (!_isMetaMaskInstalled()) {
      throw Exception('MetaMask is not installed');
    }
    
    // Load contract ABIs
    await _loadContracts();
    
    // Add event listeners for account/chain changes
    _setupEventListeners();
  }
  
  // Check if MetaMask is installed
  bool _isMetaMaskInstalled() {
    return js.context.hasProperty('ethereum');
  }
  
  // Setup event listeners for MetaMask
  void _setupEventListeners() {
    js.context['ethereum'].callMethod('on', ['accountsChanged', js.allowInterop((accounts) {
      _handleAccountsChanged(accounts);
    })]);
    
    js.context['ethereum'].callMethod('on', ['chainChanged', js.allowInterop((chainId) {
      _handleChainChanged(chainId);
    })]);
  }
  
  // Handle account changes
  void _handleAccountsChanged(dynamic accounts) {
    if (accounts.length > 0) {
      _currentAddress = accounts[0];
    } else {
      _currentAddress = null;
      _isConnected = false;
    }
    notifyListeners();
  }
  
  // Handle chain changes
  void _handleChainChanged(dynamic chainId) {
    _currentChainId = int.parse(chainId.toString());
    // Reload the page as recommended by MetaMask
    js.context.callMethod('location.reload', []);
  }
  
  // Load contract ABIs and create contract objects
  Future<void> _loadContracts() async {
    // Load token contract ABI
    String tokenAbiString = await rootBundle.loadString('lib/Pages/tokencontractabi.txt');
    
    // Note: Market contract ABI loading would go here
    String marketAbiString = await rootBundle.loadString('lib/Pages/marketcontractabi.txt');
    
    // Parse the ABIs
    final tokenAbi = ContractAbi.fromJson(tokenAbiString, 'EnergyToken');
    final marketAbi = ContractAbi.fromJson(marketAbiString, 'EnergyMarket');
    
    // Create contract objects (assuming contract addresses, will need to be configured)
    _tokenContract = DeployedContract(
      tokenAbi, 
      EthereumAddress.fromHex('0xYourTokenContractAddress'),
    );
    
    // Market contract would be initialized here
    _marketContract = DeployedContract(
      marketAbi, 
      EthereumAddress.fromHex('0xYourMarketContractAddress'),
    );
  }
  
  // Connect to MetaMask
  Future<bool> connectWallet() async {
    try {
      // Request accounts from MetaMask
      final accounts = await js.context['ethereum']
          .callMethod('request', [{'method': 'eth_requestAccounts'}]);
      
      if (accounts.length > 0) {
        _currentAddress = accounts[0];
        _isConnected = true;
        
        // Get current chain ID
        final chainId = await js.context['ethereum']
            .callMethod('request', [{'method': 'eth_chainId'}]);
        _currentChainId = int.parse(chainId.toString());
        
        // Initialize Web3 client
        _web3client = Web3Client(
          'https://ethereum.publicnode.com', // Default RPC URL, will be updated based on chain
          Client(),
        );
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting to MetaMask: $e');
      return false;
    }
  }
  
  // Switch network if needed
  Future<bool> switchNetwork(int chainId) async {
    try {
      await js.context['ethereum'].callMethod('request', [{
        'method': 'wallet_switchEthereumChain',
        'params': [{'chainId': '0x${chainId.toRadixString(16)}'}],
      }]);
      return true;
    } catch (e) {
      print('Error switching network: $e');
      return false;
    }
  }
  
  // Token Contract Functions
  
  // Get token name
  Future<String> getTokenName() async {
    if (!_isConnected || _web3client == null || _tokenContract == null) {
      throw Exception('Not connected to blockchain');
    }
    
    final nameFunction = _tokenContract!.function('name');
    final result = await _web3client!.call(
      contract: _tokenContract!,
      function: nameFunction,
      params: [],
    );
    
    return result[0].toString();
  }
  
  // Get token symbol
  Future<String> getTokenSymbol() async {
    if (!_isConnected || _web3client == null || _tokenContract == null) {
      throw Exception('Not connected to blockchain');
    }
    
    final symbolFunction = _tokenContract!.function('symbol');
    final result = await _web3client!.call(
      contract: _tokenContract!,
      function: symbolFunction,
      params: [],
    );
    
    return result[0].toString();
  }
  
  // Get token balance for the current account
  Future<BigInt> getTokenBalance() async {
    if (!_isConnected || _web3client == null || _tokenContract == null || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    final balanceFunction = _tokenContract!.function('balanceOf');
    final result = await _web3client!.call(
      contract: _tokenContract!,
      function: balanceFunction,
      params: [EthereumAddress.fromHex(_currentAddress!)],
    );
    
    return result[0] as BigInt;
  }
  
  // Buy tokens
  Future<String> buyTokens(BigInt weiAmount) async {
    if (!_isConnected || _web3client == null || _tokenContract == null || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    final buyTokensFunction = _tokenContract!.function('buyTokens');
    final transaction = Transaction(
      from: EthereumAddress.fromHex(_currentAddress!),
      to: _tokenContract!.address,
      value: EtherAmount.inWei(weiAmount),
    );
    
    // Execute the transaction via MetaMask
    final txHash = await js.context['ethereum'].callMethod('request', [{
      'method': 'eth_sendTransaction',
      'params': [{
        'from': _currentAddress,
        'to': _tokenContract!.address.hex,
        'value': '0x${weiAmount.toRadixString(16)}',
        'data': _getEncodedFunctionData(buyTokensFunction, []),
      }]
    }]);
    
    return txHash;
  }
  
  // Transfer tokens
  Future<String> transferTokens(String recipient, BigInt amount) async {
    if (!_isConnected || _web3client == null || _tokenContract == null || _currentAddress == null) {
      throw Exception('Not connected to blockchain');
    }
    
    final transferFunction = _tokenContract!.function('transfer');
    
    // Execute the transaction via MetaMask
    final txHash = await js.context['ethereum'].callMethod('request', [{
      'method': 'eth_sendTransaction',
      'params': [{
        'from': _currentAddress,
        'to': _tokenContract!.address.hex,
        'data': _getEncodedFunctionData(transferFunction, [
          EthereumAddress.fromHex(recipient),
          amount
        ]),
      }]
    }]);
    
    return txHash;
  }
  
  // Helper to encode function data for MetaMask transactions
  String _getEncodedFunctionData(ContractFunction function, List<dynamic> params) {
    final encodedFunction = function.encodeCall(params);
    return '0x${bytesToHex(encodedFunction)}';
  }
  
  // Market Contract Functions would be implemented here
  // These would include functions like:
  // - List energy for sale
  // - Buy energy
  // - Get market listings
  // etc.
}