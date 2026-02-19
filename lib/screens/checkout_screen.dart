import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _paymentMethod = 'Cash on Delivery';
  String _deliveryOption = 'Standard Delivery';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  double get _subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get _deliveryCharge => _deliveryOption == 'Standard Delivery' ? 200 : 
                               _deliveryOption == 'Express Delivery' ? 500 : 800;
  double get _total => _subtotal + _deliveryCharge;

  void _confirmOrder() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please review your order details:'),
              const SizedBox(height: 16),
              _buildConfirmDetail('Total Amount', 'Rs.${_total.toStringAsFixed(0)}'),
              _buildConfirmDetail('Payment Method', _paymentMethod),
              _buildConfirmDetail('Delivery Option', _deliveryOption),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive order confirmation via email.',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
             onPressed: () => Navigator.pop(dialogContext),

              child: const Text('Review', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
             onPressed: () async {

  Navigator.pop(dialogContext); // ✅ close confirm dialog safely

  if (!mounted) return;

                
             // 🔥 Close keyboard first
FocusScope.of(context).unfocus();

// Small delay to let keyboard close smoothly
await Future.delayed(const Duration(milliseconds: 200));

// Show loading dialog
BuildContext? loadingDialogContext;


if (mounted) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      loadingDialogContext = ctx;   // ✅ store dialog context
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing your order...'),
          ],
        ),
      );
    },
  );
}

           
                
                // Prepare order items
                final orderItems = widget.cartItems.map((item) {
                  double itemPrice = 0;
                  try {
                    String priceStr = item.price.replaceAll('Rs.', '').replaceAll(',', '').trim();
                    itemPrice = double.parse(priceStr);
                  } catch (e) {
                    print('Error parsing price: ${item.price}');
                  }
                  
                  print('📦 Item: ${item.title}, ProductID: ${item.productId}, SellerID: ${item.sellerId}');
                  
                  return {
                    'product_id': item.productId,
                    'product_title': item.title,
                    'product_image': item.image,
                    'price': itemPrice,
                    'quantity': item.quantity,
                    'total': itemPrice * item.quantity,
                    'seller_id': item.sellerId,
                  };
                }).toList();
                
                // Call API to create order
                final result = await OrderService.createOrder(
                  customerName: _nameController.text,
                  phone: _phoneController.text,
                  email: _emailController.text,
                  address: _addressController.text,
                  city: _cityController.text,
                  subtotal: _subtotal,
                  deliveryCharge: _deliveryCharge,
                  total: _total,
                  paymentMethod: _paymentMethod,
                  deliveryOption: _deliveryOption,
                  items: orderItems,
                );
                
                 if (mounted && loadingDialogContext != null) {
  Navigator.of(loadingDialogContext!).pop();  // ✅ closes ONLY loading dialog
}


                
                // Small delay to ensure dialog is closed
                await Future.delayed(const Duration(milliseconds: 100));
                
                // Show result using post frame callback
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    
                    if (result['success'] == true) {
                      // Clear the cart
                      final cartProvider = Provider.of<CartProvider>(context, listen: false);
                      cartProvider.clearCart();
                      
                      // Show success dialog
                      _showOrderSuccessDialog(result['order_number']);
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Order failed: ${result['message'] ?? 'Please try again'}'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Pay'),
            ),
          ],
        ),
      );
    }
  }

  void _showOrderSuccessDialog(String orderNumber) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Order Confirmed!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Order #$orderNumber',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildConfirmDetail('Total', 'Rs.${_total.toStringAsFixed(0)}'),
                  _buildConfirmDetail('Payment', _paymentMethod),
                  _buildConfirmDetail('Delivery', _deliveryOption),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Row(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: item.image.startsWith('http') 
                ? NetworkImage(item.image) as ImageProvider
                : AssetImage(item.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, 
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('Qty: ${item.quantity}', 
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text('Rs.${item.price}', 
                style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Text('Rs.${item.totalPrice.toStringAsFixed(0)}', 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildDeliveryOption(String name, String time, int price, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _deliveryOption = name),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _deliveryOption == name ? Colors.redAccent : Colors.grey.shade300,
            width: _deliveryOption == name ? 2 : 1,
          ),
          color: _deliveryOption == name ? Colors.redAccent.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _deliveryOption == name ? Colors.redAccent : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, 
                color: _deliveryOption == name ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _deliveryOption == name ? Colors.redAccent : Colors.black,
                  )),
                  const SizedBox(height: 2),
                  Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Text('Rs.$price', style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _deliveryOption == name ? Colors.redAccent : Colors.black,
            )),
            const SizedBox(width: 12),
            Radio(
              value: name,
              groupValue: _deliveryOption,
              activeColor: Colors.redAccent,
              onChanged: (value) => setState(() => _deliveryOption = value.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String name, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = name),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _paymentMethod == name ? color : Colors.grey.shade300,
            width: _paymentMethod == name ? 2 : 1,
          ),
          color: _paymentMethod == name ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _paymentMethod == name ? color : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, 
                color: _paymentMethod == name ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(name, style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _paymentMethod == name ? color : Colors.black,
            )),
            const Spacer(),
            Radio(
              value: name,
              groupValue: _paymentMethod,
              activeColor: color,
              onChanged: (value) => setState(() => _paymentMethod = value.toString()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Information
              _buildSection('Contact Information', Column(
                children: [
                  _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
                  const SizedBox(height: 12),
                  _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
                ],
              )),

              // Delivery Address
              _buildSection('Delivery Address', Column(
                children: [
                  _buildTextField(_addressController, 'Complete Address', Icons.home_outlined),
                  const SizedBox(height: 12),
                  _buildTextField(_cityController, 'City', Icons.location_city_outlined),
                ],
              )),

              // Delivery Options
              _buildSection('Delivery Options', Column(
                children: [
                  _buildDeliveryOption('Standard Delivery', '3-5 days', 200, Icons.delivery_dining),
                  const SizedBox(height: 8),
                  _buildDeliveryOption('Express Delivery', '1-2 days', 500, Icons.flash_on),
                  const SizedBox(height: 8),
                  _buildDeliveryOption('Same Day Delivery', 'Today', 800, Icons.bolt),
                ],
              )),

              // Payment Method
              _buildSection('Payment Method', Column(
                children: [
                  _buildPaymentOption('Cash on Delivery', Icons.money_off_csred, Colors.green),
                  const SizedBox(height: 8),
                  _buildPaymentOption('Credit/Debit Card', Icons.credit_card, Colors.blue),
                  const SizedBox(height: 8),
                  _buildPaymentOption('EasyPaisa', Icons.phone_android, Colors.orange),
                  const SizedBox(height: 8),
                  _buildPaymentOption('JazzCash', Icons.phone_iphone, Colors.purple),
                ],
              )),

              // Order Summary
              _buildSection('Order Summary', Column(
                children: [
                  ...widget.cartItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOrderItem(item),
                  )),
                  const Divider(height: 24),
                  _buildPriceRow('Subtotal', 'Rs.${_subtotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Delivery Fee', 'Rs.${_deliveryCharge.toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildPriceRow('Total Amount', 'Rs.${_total.toStringAsFixed(0)}', isTotal: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text('Delivery charges included',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ],
              )),

              // Confirm Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 22),
                      SizedBox(width: 8),
                      Text('Confirm Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          color: isTotal ? Colors.black : Colors.grey.shade700,
        )),
        Text(value, style: TextStyle(
          fontSize: isTotal ? 20 : 16,
          fontWeight: FontWeight.bold,
          color: isTotal ? Colors.redAccent : Colors.black,
        )),
      ],
    );
  }
}