// lib/models/product.dart
class Product {
  final int id;
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
      photoUrls: extractedPhotoUrls, // Use the extracted URLs here
      size: json['size'],
      user: json['user'] ?? {},
    );
  }
}