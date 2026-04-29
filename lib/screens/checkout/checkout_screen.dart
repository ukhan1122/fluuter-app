import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../utils/image_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

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
  
  // Address selection
  List<Map<String, dynamic>> _savedAddresses = [];
  int? _selectedAddressId;
  bool _isLoadingAddresses = false;
  bool _useNewAddress = false;
  bool _addressesFetched = false; // Track if addresses have been fetched

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _clearInvalidGuestId();
    _loadUserProfile();
    
    // Don't load addresses automatically - only when needed
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isLoggedIn = token != null && token.isNotEmpty;
    
    if (isLoggedIn) {
      try {
        final userProfile = await ApiService.getUserProfile(token);
        if (userProfile['success'] == true && mounted) {
          final userData = userProfile['data'];
          setState(() {
            _nameController.text = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
            _emailController.text = userData['email'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> _fetchUserAddresses() async {
  if (_addressesFetched) return;
  
  print('🕐 START fetching addresses at: ${DateTime.now()}');
  final stopwatch = Stopwatch()..start();
  
  setState(() {
    _isLoadingAddresses = true;
  });
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      setState(() {
        _isLoadingAddresses = false;
      });
      return;
    }
    
    final url = Uri.parse('${ApiService.baseUrl}/api/v1/user/address');
    print('🕐 URL: $url');
    
    final headers = AppConfig.getHeaders(token: token);
    
    print('🕐 Sending request...');
    final response = await http.get(url, headers: headers);
    print('🕐 Response received in: ${stopwatch.elapsedMilliseconds}ms');
    
    if (response.statusCode == 200) {
      print('🕐 Parsing response...');
      final data = json.decode(response.body);
      List<Map<String, dynamic>> addresses = [];
      
      if (data['data'] != null) {
        if (data['data'] is List) {
          addresses = List<Map<String, dynamic>>.from(data['data']);
        } else if (data['data'] is Map) {
          addresses = [Map<String, dynamic>.from(data['data'])];
        }
      }
      
      print('🕐 Filtering addresses...');
      addresses = addresses.where((addr) => 
        addr['address_type'] == 'shipping' || addr['address_type'] == 'home'
      ).toList();
      
      setState(() {
        _savedAddresses = addresses;
        if (addresses.isNotEmpty) {
          _selectedAddressId = addresses.first['id'];
        }
        _isLoadingAddresses = false;
        _addressesFetched = true;
      });
      print('🕐 Done! Total time: ${stopwatch.elapsedMilliseconds}ms');
    } else {
      print('🕐 Failed with status: ${response.statusCode}');
      setState(() {
        _isLoadingAddresses = false;
        _addressesFetched = true;
      });
    }
  } catch (e) {
    print('🕐 Error: $e');
    setState(() {
      _isLoadingAddresses = false;
      _addressesFetched = true;
    });
  }
}

  double get _subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get _deliveryCharge => _deliveryOption == 'Standard Delivery' ? 200 : 
                               _deliveryOption == 'Express Delivery' ? 500 : 800;
  double get _total => _subtotal + _deliveryCharge;

  Future<String> _getGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString('guest_id');
    
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    if (guestId != null && !uuidRegex.hasMatch(guestId)) {
      guestId = null;
      await prefs.remove('guest_id');
    }
    
    if (guestId == null) {
      guestId = const Uuid().v4();
      await prefs.setString('guest_id', guestId);
    }
    
    return guestId;
  }

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
                Navigator.pop(dialogContext);
                if (!mounted) return;
                
                FocusScope.of(context).unfocus();
                await Future.delayed(const Duration(milliseconds: 200));
                
                BuildContext? loadingDialogContext;
                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      loadingDialogContext = ctx;
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
                
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');
                final isLoggedIn = token != null && token.isNotEmpty;
                
                int? addressId = null;
                final sellerId = widget.cartItems.first.sellerId;
                
                Map<String, dynamic> result;
                
                if (isLoggedIn) {
                  if (_useNewAddress) {
                    // Create new address
                    final addressResult = await ApiService.createAddress(
                      address: _addressController.text.trim(),
                      city: _cityController.text.trim(),
                      phone: _phoneController.text.trim(),
                    );
                    
                    if (!addressResult['success']) {
                      if (mounted && loadingDialogContext != null) {
                        Navigator.of(loadingDialogContext!).pop();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to save address. Please try again.')),
                      );
                      return;
                    }
                    addressId = addressResult['data']['id'];
                  } else {
                    if (_selectedAddressId == null) {
                      if (mounted && loadingDialogContext != null) {
                        Navigator.of(loadingDialogContext!).pop();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a delivery address')),
                      );
                      return;
                    }
                    addressId = _selectedAddressId;
                  }
                  
                  // Sync cart items to backend
                  for (var item in widget.cartItems) {
                    await ApiService.addToCart(
                      productId: item.productId,
                      quantity: item.quantity,
                    );
                  }
                  
                  final cartItemsForBackend = widget.cartItems.map((item) {
                    return {
                      'product_id': item.productId,
                      'quantity': item.quantity,
                    };
                  }).toList();
                  
                  result = await ApiService.createOrder(
                    orderData: {
                      'seller_id': sellerId,
                      'delivery_address_id': addressId,
                      'cart_items': cartItemsForBackend,
                    },
                  );
                } else {
                  // Guest checkout
                  final guestId = await _getGuestId();
                  
                  for (var item in widget.cartItems) {
                    await ApiService.addToGuestCart(
                      guestId: guestId,
                      productId: item.productId,
                      quantity: item.quantity,
                    );
                  }
                  
                  final nameParts = _nameController.text.trim().split(' ');
                  final firstName = nameParts.first;
                  final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
                  
                  final guestPayload = {
                    'guest_info': {
                      'guest_id': guestId,
                      'email': _emailController.text.trim(),
                      'first_name': firstName,
                      'last_name': lastName,
                      'city': _cityController.text.trim(),
                      'address': _addressController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'subscribe': false,
                      'save_info': false,
                      'text_offers': false,
                    },
                    'seller_id': sellerId,
                    'cart_items': widget.cartItems.map((item) {
                      return {
                        'product_id': item.productId,
                        'quantity': item.quantity,
                      };
                    }).toList(),
                  };
                  
                  result = await ApiService.createGuestOrder(guestPayload);
                }
                
                if (mounted && loadingDialogContext != null) {
                  Navigator.of(loadingDialogContext!).pop();
                }
                
                if (mounted) {
                  if (result['success'] == true) {
                    final cartProvider = Provider.of<CartProvider>(context, listen: false);
                    cartProvider.clearCart();
                    _showOrderSuccessDialog(result['data']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order failed: ${result['message'] ?? 'Please try again'}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
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

  Future<void> _clearInvalidGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString('guest_id');
    
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    if (guestId != null && !uuidRegex.hasMatch(guestId)) {
      await prefs.remove('guest_id');
    }
  }

  void _showOrderSuccessDialog(Map<String, dynamic> orderData) {
    if (!mounted) return;
    
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    final subtotal = toDouble(orderData['subtotal']) != 0 
        ? toDouble(orderData['subtotal']) 
        : _subtotal;
        
    final deliveryFee = toDouble(orderData['delivery_fee']) != 0 
        ? toDouble(orderData['delivery_fee']) 
        : _deliveryCharge;
        
    final totalAmount = toDouble(orderData['total_amount']) != 0 
        ? toDouble(orderData['total_amount']) 
        : _total;
        
    final trackingNo = orderData['tracking_no']?.toString() ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
                'Tracking #${trackingNo.isNotEmpty ? trackingNo : 'N/A'}',
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
                    _buildConfirmDetail('Subtotal', 'Rs.${subtotal.toStringAsFixed(0)}'),
                    _buildConfirmDetail('Delivery Fee', 'Rs.${deliveryFee.toStringAsFixed(0)}'),
                    const Divider(height: 16),
                    _buildConfirmDetail('Total', 'Rs.${totalAmount.toStringAsFixed(0)}'),
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
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue Shopping'),
            ),
          ],
        );
      },
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? Function(String?)? customValidator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
      validator: customValidator ?? (v) => v == null || v.isEmpty ? 'Required' : null,
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
              ? NetworkImage(fixImageUrl(item.image)) as ImageProvider
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

Widget _buildAddressSection() {
  // Check if user is logged in
  return FutureBuilder(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      final prefs = snapshot.data;
      final token = prefs?.getString('auth_token');
      final isLoggedIn = token != null && token.isNotEmpty;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For guest users, only show New Address option
          if (!isLoggedIn)
            _buildNewAddressForm()
          else
            Column(
              children: [
                // Toggle between saved and new address (only for logged-in users)
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        title: 'Saved Address',
                        icon: Icons.bookmark_border,
                        isSelected: !_useNewAddress,
                        onTap: () {
                          setState(() {
                            _useNewAddress = false;
                            if (!_addressesFetched) {
                              _fetchUserAddresses();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToggleButton(
                        title: 'New Address',
                        icon: Icons.add_location_alt,
                        isSelected: _useNewAddress,
                        onTap: () => setState(() => _useNewAddress = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (!_useNewAddress)
                  _buildSavedAddressesUI()
                else
                  _buildNewAddressForm(),
              ],
            ),
        ],
      );
    },
  );
}
  

Widget _buildSavedAddressesUI() {
  if (_isLoadingAddresses) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your addresses...'),
          ],
        ),
      ),
    );
  }
  
  // Always fetch if addresses are empty and not fetched yet
  if (_savedAddresses.isEmpty && !_addressesFetched && !_isLoadingAddresses) {
    // Trigger fetch immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserAddresses();
    });
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching your addresses...'),
          ],
        ),
      ),
    );
  }
  
  if (_savedAddresses.isEmpty && _addressesFetched) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.orange.shade400),
          const SizedBox(height: 12),
          Text(
            'No saved addresses found',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Address" to add one',
            style: TextStyle(color: Colors.orange.shade600),
          ),
        ],
      ),
    );
  }
  
  // Rest of your existing code for dropdown...
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<int>(
        value: _selectedAddressId,
        isExpanded: true,
        isDense: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(Icons.location_on, color: Colors.redAccent, size: 20),
        ),
        items: _savedAddresses.map((address) {
          String fullAddress = address['address_line_1'] ?? '';
          String city = address['city'] ?? '';
          String region = address['state_province_or_region'] ?? '';
          
          String displayAddress = fullAddress;
          if (city.isNotEmpty) {
            displayAddress = '$fullAddress, $city';
          }
          if (region.isNotEmpty && city.isEmpty) {
            displayAddress = '$fullAddress, $region';
          }
          
          if (displayAddress.length > 45) {
            displayAddress = displayAddress.substring(0, 42) + '...';
          }
          
          return DropdownMenuItem<int>(
            value: address['id'],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayAddress,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedAddressId = value;
          });
        },
        hint: const Text('Select delivery address'),
      ),
      const SizedBox(height: 12),
      if (_selectedAddressId != null)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Address selected for delivery',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}







  
  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNewAddressForm() {
    return Column(
      children: [
        _buildTextField(_addressController, 'Complete Address', Icons.home_outlined),
        const SizedBox(height: 12),
        _buildTextField(_cityController, 'City', Icons.location_city_outlined),
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
                  _buildTextField(
                    _nameController, 
                    'Full Name', 
                    Icons.person_outline,
                    customValidator: (v) {
                      if (v == null || v.isEmpty) return 'Full name is required';
                      if (v.trim().split(' ').length < 2) return 'Please enter both first and last name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _phoneController, 
                    'Phone Number', 
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    customValidator: (v) {
                      if (v == null || v.isEmpty) return 'Phone number is required';
                      if (v.length < 10) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _emailController, 
                    'Email Address', 
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    customValidator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                ],
              )),

              // Delivery Address Section - Improved
              _buildSection('Delivery Address', _buildAddressSection()),

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