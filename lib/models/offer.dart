// lib/models/offer.dart

class Offer {
  final int id;
  final int productId;
  final int buyerId;
  final int sellerId;
  final double price;
  final String? message;
  final String status; // pending, accepted, rejected, countered
  
  // Simplified fields from API (FLAT structure)
  final String? productTitle;
  final double? productPrice;
  final String? productImage;
  final String? buyerName;
  final String? sellerName;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Offer({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.price,
    this.message,
    required this.status,
    this.productTitle,
    this.productPrice,
    this.productImage,
    this.buyerName,
    this.sellerName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      message: json['message'],
      status: json['status'] ?? 'pending',
      
      // Simplified fields (FLAT structure)
      productTitle: json['product_title'],
      productPrice: json['product_price'] != null 
          ? double.tryParse(json['product_price'].toString()) 
          : null,
      productImage: json['product_image'],
      buyerName: json['buyer_name'],
      sellerName: json['seller_name'],
      
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'price': price,
      'message': message,
      'status': status,
    };
  }

  // Helper getters for UI
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCountered => status == 'countered';
  
  // Display price with currency
  String get formattedPrice => 'Rs. ${price.toStringAsFixed(0)}';
}