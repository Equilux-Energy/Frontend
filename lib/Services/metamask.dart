import 'dart:async';
import 'dart:js_util';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

// JS interop for accessing window.ethereum
@JS('window.ethereum')
external Object? get ethereumInstance;

@JS('Object.keys')
external List<String> objectKeys(Object obj);

// JS interop for event listeners
@JS()
@anonymous
class EventOptions {
  external factory EventOptions({bool once});
}

@JS()
@anonymous
class ProviderRpcError implements Exception {
  external int get code;
  external String get message;
  external dynamic get data;
  external factory ProviderRpcError({int code, String message, dynamic data});
}

// Check if ethereum is supported
bool get isEthereumSupported => ethereumInstance != null;

class MetaMaskProvider extends ChangeNotifier {
  // Holesky testnet chain ID
  static const operatingChain = '0x4268';

  bool _isConnected = false;
  bool _isEnabled = false;
  bool _isInOperatingChain = false;
  String _currentChain = '';
  String _currentAddress = '';
  String _currentBalance = '0';

  // Storage keys
  static const String _connectedKey = 'metamask_connected';
  static const String _addressKey = 'metamask_address';

  // Web3 client
  Web3Client? _web3client;

  bool get isConnected => _isConnected;
  bool get isEnabled => _isEnabled;
  bool get isInOperatingChain => _isInOperatingChain;
  String get currentChain => _currentChain;
  String get currentAddress => _currentAddress;
  String get currentBalance => _currentBalance;
  
  // Constructor
  MetaMaskProvider() {
    _isEnabled = isEthereumSupported;
    if (_isEnabled) {
      // Initialize web3client with provider
      _web3client = Web3Client('', http.Client());
    }
  }

  // Initialize with stored values
  Future<void> init() async {
    try {
      if (_isEnabled) {
        // Load saved connection details
        await _loadSavedConnection();

        // Set up event listeners
        _setupEventListeners();

        // Auto reconnect if previously connected
        if (_isConnected && _currentAddress.isNotEmpty) {
          await reconnect();
        }
      }
    } catch (e) {
      debugPrint('Error initializing fuck you MetaMask: $e');
    }
    
    notifyListeners();
  }

  // Set up event listeners for account and chain changes
  void _setupEventListeners() {
    if (!_isEnabled) return;
    
    // Listen for account changes
    promiseToFuture(callMethod(
      ethereumInstance!,
      'on',
      ['accountsChanged', allowInterop((accounts) {
        _updateAccounts(accounts as List<dynamic>);
        notifyListeners();
      })],
    ));
    
    // Listen for chain changes
    promiseToFuture(callMethod(
      ethereumInstance!,
      'on',
      ['chainChanged', allowInterop((chainId) {
        _handleChainChanged(chainId as String);
        notifyListeners();
      })],
    ));
  }

