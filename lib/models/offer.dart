// lib/models/offer.dart

class Offer {
  final int id;
  final int productId;
  final int buyerId;
  final int sellerId;
  final int? actorId;
  final String? action;
  final double price;
  final String? message;
  final String status;
  final int? parentId;
  
  final String? productTitle;
  final double? productPrice;
  final String? productImage;
  final String? buyerName;
  final String? sellerName;
  
  // ✅ ADD THESE PROFILE PICTURE FIELDS
  final String? buyerProfilePic;
  final String? sellerProfilePic;
  final String? actorProfilePic;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Offer({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    this.actorId,
    this.action,
    required this.price,
    this.message,
    required this.status,
    this.parentId,
    this.productTitle,
    this.productPrice,
    this.productImage,
    this.buyerName,
    this.sellerName,
    // ✅ ADD THESE TO CONSTRUCTOR
    this.buyerProfilePic,
    this.sellerProfilePic,
    this.actorProfilePic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      actorId: json['actor_id'],
      action: json['action'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      message: json['message'],
      status: json['status'] ?? 'pending',
      parentId: json['parent_id'],
      productTitle: json['product_title'],
      productPrice: json['product_price'] != null 
          ? double.tryParse(json['product_price'].toString()) 
          : null,
      productImage: json['product_image'],
      buyerName: json['buyer_name'],
      sellerName: json['seller_name'],
      // ✅ ADD THESE TO JSON PARSING
      buyerProfilePic: json['buyer_profile_picture'],
      sellerProfilePic: json['seller_profile_picture'],
      actorProfilePic: json['actor_profile_picture'],
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
      'actor_id': actorId,
      'action': action,
      'price': price,
      'message': message,
      'status': status,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // ✅ ADD THESE TO toJson
      'buyer_profile_picture': buyerProfilePic,
      'seller_profile_picture': sellerProfilePic,
      'actor_profile_picture': actorProfilePic,
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCountered => status == 'countered';
  bool get isCounterOffer => parentId != null;
  
  String getOtherPartyName(bool isReceived) {
    return isReceived ? (buyerName ?? 'Buyer') : (sellerName ?? 'Seller');
  }
  
  String get formattedPrice => 'Rs. ${price.toStringAsFixed(0)}';
  
  // ============ ACTOR METHODS ============
  
  /// Get the correct actor based on offer status (overrides API data)
  Map<String, dynamic> getCorrectActor() {
    // ACCEPTED - always seller
    if (status == 'accepted') {
      return {
        'id': sellerId,
        'name': sellerName ?? 'Seller',
        'role': 'seller',
        'profilePic': sellerProfilePic,
      };
    }
    
    // REJECTED - always seller
    if (status == 'rejected') {
      return {
        'id': sellerId,
        'name': sellerName ?? 'Seller',
        'role': 'seller',
        'profilePic': sellerProfilePic,
      };
    }
    
    // COUNTERED - check who countered
    if (status == 'countered') {
      // If actor exists and matches buyer, buyer countered
      if (actorId != null && actorId == buyerId) {
        return {
          'id': buyerId,
          'name': buyerName ?? 'Buyer',
          'role': 'buyer',
          'profilePic': buyerProfilePic,
        };
      }
      // Otherwise seller countered
      return {
        'id': sellerId,
        'name': sellerName ?? 'Seller',
        'role': 'seller',
        'profilePic': sellerProfilePic,
      };
    }
    
    // PENDING - original actor
    if (actorId != null) {
      if (actorId == buyerId) {
        return {
          'id': buyerId,
          'name': buyerName ?? 'Buyer',
          'role': 'buyer',
          'profilePic': buyerProfilePic,
        };
      } else if (actorId == sellerId) {
        return {
          'id': sellerId,
          'name': sellerName ?? 'Seller',
          'role': 'seller',
          'profilePic': sellerProfilePic,
        };
      }
    }
    
    // Default fallback
    return {
      'id': buyerId,
      'name': buyerName ?? 'Buyer',
      'role': 'buyer',
      'profilePic': buyerProfilePic,
    };
  }
  
  /// Get the last action message
  String getLastActionMessage() {
    if (action == null) return 'sent an offer';
    
    switch (action?.toLowerCase()) {
      case 'created':
        return 'sent an offer';
      case 'accepted':
        return 'accepted the offer';
      case 'rejected':
        return 'rejected the offer';
      case 'countered':
        return 'sent a counter offer';
      default:
        return action ?? 'updated the offer';
    }
  }
  
  /// Get correct action message based on status
  String getCorrectLastActionMessage() {
    if (status == 'accepted') return 'accepted the offer';
    if (status == 'rejected') return 'rejected the offer';
    if (status == 'countered') return 'sent a counter offer';
    return getLastActionMessage();
  }
  
  /// Get correct full description
  String getCorrectLastActionDescription() {
    final actor = getCorrectActor();
    final actionMessage = getCorrectLastActionMessage();
    return '${actor['name']} $actionMessage';
  }
}