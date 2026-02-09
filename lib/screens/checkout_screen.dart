import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'name': TextEditingController(text: 'Ali Khan'),
    'phone': TextEditingController(text: '03001234567'),
    'email': TextEditingController(text: 'ali.khan@email.com'),
    'address': TextEditingController(text: 'House 123, Street 45, Gulberg'),
    'city': TextEditingController(text: 'Lahore'),
  };

  String _paymentMethod = 'Cash on Delivery';
  String _deliveryOption = 'Standard Delivery';
  bool _showPaymentOptions = false;
  bool _showDeliveryOptions = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Cash on Delivery', 'icon': Icons.money_off_csred},
    {'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'name': 'EasyPaisa', 'icon': Icons.phone_android},
    {'name': 'JazzCash', 'icon': Icons.phone_iphone},
  ];

  final List<Map<String, dynamic>> _deliveryOptions = [
    {'name': 'Standard Delivery', 'time': '3-5 days', 'price': 200},
    {'name': 'Express Delivery', 'time': '1-2 days', 'price': 500},
    {'name': 'Same Day Delivery', 'time': 'Today', 'price': 800},
  ];

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  double get _subtotal {
    double total = 0;
    for (var item in widget.cartItems) {
      String priceStr =
          item.price.replaceAll('Rs.', '').replaceAll(',', '').trim();
      double price = double.tryParse(priceStr) ?? 0;
      total += price * item.quantity;
    }
    return total;
  }

  double get _deliveryCharge {
    final option =
        _deliveryOptions.firstWhere((opt) => opt['name'] == _deliveryOption);
    return (option['price'] as int).toDouble();
  }

  double get _total => _subtotal + _deliveryCharge;

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: Rs.${_total.toStringAsFixed(0)}'),
            Text('Payment: $_paymentMethod'),
            Text('Delivery: $_deliveryOption'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),    
                  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white, 
    foregroundColor: Colors.redAccent, 
  ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            },
             style: ElevatedButton.styleFrom(
    backgroundColor: Colors.redAccent, 
    foregroundColor: Colors.white, 
  ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: child)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(item.image),
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
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Qty: ${item.quantity}'),
              ],
            ),
          ),
          Text(item.price,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String key, String label, IconData icon,
      {TextInputType? type, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        maxLines: lines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (v) =>
            v == null || v.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildCollapsibleSection(
    String title,
    String selectedValue,
    bool isExpanded,
    VoidCallback onToggle,
    List<Map<String, dynamic>> options,
    Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedValue),
                  trailing: IconButton(
                    icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: onToggle,
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(),
                  ...options.map((option) => ListTile(
                        title: Text(option['name']),
                        trailing: Radio<String>(
                          value: option['name'],
                          groupValue: selectedValue,
                          onChanged: (v) => onSelect(v!),
                        ),
                        onTap: () => onSelect(option['name']),
                      )),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CONTACT INFO
              _buildSection(
                'Contact Information',
                Column(
                  children: [
                    _buildTextField('name', 'Full Name', Icons.person),
                    _buildTextField('phone', 'Phone', Icons.phone),
                    _buildTextField('email', 'Email', Icons.email),
                  ],
                ),
              ),

              // ADDRESS
              _buildSection(
                'Delivery Address',
                Column(
                  children: [
                    _buildTextField('address', 'Address', Icons.home,
                        lines: 2),
                    _buildTextField('city', 'City', Icons.location_city),
                  ],
                ),
              ),

              // DELIVERY
              _buildCollapsibleSection(
                'Delivery Options',
                _deliveryOption,
                _showDeliveryOptions,
                () => setState(
                    () => _showDeliveryOptions = !_showDeliveryOptions),
                _deliveryOptions,
                (v) => setState(() {
                  _deliveryOption = v;
                  _showDeliveryOptions = false;
                }),
              ),

              // PAYMENT
              _buildCollapsibleSection(
                'Payment Method',
                _paymentMethod,
                _showPaymentOptions,
                () => setState(
                    () => _showPaymentOptions = !_showPaymentOptions),
                _paymentMethods,
                (v) => setState(() {
                  _paymentMethod = v;
                  _showPaymentOptions = false;
                }),
              ),

              // PLACE ORDER (MOVED UP)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Confirm Order',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // ORDER SUMMARY (AFTER PLACE ORDER)
              Padding(
  padding: const EdgeInsets.only(top: 24), // <-- adds margin from top
  child: _buildSection(
                'Order Summary',
                Column(
                  children: [
                    ...widget.cartItems.map(_buildOrderItem),
                    const Divider(),
                    _buildPriceRow(
                        'Subtotal', 'Rs.${_subtotal.toStringAsFixed(0)}'),
                    _buildPriceRow(
                        'Delivery', 'Rs.${_deliveryCharge.toStringAsFixed(0)}'),
                    const Divider(),
                    _buildPriceRow(
                        'Total', 'Rs.${_total.toStringAsFixed(0)}',
                        isTotal: true),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    ); 
  }
}
