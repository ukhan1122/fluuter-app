import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../services/api_service.dart';
import '../../../config.dart';

class EditProfileDialog extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userProfilePicture;
  final String? shopDescription;
  final String? authToken;
  final VoidCallback onProfileUpdated;

  const EditProfileDialog({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userProfilePicture,
    this.shopDescription,
    required this.authToken,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final TextEditingController _shopDescriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _shopDescriptionController.text = widget.shopDescription ?? '';
  }

  @override
  void dispose() {
    _shopDescriptionController.dispose();
    super.dispose();
  }

  String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // Extract just the filename from the URL
    String filename = url.split('/').last;
    // Use the direct storage URL
    return 'http://10.0.2.2/storage/profile_pictures/$filename';
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/v1/users/profile/picture'),
      );
      
      request.headers.addAll(AppConfig.getHeaders(token: widget.authToken));
      
      var multipartFile = await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      
      print('📤 Upload Profile Picture Status: ${response.statusCode}');
      print('📤 Response: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(responseBody);
        
        // Update SharedPreferences with new profile picture URL
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = prefs.getString('user_data');
        if (userDataJson != null) {
          Map<String, dynamic> userData = json.decode(userDataJson);
          
          // Get the image URL from response
          String imageUrl = responseData['data']['profile_picture'] ?? 
                           responseData['profile_picture'] ?? 
                           responseData['url'];
          
          if (imageUrl != null) {
            // Fix the URL for emulator
            String fixedUrl = _fixImageUrl(imageUrl);
            userData['profile_picture'] = fixedUrl;
            await prefs.setString('user_data', json.encode(userData));
          }
        }
      } else {
        throw Exception('Failed to upload image (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Image upload error: $e');
      rethrow;
    }
  }

  Future<void> _updateShopDescription() async {
    if (widget.authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // First upload image if selected
      if (_selectedImage != null) {
        await _uploadProfileImage(_selectedImage!);
      }

      // Update shop description using the specific endpoint
      Map<String, dynamic> updateData = {
        'description': _shopDescriptionController.text.trim(),
      };

      print('📤 Updating shop description: ${updateData['description']}');
      
      String endpoint = '${ApiService.baseUrl}/api/v1/shop/auth/update-description';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: AppConfig.getHeaders(token: widget.authToken),
        body: json.encode(updateData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Update Shop Description Status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = prefs.getString('user_data');
        if (userDataJson != null) {
          Map<String, dynamic> userData = json.decode(userDataJson);
          userData['shop_description'] = _shopDescriptionController.text.trim();
          await prefs.setString('user_data', json.encode(userData));
        }
        
        if (mounted) {
          Navigator.pop(context);
          widget.onProfileUpdated();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // If the specific endpoint fails, try the preferences endpoint
        print('Trying preferences endpoint...');
        endpoint = '${ApiService.baseUrl}/api/v1/user/preferences';
        updateData = {
          'shop_description': _shopDescriptionController.text.trim(),
        };
        
        final response2 = await http.post(
          Uri.parse(endpoint),
          headers: AppConfig.getHeaders(token: widget.authToken),
          body: json.encode(updateData),
        ).timeout(const Duration(seconds: 15));
        
        if (response2.statusCode == 200 || response2.statusCode == 201) {
          final prefs = await SharedPreferences.getInstance();
          final userDataJson = prefs.getString('user_data');
          if (userDataJson != null) {
            Map<String, dynamic> userData = json.decode(userDataJson);
            userData['shop_description'] = _shopDescriptionController.text.trim();
            await prefs.setString('user_data', json.encode(userData));
          }
          
          if (mounted) {
            Navigator.pop(context);
            widget.onProfileUpdated();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Failed to update shop description');
        }
      }
    } catch (e) {
      print('❌ Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (widget.userProfilePicture != null && widget.userProfilePicture!.isNotEmpty) {
      String fixedUrl = _fixImageUrl(widget.userProfilePicture);
      return NetworkImage(fixedUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Edit Shop Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: _getProfileImage(),
                          child: _selectedImage == null && 
                                 (widget.userProfilePicture == null || widget.userProfilePicture!.isEmpty)
                              ? Icon(
                                  Icons.store,
                                  size: 50,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextFormField(
                      controller: _shopDescriptionController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Shop Description',
                        hintText: 'Describe your shop, products, services, etc...',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.store_outlined, color: Colors.red[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _updateShopDescription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}