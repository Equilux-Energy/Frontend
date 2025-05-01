import 'package:flutter/material.dart';
import '../services/blockchain_service.dart';
import '../models/blockchain_models.dart';

class BlockchainProvider with ChangeNotifier {
  final BlockchainService _service = BlockchainService();
  
  // States
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _service.isConnected;
  String? get currentAddress => _service.currentAddress;
  String? get errorMessage => _errorMessage;
  
  // Cache for token info
  TokenInfo? _tokenInfo;
  TokenBalance? _tokenBalance;
  
  TokenInfo? get tokenInfo => _tokenInfo;
  TokenBalance? get tokenBalance => _tokenBalance;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitializing || _isInitialized) return;
    
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _service.initialize();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }
  
  // Connect to wallet
  Future<bool> connectWallet() async {
    if (!_isInitialized) {
      _errorMessage = 'Service not initialized';
      notifyListeners();
      return false;
    }
    
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _service.connectWallet();
      if (result) {
        // If connected, fetch token info and balance
        await refreshTokenData();
      }
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Refresh token data
  Future<void> refreshTokenData() async {
    if (!isConnected) return;
    
    try {
      final name = await _service.getTokenName();
      final symbol = await _service.getTokenSymbol();
      final balance = await _service.getTokenBalance();
      
      // Create token info and balance objects
      // Note: Some properties are hardcoded as they would need to be fetched from the contract
      _tokenInfo = TokenInfo(
        name: name,
        symbol: symbol,
        totalSupply: BigInt.from(0), // Need to fetch from contract
        decimals: 18, // Assuming standard 18 decimals
        rate: BigInt.from(0), // Need to fetch from contract
      );
      
      _tokenBalance = TokenBalance(
        rawBalance: balance,
        decimals: 18, // Assuming standard 18 decimals
      );
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching token data: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Buy tokens
  Future<TransactionResult?> buyTokens(double etherAmount) async {
    if (!isConnected) {
      _errorMessage = 'Not connected to wallet';
      notifyListeners();
      return null;
    }
    
    try {
      // Convert ether to wei
      final weiAmount = BigInt.from(etherAmount * 1e18);
      final txHash = await _service.buyTokens(weiAmount);
      
      // Refresh token balance after transaction (with a delay)
      await Future.delayed(Duration(seconds: 2));
      await refreshTokenData();
      
      return TransactionResult(
        transactionHash: txHash,
        success: true,
      );
    } catch (e) {
      _errorMessage = 'Error buying tokens: ${e.toString()}';
      notifyListeners();
      return TransactionResult(
        transactionHash: '',
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Transfer tokens
  Future<TransactionResult?> transferTokens(String recipient, double amount) async {
    if (!isConnected) {
      _errorMessage = 'Not connected to wallet';
      notifyListeners();
      return null;
    }
    
    try {
      // Convert amount to token units (considering decimals)
      final tokenAmount = BigInt.from(amount * 1e18);
      final txHash = await _service.transferTokens(recipient, tokenAmount);
      
      // Refresh token balance after transaction (with a delay)
      await Future.delayed(Duration(seconds: 2));
      await refreshTokenData();
      
      return TransactionResult(
        transactionHash: txHash,
        success: true,
      );
    } catch (e) {
      _errorMessage = 'Error transferring tokens: ${e.toString()}';
      notifyListeners();
      return TransactionResult(
        transactionHash: '',
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Additional methods for the market contract would be implemented here
}