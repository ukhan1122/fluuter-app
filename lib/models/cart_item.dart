// lib/models/cart_item.dart
class CartItem {
  final int productId;
  final int sellerId;  // ADD THIS - seller ID for the product
  final String title;
  final String image;
  final String price;
  int quantity;

  CartItem({
    required this.productId,
    required this.sellerId,  // ADD THIS
    required this.title,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice {
    final p = double.tryParse(price.replaceAll('Rs.', '').trim()) ?? 0;
    return p * quantity;
  }

  // Optional: Add toJson method for storage
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sellerId': sellerId,  // ADD THIS
      'title': title,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  // Optional: Add fromJson factory for retrieval
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? 0,
      sellerId: json['sellerId'] ?? 1,  // ADD THIS with default
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      price: json['price'] ?? 'Rs.0',
      quantity: json['quantity'] ?? 1,
    );
  }
}