  // Load saved connection from SharedPreferences
  Future<void> _loadSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isConnected = prefs.getBool(_connectedKey) ?? false;
      _currentAddress = prefs.getString(_addressKey) ?? '';
    } catch (e) {
      debugPrint('Error loading saved connection: $e');
    }
  }

  // Save connection to SharedPreferences
  Future<void> _saveConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_connectedKey, _isConnected);
      await prefs.setString(_addressKey, _currentAddress);
    } catch (e) {
      debugPrint('Error saving connection: $e');
    }
  }

  // Connect to MetaMask
  Future<void> connect() async {
    if (!_isEnabled) return;

    try {
      // Request accounts using JS interop
      final accounts = await promiseToFuture<List<dynamic>>(
        callMethod(ethereumInstance!, 'request', [
          jsify({'method': 'eth_requestAccounts'}),
        ]),
      );

      _updateAccounts(accounts);
      await _getChainId();
      await getBalance();

      // Save the connection
      _isConnected = true;
      await _saveConnection();

      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting: $e');
    }
  }

  // Reconnect using saved address
  Future<void> reconnect() async {
    if (!_isEnabled || _currentAddress.isEmpty) return;

    try {
      // Request accounts again to verify we still have access
      final accounts = await promiseToFuture<List<dynamic>>(
        callMethod(ethereumInstance!, 'request', [
          jsify({'method': 'eth_requestAccounts'}),
        ]),
      );

      if (accounts.isNotEmpty) {
        _updateAccounts(accounts);
        await _getChainId();
        await getBalance();
      } else {
        // If we can't get accounts, connection was lost
        _isConnected = false;
        _saveConnection();
      }
    } catch (e) {
      debugPrint('Error reconnecting: $e');
      _isConnected = false;
      _saveConnection();
    }

    notifyListeners();
  }

  // Disconnect from MetaMask
  Future<void> disconnect() async {
    _isConnected = false;
    _currentAddress = '';
    await _saveConnection();
    notifyListeners();
  }

  // Update accounts and address
  void _updateAccounts(List<dynamic>? accounts) {
    if (accounts != null && accounts.isNotEmpty) {
      _currentAddress = accounts[0] as String;
      _isConnected = true;
    } else {
      _currentAddress = '';
      _isConnected = false;
    }
    _saveConnection();
  }

  // Handle chain changes
  void _handleChainChanged(String chainId) {
    _currentChain = chainId;
    _checkChain();
    notifyListeners();
  }

  // Get current chain ID
  Future<void> _getChainId() async {
    try {
      final chainId = await promiseToFuture<String>(
        callMethod(ethereumInstance!, 'request', [
          jsify({'method': 'eth_chainId'}),
        ]),
      );
      _currentChain = chainId;
      _checkChain();
    } catch (e) {
      debugPrint('Error getting chain ID: $e');
    }
  }

  // Check if we're on the right chain
  void _checkChain() {
    _isInOperatingChain = _currentChain == operatingChain;
  }

  // Get account balance
  Future<void> getBalance() async {
    if (!_isConnected || _currentAddress.isEmpty) return;

    try {
      final balance = await promiseToFuture<String>(
        callMethod(ethereumInstance!, 'request', [
          jsify({
            'method': 'eth_getBalance',
            'params': [_currentAddress, 'latest'],
          }),
        ]),
      );

      if (balance.isNotEmpty) {
        // Convert from wei to ETH and format
        final ethBalance = EtherAmount.fromBigInt(
          EtherUnit.wei,
          BigInt.parse(balance.substring(2), radix: 16),
        ).getValueInUnit(EtherUnit.ether);
        _currentBalance = ethBalance.toStringAsFixed(4);
      }
    } catch (e) {
      debugPrint('Error getting balance: $e');
    }

    notifyListeners();
  }

  // Switch to the correct chain
  Future<void> switchChain() async {
    if (!_isEnabled) return;

    try {
      await promiseToFuture(
        callMethod(ethereumInstance!, 'request', [
          jsify({
            'method': 'wallet_switchEthereumChain',
            'params': [{'chainId': operatingChain}],
          }),
        ]),
      );
    } catch (e) {
      debugPrint('Error switching chain: $e');
    }
  }
  
  // For interacting with contracts using web3dart
  Future<String> sendTransaction({
    required String to,
    required BigInt value,
    required String data,
  }) async {
    if (!_isConnected || _currentAddress.isEmpty) {
      throw Exception('Not connected to MetaMask');
    }

    try {
      final txHash = await promiseToFuture<String>(
        callMethod(ethereumInstance!, 'request', [
          jsify({
            'method': 'eth_sendTransaction',
            'params': [{
              'from': _currentAddress,
              'to': to,
              'value': '0x${value.toRadixString(16)}',
              'data': data,
            }],
          }),
        ]),
      );
      return txHash;
    } catch (e) {
      debugPrint('Error sending transaction: $e');
      rethrow;
    }
  }
}