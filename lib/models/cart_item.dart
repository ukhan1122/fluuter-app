// lib/models/cart_item.dart
class CartItem {
  final String title;
  final String image;
  final String price;
  int quantity;

  CartItem({
    required this.title,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice {
    final p = double.tryParse(price.replaceAll('Rs.', '').trim()) ?? 0;
    return p * quantity;
  }
}
