import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';





class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? _authToken;
  
  // Product Details
  String _title = '';
  String _description = '';
  int _quantity = 1;
  double _price = 0.0;
  String _categoryId = '';
  String _brandName = '';
  String _conditionId = '';
  String _standardSize = '';
  bool _allowOffers = true;
  bool _showDetailedSizes = false;
  String _shippingType = 'pickup'; // NEW: Shipping type field
  
  // Detailed Measurements
  TextEditingController _chestController = TextEditingController();
  TextEditingController _waistController = TextEditingController();
  TextEditingController _hipsController = TextEditingController();
  TextEditingController _inseamController = TextEditingController();
  TextEditingController _sleeveController = TextEditingController();
  TextEditingController _shoulderController = TextEditingController();
  
  // Address Details
  String _addressLine1 = '';
  String _addressLine2 = '';
  String _city = '';
  String _state = 'Punjab';
  String _zipCode = '';
  String _country = 'Pakistan';
  String? _addressId; // NEW: Will store created address ID
  
  // API Data
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _conditions = [];
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _sizes = [];
  List<XFile?> _selectedImages = [];
  
  // UI States
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasLoadedBrands = false;
  bool _hasLoadedSizes = false;
  
  // City & State Lists
  final List<String> _cities = [
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi', 'Faisalabad',
    'Multan', 'Peshawar', 'Quetta', 'Gujranwala', 'Sialkot',
  ];
  
  final List<String> _states = [
    'Punjab', 'Sindh', 'Khyber Pakhtunkhwa', 'Balochistan',
    'Gilgit-Baltistan', 'Azad Kashmir', 'Islamabad Capital Territory'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _inseamController.dispose();
    _sleeveController.dispose();
    _shoulderController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    
    try {
      _categories = await ApiService.getCategories();
      if (_categories.isNotEmpty && _categoryId.isEmpty) {
        _categoryId = _categories.first['id']?.toString() ?? '';
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
    }
    
    try {
      _conditions = await ApiService.getConditions();
      if (_conditions.isNotEmpty && _conditionId.isEmpty) {
        _conditionId = _conditions.first['id']?.toString() ?? '';
      }
    } catch (e) {
      print('❌ Error loading conditions: $e');
      _conditions = [
        {'id': '1', 'name': 'Brand new'},
        {'id': '2', 'name': 'Like new'},
        {'id': '3', 'name': 'Used - Excellent'},
        {'id': '4', 'name': 'Used - Good'},
        {'id': '5', 'name': 'Used - Fair'},
      ];
    }
    
    try {
      _brands = await ApiService.getBrands();
      _hasLoadedBrands = true;
    } catch (e) {
      print('❌ Error loading brands: $e');
      _hasLoadedBrands = false;
    }
    
    try {
      _sizes = await ApiService.getSizes();
      _hasLoadedSizes = true;
    } catch (e) {
      print('❌ Error loading sizes: $e');
      _hasLoadedSizes = false;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile?> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.where((image) => image != null));
          if (_selectedImages.length > 8) {
            _selectedImages = _selectedImages.sublist(0, 8);
            _showSnackBar('Maximum 8 images allowed', Colors.orange);
          }
        });
        _showSnackBar('Added ${images.length} image(s)', Colors.green);
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      _showSnackBar('Error picking images', Colors.red);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Listing',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION: Photos
                    _buildSectionHeader('Photos', 'Add up to 8 clear images'),
                    _buildPhotosSection(),
                    
                    const SizedBox(height: 24),
                    
                    // SECTION: Product Information
                    _buildSectionHeader('Product Information', 'Fill in all required fields'),
                    
                    // Title
                    _buildFormField(
                      label: 'Product Title*',
                      hint: 'e.g., Nike Air Max 270',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _title = v!,
                    ),
                    
                    // Description
                    _buildFormField(
                      label: 'Description*',
                      hint: 'Describe condition, features, size, etc.',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _description = v!,
                      maxLines: 4,
                    ),
                    
                    // Category
                    _buildDropdownField(
                      label: 'Category*',
                      value: _categoryId.isEmpty ? null : _categoryId,
                      hint: 'Select Category',
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['id']?.toString() ?? '',
                          child: Text(cat['name']?.toString() ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          setState(() => _categoryId = value);
                        }
                      },
                    ),
                    
                    // Brand
                    _buildBrandField(),
                    
                    // Condition
                    _buildDropdownField(
                      label: 'Condition*',
                      value: _conditionId.isEmpty ? null : _conditionId,
                      hint: 'Select Condition',
                      items: _conditions.map((cond) {
                        return DropdownMenuItem<String>(
                          value: cond['id']?.toString() ?? '',
                          child: Text(cond['name']?.toString() ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          setState(() => _conditionId = value);
                        }
                      },
                    ),
                    
                    // Standard Size
                    _buildStandardSizeField(),
                    
                    // Detailed Measurements Toggle
                    _buildToggleSwitch(
                      label: 'Add Detailed Measurements (Optional)',
                      value: _showDetailedSizes,
                      onChanged: (v) => setState(() => _showDetailedSizes = v ?? false),
                    ),
                    
                    // Detailed Measurements Section
                    if (_showDetailedSizes) ...[
                      const SizedBox(height: 12),
                      _buildDetailedMeasurementsSection(),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // SECTION: Pickup Address
                    _buildSectionHeader('Pickup Address', 'Where buyers can collect the item'),
                    
                    // Address Line 1
                    _buildFormField(
                      label: 'Address Line 1*',
                      hint: 'e.g., 123 Main Street, Building Name',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _addressLine1 = v!,
                    ),
                    
                    // Address Line 2
                    _buildFormField(
                      label: 'Address Line 2 (Optional)',
                      hint: 'e.g., Apartment/Suite/Floor',
                      validator: (v) => null,
                      onSaved: (v) => _addressLine2 = v ?? '',
                    ),
                    
                    // City
                    _buildDropdownField(
                      label: 'City*',
                      value: _city.isEmpty ? null : _city,
                      hint: 'Select City',
                      items: _cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          setState(() => _city = value);
                        }
                      },
                    ),
                    
                    // State
                    _buildDropdownField(
                      label: 'State/Province*',
                      value: _state,
                      hint: 'Select State',
                      items: _states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _state = value);
                        }
                      },
                    ),
                    
                    // Zip Code
                    _buildFormField(
                      label: 'ZIP/Postal Code*',
                      hint: 'e.g., 54000',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _zipCode = v!,
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // SECTION: Shipping & Pricing
                    _buildSectionHeader('Shipping & Pricing', ''),
                    
                    // Shipping Type - NEW FIELD
                    _buildDropdownField(
                      label: 'Shipping Type*',
                      value: _shippingType,
                      hint: 'Select Shipping Type',
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'pickup',
                          child: Text('Pickup Only'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'delivery',
                          child: Text('Delivery Only'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'both',
                          child: Text('Pickup & Delivery'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _shippingType = value);
                        }
                      },
                    ),
                    
                    // Quantity & Price Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Quantity*',
                            hint: '1',
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            onSaved: (v) => _quantity = int.tryParse(v!) ?? 1,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Price (PKR)*',
                            hint: '0.00',
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid number';
                              if (double.parse(v) <= 0) return 'Must be > 0';
                              return null;
                            },
                            onSaved: (v) => _price = double.parse(v!),
                            keyboardType: TextInputType.number,
                            prefixIcon: const Text('PKR ', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                    
                    // Allow Offers
                    _buildToggleSwitch(
                      label: 'Allow offers from buyers',
                      value: _allowOffers,
                      onChanged: (v) => setState(() => _allowOffers = v ?? true),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ========== UI COMPONENTS ==========

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: prefixIcon,
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              style: const TextStyle(fontSize: 15),
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: validator,
              onSaved: onSaved,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
                items: items,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.red,
            activeTrackColor: Colors.red[200],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImages[index]!.path)),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[300]!,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedImages.length}/8 added',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brand*',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_hasLoadedBrands && _brands.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _brandName.isEmpty ? null : _brandName,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  hint: const Text('Select Brand'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Select Brand'),
                    ),
                    ..._brands.map((brand) {
                      final name = brand['name']?.toString() ?? 'Unknown';
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _brandName = value ?? '';
                    });
                  },
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'e.g., Nike, Samsung, Apple',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _brandName = v!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStandardSizeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Standard Size*',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_hasLoadedSizes && _sizes.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _standardSize.isEmpty ? null : _standardSize,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  hint: const Text('Select Standard Size'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Select Size'),
                    ),
                    ..._sizes.map((size) {
                      final name = size['name']?.toString() ?? 'Unknown';
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    const DropdownMenuItem<String>(
                      value: 'custom',
                      child: Text('Custom Size'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _standardSize = value ?? '';
                    });
                  },
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'e.g., S, M, L, XL or 32, 34, 36',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _standardSize = v!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedMeasurementsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Measurements (inches) - Optional',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Row 1: Chest & Waist
          Row(
            children: [
              Expanded(
                child: _buildMeasurementField(
                  label: 'Chest (inches)',
                  hint: '40',
                  controller: _chestController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementField(
                  label: 'Waist (inches)',
                  hint: '32',
                  controller: _waistController,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row 2: Hips & Inseam
          Row(
            children: [
              Expanded(
                child: _buildMeasurementField(
                  label: 'Hips (inches)',
                  hint: '42',
                  controller: _hipsController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementField(
                  label: 'Inseam (inches)',
                  hint: '32',
                  controller: _inseamController,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row 3: Sleeve & Shoulder
          Row(
            children: [
              Expanded(
                child: _buildMeasurementField(
                  label: 'Sleeve (inches)',
                  hint: '34',
                  controller: _sleeveController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementField(
                  label: 'Shoulder (inches)',
                  hint: '18',
                  controller: _shoulderController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitListing,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: Colors.red.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Publish Listing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

 Future<void> _submitListing() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    
    // Validate required fields
    if (_authToken == null) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }
    
    if (_city.isEmpty) {
      _showSnackBar('Please select a city', Colors.red);
      return;
    }
    
    if (_addressLine1.isEmpty) {
      _showSnackBar('Please enter address line 1', Colors.red);
      return;
    }
    
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please add at least 1 image', Colors.red);
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    // Convert images to file paths
    List<String> imagePaths = [];
    for (var image in _selectedImages) {
      if (image != null) {
        imagePaths.add(File(image.path).path);
      }
    }
    
    try {
      String? addressId;
      
      // Try to create address with correct field names
      try {
        final addressData = {
          'address_line_1': _addressLine1,
          'address_line_2': _addressLine2.isEmpty ? '' : _addressLine2,
          'city': _city,
          'state_province_or_region': _state,
          'zip_or_postal_code': _zipCode,
          'country': _country,
          'address_type': 'pickup',
        };
        
        print('🏠 Creating address with data: $addressData');
        
        final addressResponse = await http.post(
          Uri.parse('${ApiService.baseUrl}/api/v1/user/address'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
            'ngrok-skip-browser-warning': 'true',
          },
          body: jsonEncode(addressData),
        ).timeout(const Duration(seconds: 15));
        
        if (addressResponse.statusCode == 200 || addressResponse.statusCode == 201) {
          final addressResult = json.decode(addressResponse.body);
          addressId = addressResult['data']?['id']?.toString() ?? 
                      addressResult['id']?.toString();
          
          if (addressId != null && addressId.isNotEmpty) {
            print('✅ Address created with ID: $addressId');
          }
        }
      } catch (e) {
        print('⚠️ Address creation error: $e');
      }
      
      // 2. Create listing
      final Map<String, dynamic> listingData = {
        'title': _title,
        'description': _description,
        'quantity': _quantity,
        'price': _price.toString(),
        'category_id': _categoryId,
        'brand_name': _brandName,
        'condition_id': _conditionId,
        'size': _standardSize,
        'allow_offers': _allowOffers,
        'city': _city,
        'location': _addressLine1,
        'shipping_type': _shippingType,
        'active': true,
        'sold': false,
      };
      
      // Add address_id if available
      if (addressId != null && addressId.isNotEmpty) {
        listingData['address_id'] = addressId;
      }
      
      // Add detailed measurements if available
      if (_chestController.text.isNotEmpty) {
        listingData['chest_size'] = _chestController.text;
      }
      if (_waistController.text.isNotEmpty) {
        listingData['waist_size'] = _waistController.text;
      }
      if (_hipsController.text.isNotEmpty) {
        listingData['hips_size'] = _hipsController.text;
      }
      if (_inseamController.text.isNotEmpty) {
        listingData['inseam_size'] = _inseamController.text;
      }
      if (_sleeveController.text.isNotEmpty) {
        listingData['sleeve_size'] = _sleeveController.text;
      }
      if (_shoulderController.text.isNotEmpty) {
        listingData['shoulder_size'] = _shoulderController.text;
      }
      
      print('📤 Creating listing with data: $listingData');
      
      // 3. Submit listing
      final result = await ApiService.createListing(
        token: _authToken!,
        listingData: listingData,
        images: imagePaths,
      );
      
      setState(() => _isSubmitting = false);
      
      print('📥 Listing creation result: $result');
      
      // Check if it's an SMTP error (listing was created but email failed)
      if (result['raw_response'] != null) {
        final rawResponse = result['raw_response'];
        if (rawResponse is Map) {
          final message = rawResponse['message']?.toString() ?? '';
          
          // Check if it's an SMTP authentication error
          if (message.contains('SMTP') || 
              message.contains('authenticate') || 
              message.contains('contact@dexktech.com')) {
            // This means the listing was created but email notification failed
            print('⚠️ Listing created but email notification failed (SMTP issue)');
            _showSnackBar('Listing created successfully! (Email notification failed)', Colors.orange);
            Navigator.pop(context);
            return;
          }
        }
      }
      
      if (result['success'] == true || result['status'] == 'success') {
        _showSnackBar('Listing created successfully!', Colors.green);
        Navigator.pop(context);
      } else {
        String errorMessage = result['message'] ?? 'Failed to create listing';
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          errorMessage += '\nErrors: ${errors.values.join(', ')}';
        }
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      print('❌ Submission error: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }
}
}