// lib/models/product.dart
class Product {
  final int id;
  final int userId;  // ← This is the seller ID - use this!
  final String title;
  final String description;
  final double price;
  final String? location;
  final String? city;
  final String? shippingType;
  final bool active;
  final bool sold;
  final bool allowOffers;
  final int quantityLeft;
  final String? approvalStatus;
  final String? categoryName;
  final String? categoryGroup;
  final String? brandName;
  final String? conditionTitle;
  final List<String> photoUrls; 
  final Map<String, dynamic>? size;
  final Map<String, dynamic> user;

  Product({
    required this.id,
    required this.userId,  // ← This is the seller ID
    required this.title,
    required this.description,
    required this.price,
    this.location,
    this.city,
    this.shippingType,
    required this.active,
    required this.sold,
    required this.allowOffers,
    required this.quantityLeft,
    this.approvalStatus,
    this.categoryName,
    this.categoryGroup,
    this.brandName,
    this.conditionTitle,
    required this.photoUrls,
    this.size,
    required this.user,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final List<String> extractedPhotoUrls = [];
    
    if (json['photos'] != null && json['photos'] is List) {
      final photosList = json['photos'] as List;
      
      for (var photo in photosList) {
        if (photo is Map) {
          // Extract image_path from photo object
          final imagePath = photo['image_path']?.toString();
          if (imagePath != null && imagePath.isNotEmpty) {
            extractedPhotoUrls.add(imagePath);
          }
        } else if (photo is String && photo.isNotEmpty) {
          // If photo is already a string URL
          extractedPhotoUrls.add(photo);
        }
      }
    }
    
    return Product(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,  // ← This is the seller ID
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      location: json['location'],
      city: json['city'],
      shippingType: json['shipping_type'],
      active: json['active'] ?? false,
      sold: json['sold'] ?? false,
      allowOffers: json['allow_offers'] ?? false,
      quantityLeft: json['quantity_left'] ?? 0,
      approvalStatus: json['approval_status'],
      categoryName: json['category']?['name'],
      categoryGroup: json['category']?['group'],
      brandName: json['brand']?['name'],
      conditionTitle: json['condition']?['title'],
      photoUrls: extractedPhotoUrls,
      size: json['size'],
      user: json['user'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    // Reconstruct the photos array in the same format as fromJson expects
    final List<Map<String, dynamic>> photosList = [];
    for (var url in photoUrls) {
      photosList.add({'image_path': url});
    }

    return {
      'id': id,
      'user_id': userId,  // ← This is the seller ID
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'city': city,
      'shipping_type': shippingType,
      'active': active,
      'sold': sold,
      'allow_offers': allowOffers,
      'quantity_left': quantityLeft,
      'approval_status': approvalStatus,
      'category': categoryName != null ? {'name': categoryName, 'group': categoryGroup} : null,
      'brand': brandName != null ? {'name': brandName} : null,
      'condition': conditionTitle != null ? {'title': conditionTitle} : null,
      'photos': photosList,
      'size': size,
      'user': user,
    };
  }
}