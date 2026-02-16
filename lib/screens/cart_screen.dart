// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart'; 
import 'package:provider/provider.dart'; // ADD THIS LINE
import '../providers/cart_provider.dart'; // ADD THIS LINE

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
// Get cart data from Provider
List<CartItem> get cartItems => Provider.of<CartProvider>(context).cartItems;
double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.totalPrice);
int get totalQuantity => cartItems.fold(0, (sum, item) => sum + item.quantity);

  Widget _buildCartItem(CartItem item, int index) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: item.image.startsWith('http')
            ? Image.network(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            : Image.asset(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
              ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: () => Provider.of<CartProvider>(context, listen: false).removeFromCart(index),
            child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Rs.${item.price}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.redAccent)),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.remove, size: 16, color: item.quantity > 1 ? Colors.black : Colors.grey.shade400),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  if (item.quantity > 1) {
                    cartProvider.updateQuantity(index, item.quantity - 1);
                  } else {
                    cartProvider.removeFromCart(index);
                  }
                },
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(fontSize: 14))),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () => Provider.of<CartProvider>(context, listen: false).updateQuantity(index, item.quantity + 1),
              ),
            ]),
          ),
          const Spacer(),
          Text('Rs.${(double.parse(item.price.replaceAll('Rs.', '')) * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ])),
    ]),
  );
}

  Widget _buildEmptyCart() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
    const SizedBox(height: 16),
    const Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    const SizedBox(height: 24),
    ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
        child: const Text('Continue Shopping', style: TextStyle(color: Colors.white)),
    ),
  ]));

  Widget _buildCheckoutPanel() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Subtotal', style: TextStyle(fontSize: 14)),
        Text('Rs.${totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Delivery', style: TextStyle(fontSize: 14)),
        const Text('Rs.50', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      const Divider(height: 1),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Rs.${(totalPrice + 50).toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.redAccent)),
      ]),
      const SizedBox(height: 6),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(cartItems: cartItems),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 20),
              SizedBox(width: 8),
              Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Shopping', style: TextStyle(fontSize: 14, color: Colors.black87))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: cartItems.isEmpty ? null : [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
              child: Text(totalQuantity.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            )),
          ),
        ],
      ),
     body: cartItems.isEmpty ? _buildEmptyCart() : Column(children: [
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
         itemCount: cartItems.length,
         itemBuilder: (context, index) => _buildCartItem(cartItems[index], index),
        )),
        _buildCheckoutPanel(),
      ]),
    );
  }
}