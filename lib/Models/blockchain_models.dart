import 'package:web3dart/web3dart.dart';

// Model to represent token information
class TokenInfo {
  final String name;
  final String symbol;
  final BigInt totalSupply;
  final int decimals;
  final BigInt rate; // Exchange rate for purchasing tokens

  TokenInfo({
    required this.name,
    required this.symbol,
    required this.totalSupply,
    required this.decimals,
    required this.rate,
  });
}

// Model to represent token balance
class TokenBalance {
  final BigInt rawBalance;
  final int decimals;

  TokenBalance({required this.rawBalance, this.decimals = 18});

  // Convert raw balance to a human-readable format
  double get formattedBalance => rawBalance / BigInt.from(10).pow(decimals);

  @override
  String toString() {
    return formattedBalance.toString();
  }
}

// Model for energy listings (will be used with the market contract)
class EnergyListing {
  final int id;
  final EthereumAddress seller;
  final BigInt energyAmount;
  final BigInt pricePerUnit;
  final bool isActive;

  EnergyListing({
    required this.id,
    required this.seller,
    required this.energyAmount,
    required this.pricePerUnit,
    required this.isActive,
  });
}

// Model for a transaction result
class TransactionResult {
  final String transactionHash;
  final bool success;
  final String? errorMessage;

  TransactionResult({
    required this.transactionHash,
    required this.success,
    this.errorMessage,
  });
}