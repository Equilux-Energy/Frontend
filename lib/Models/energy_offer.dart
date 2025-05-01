import '../Pages/chat_page.dart';

enum EnergyOfferStatus {
  pending,
  active,
  completed,
  cancelled,
  disputed
}

class EnergyOffer {
  final String? id;            // Blockchain offer ID (null if not yet on-chain)
  final String? txHash;        // Transaction hash
  final String seller;         // Seller address
  final String? buyer;         // Buyer address (null if no buyer yet)
  final int amount;            // Amount in kWh
  final double pricePerUnit;   // Price per kWh
  final DateTime startTime;    // Start time for energy delivery
  final EnergyOfferStatus status; // Offer status
  final bool isSelling;        // If true, the offer is to sell energy; if false, to buy
  
  EnergyOffer({
    this.id,
    this.txHash,
    required this.seller,
    this.buyer,
    required this.amount,
    required this.pricePerUnit,
    required this.startTime,
    required this.status,
    required this.isSelling,
  });
  
  // Calculate total value
  double get totalValue => amount * pricePerUnit;
  
  // Create from blockchain response
  factory EnergyOffer.fromBlockchain(Map<String, dynamic> data) {
    return EnergyOffer(
      id: data['id'],
      seller: data['seller'],
      buyer: data['buyer'],
      amount: data['amount'],
      pricePerUnit: data['pricePerUnit'],
      startTime: data['startTime'],
      status: EnergyOfferStatus.values[data['status']],
      isSelling: data['isSelling'],
    );
  }
  
  // Create from TradeOffer
  factory EnergyOffer.fromTradeOffer(TradeOffer offer, String creatorAddress) {
    return EnergyOffer(
      seller: creatorAddress,
      amount: offer.totalAmount,
      pricePerUnit: offer.pricePerUnit,
      startTime: offer.startTime,
      status: EnergyOfferStatus.pending,
      isSelling: offer.tradeType == 'sell',
    );
  }
}