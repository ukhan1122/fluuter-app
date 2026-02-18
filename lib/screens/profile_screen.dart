// lib/screens/profile_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/create_listing_screen.dart';
import '../widgets/product_detail.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> sellingItems = [];
  List<Product> soldItems = [];
  bool _isLoading = true;
  
  // User data - ALL FROM API
  String userName = '';
  String userEmail = '';
  String? userProfilePicture;
  String? authToken;
  String memberSince = '';
  double totalEarnings = 0.0;
  int totalFollowers = 0;
  int totalFollowing = 0;
  
  // For edit profile
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    
    // Add debug call here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugFollowersAPI();
    });
    
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
// Load from SharedPreferences cache
Future<void> _loadFromCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');
    
    if (userDataJson != null) {
      final userData = json.decode(userDataJson);
      
      // Check if we have an ID now
      if (userData.containsKey('id')) {
        print('✅ Found user ID in cache: ${userData['id']}');
        // If we have ID, we can fetch fresh stats
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchUserStatsWithId(userData['id'].toString());
        });
      }
      
      setState(() {
        final firstName = userData['first_name']?.toString() ?? '';
        final lastName = userData['last_name']?.toString() ?? '';
        final email = userData['email']?.toString() ?? '';
        final profilePicture = userData['profile_picture']?.toString();
        final createdAt = userData['created_at']?.toString() ?? '';
        final username = userData['username']?.toString() ?? '';
        
        // Get follower counts if they exist in cache
        totalFollowers = userData['followers_count'] ?? 0;
        totalFollowing = userData['following_count'] ?? 0;
        
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          userName = '$firstName $lastName';
        } else if (firstName.isNotEmpty) {
          userName = firstName;
        } else if (lastName.isNotEmpty) {
          userName = lastName;
        } else if (username.isNotEmpty) {
          userName = username;
        } else {
          userName = 'User';
        }
        
        userEmail = email.isNotEmpty ? email : 'No email';
        userProfilePicture = profilePicture;
        
        if (createdAt.isNotEmpty) {
          try {
            final date = DateTime.parse(createdAt);
            memberSince = DateFormat('MMM yyyy').format(date);
          } catch (e) {
            if (createdAt.length >= 4) {
              memberSince = createdAt.substring(0, 4);
            }
          }
        }
      });
      print('✅ Loaded profile from cache');
    }
  } catch (e) {
    print('❌ Error loading from cache: $e');
  }
}

  // Main method to load all user data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
      
      if (authToken != null && authToken!.isNotEmpty) {
        // First load from cache for immediate display
        await _loadFromCache();
        
        // Then try to get fresh data from API
        await _refreshUserProfile();
        
        // Fetch products
        await _fetchUserProducts();
        
        // Fetch follower stats using the working method
        await _fetchUserStats();
      } else {
        setState(() {
          userName = 'Guest';
          userEmail = 'Please login';
        });
      }
    } catch (e) {
      print('❌ Error in _loadUserData: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch fresh profile data from API
  Future<void> _refreshUserProfile() async {
    if (authToken == null || authToken!.isEmpty) return;
    
    try {
      print('🔄 Refreshing user profile from API');
      
      // Try to get user profile from the auth endpoint first
      String authUrl = '${ApiService.baseUrl}/api/v1/auth/user';
      print('🌐 Trying auth endpoint: $authUrl');
      
      final authResponse = await http.get(
        Uri.parse(authUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          'ngrok-skip-browser-warning': 'true',
          'Host': 'depop-backend.test',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Auth Response Status: ${authResponse.statusCode}');
      
      if (authResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(authResponse.body);
        final userData = responseData['data'] ?? responseData;
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(userData));
        
        // Update UI
        setState(() {
          _updateUserDataFromJson(userData);
        });
        
        print('✅ Profile refreshed from auth endpoint');
        return;
      }
      
      // If auth endpoint fails, try to get profile using seller API with user ID
      print('⚠️ Auth endpoint failed, trying seller profile API...');
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        print('📄 User data keys: ${userData.keys}');
        
        // Try to find ID in different possible locations
        String? userId;
        
        if (userData.containsKey('id')) {
          userId = userData['id']?.toString();
        } else if (userData.containsKey('user_id')) {
          userId = userData['user_id']?.toString();
        } else if (userData.containsKey('userId')) {
          userId = userData['userId']?.toString();
        }
        
        if (userId != null && userId.isNotEmpty) {
          print('📡 Fetching own profile using seller API for ID: $userId');
          final profileResult = await ApiService.getSellerProfile(userId);
          
          if (profileResult['success'] == true) {
            final profileData = profileResult['data'];
            
            // Update cached user data with all fields including follower counts
            userData['followers_count'] = profileData['followers_count'] ?? 0;
            userData['following_count'] = profileData['following_count'] ?? 0;
            userData['products_count'] = profileData['products_count'] ?? 0;
            
            await prefs.setString('user_data', json.encode(userData));
            
            setState(() {
              _updateUserDataFromJson(userData);
            });
            
            print('✅ Profile refreshed from seller API');
            return;
          }
        } else {
          print('❌ No user ID found in cached data');
        }
      }
      
      // Final fallback to cached data
      print('⚠️ Using cached profile data');
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        setState(() {
          _updateUserDataFromJson(userData);
        });
        print('✅ Using cached profile data');
      }
      
    } catch (e) {
      print('❌ Error refreshing profile: $e');
      
      // Fallback to cached data
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        setState(() {
          _updateUserDataFromJson(userData);
        });
      }
    }
  }

  // Helper method to update UI from JSON data
  void _updateUserDataFromJson(Map<String, dynamic> userData) {
    final firstName = userData['first_name']?.toString() ?? '';
    final lastName = userData['last_name']?.toString() ?? '';
    final email = userData['email']?.toString() ?? '';
    final profilePicture = userData['profile_picture']?.toString();
    final createdAt = userData['created_at']?.toString() ?? '';
    final username = userData['username']?.toString() ?? '';
    
    // Update follower counts - these should now come from the seller API
    totalFollowers = userData['followers_count'] ?? 0;
    totalFollowing = userData['following_count'] ?? 0;
    
    print('📊 Updated follower counts - Followers: $totalFollowers, Following: $totalFollowing');
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      userName = '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      userName = firstName;
    } else if (lastName.isNotEmpty) {
      userName = lastName;
    } else if (username.isNotEmpty) {
      userName = username;
    }
    
    userEmail = email.isNotEmpty ? email : 'No email';
    userProfilePicture = profilePicture;
    
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        memberSince = DateFormat('MMM yyyy').format(date);
      } catch (e) {
        if (createdAt.length >= 4) {
          memberSince = createdAt.substring(0, 4);
        }
      }
    }
  }
  
  // Alternative method to get user data
  Future<void> _refreshUserProfileAlternative() async {
    try {
      print('🔄 Trying alternative profile endpoint...');
      
      // Try user endpoint
      String altEndpoint = '${ApiService.baseUrl}/api/v1/user';
      print('🌐 Alternative endpoint: $altEndpoint');
      
      final response = await http.get(
        Uri.parse(altEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          'ngrok-skip-browser-warning': 'true',
          'Host': 'depop-backend.test',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Alternative Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final userData = responseData['data'] ?? responseData;
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(userData));
        
        // Update UI
        setState(() {
          final firstName = userData['first_name']?.toString() ?? '';
          final lastName = userData['last_name']?.toString() ?? '';
          final email = userData['email']?.toString() ?? '';
          final profilePicture = userData['profile_picture']?.toString();
          final createdAt = userData['created_at']?.toString() ?? '';
          
          // Update follower counts
          totalFollowers = userData['followers_count'] ?? 0;
          totalFollowing = userData['following_count'] ?? 0;
          
          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            userName = '$firstName $lastName';
          } else if (firstName.isNotEmpty) {
            userName = firstName;
          } else {
            userName = userData['username'] ?? 'User';
          }
          
          userEmail = email;
          userProfilePicture = profilePicture;
          
          if (createdAt.isNotEmpty) {
            memberSince = createdAt.length >= 4 ? createdAt.substring(0, 4) : '';
          }
        });
        
        print('✅ Profile refreshed from alternative endpoint');
      } else {
        // Fallback to SharedPreferences
        print('⚠️ Using cached profile data');
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = prefs.getString('user_data');
        if (userDataJson != null) {
          final userData = json.decode(userDataJson);
          setState(() {
            final firstName = userData['first_name']?.toString() ?? '';
            final lastName = userData['last_name']?.toString() ?? '';
            final email = userData['email']?.toString() ?? '';
            final profilePicture = userData['profile_picture']?.toString();
            final createdAt = userData['created_at']?.toString() ?? '';
            
            // Update follower counts
            totalFollowers = userData['followers_count'] ?? 0;
            totalFollowing = userData['following_count'] ?? 0;
            
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              userName = '$firstName $lastName';
            } else if (firstName.isNotEmpty) {
              userName = firstName;
            } else {
              userName = userData['username'] ?? 'User';
            }
            
            userEmail = email;
            userProfilePicture = profilePicture;
            
            if (createdAt.isNotEmpty) {
              memberSince = createdAt.length >= 4 ? createdAt.substring(0, 4) : '';
            }
          });
        }
      }
    } catch (e) {
      print('❌ All profile refresh attempts failed: $e');
    }
  }

 // Fetch user products from API
Future<void> _fetchUserProducts() async {
  if (authToken == null || authToken!.isEmpty) return;
  
  try {
    final allProducts = await ApiService.getUserProducts(authToken!);
    
    if (allProducts.isNotEmpty) {
      final activeProducts = allProducts.where((product) {
        return product.sold == false && product.active == true;
      }).toList();
      
      final soldProducts = allProducts.where((product) {
        return product.sold == true || product.active == false;
      }).toList();
      
      // Calculate total earnings from sold items
      totalEarnings = soldProducts.fold(0.0, (sum, product) => sum + product.price);
      
      setState(() {
        sellingItems = activeProducts;
        soldItems = soldProducts;
      });
      
      // 👇 ADD THIS LINE to extract and save user ID
      await _extractUserIdFromProducts();
      
    }
  } catch (e) {
    print('❌ Error fetching products: $e');
  }
}


// Get user ID from products and save it
Future<void> _extractUserIdFromProducts() async {
  try {
    if (sellingItems.isNotEmpty) {
      final userId = sellingItems.first.userId?.toString();
      if (userId != null && userId.isNotEmpty) {
        print('✅ Found user ID from selling products: $userId');
        await _saveUserIdToPrefs(userId);
      }
    } else if (soldItems.isNotEmpty) {
      final userId = soldItems.first.userId?.toString();
      if (userId != null && userId.isNotEmpty) {
        print('✅ Found user ID from sold products: $userId');
        await _saveUserIdToPrefs(userId);
      }
    } else {
      print('⚠️ No products found to extract user ID');
    }
  } catch (e) {
    print('❌ Error extracting user ID: $e');
  }
}

// Save user ID to SharedPreferences
Future<void> _saveUserIdToPrefs(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');
    
    if (userDataJson != null) {
      final userData = json.decode(userDataJson);
      userData['id'] = int.parse(userId);
      await prefs.setString('user_data', json.encode(userData));
      print('✅ Saved user ID $userId to SharedPreferences');
      
      // Also update the current userData in memory
      setState(() {
        // You can now fetch stats with the ID
        _fetchUserStatsWithId(userId);
      });
    }
  } catch (e) {
    print('❌ Error saving user ID: $e');
  }
}

// Fetch stats with known user ID
Future<void> _fetchUserStatsWithId(String userId) async {
  try {
    print('📡 Fetching profile for user ID: $userId');
    final profileResult = await ApiService.getSellerProfile(userId);
    
    if (profileResult['success'] == true) {
      final profileData = profileResult['data'];
      
      setState(() {
        totalFollowers = profileData['followers_count'] ?? 0;
        totalFollowing = profileData['following_count'] ?? 0;
      });
      
      print('✅ Got follower counts - Followers: $totalFollowers, Following: $totalFollowing');
    }
  } catch (e) {
    print('❌ Error fetching stats with ID: $e');
  }
}

  // Fetch follower stats from API
  Future<void> _fetchUserStats() async {
    if (authToken == null || authToken!.isEmpty) return;
    
    try {
      print('📊 Fetching user stats');
      
      // Get your user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      
      if (userDataJson == null) {
        print('❌ No user data found');
        return;
      }
      
      final userData = json.decode(userDataJson);
      print('📄 Your user data keys: ${userData.keys}');
      
      // YOUR user ID should be in the user data from login
      String? yourUserId;
      
      if (userData.containsKey('id')) {
        yourUserId = userData['id']?.toString();
        print('✅ Found YOUR user ID: $yourUserId');
      } else {
        print('❌ YOUR user ID not found in user data');
        print('📄 Available keys: ${userData.keys}');
        
        // If ID not found, maybe it's nested? Check the structure
        if (userData.containsKey('user') && userData['user'] is Map) {
          final nestedUser = userData['user'];
          yourUserId = nestedUser['id']?.toString();
          print('✅ Found YOUR user ID in nested user: $yourUserId');
        }
      }
      
      if (yourUserId == null) {
        print('❌ Cannot fetch stats without YOUR user ID');
        setState(() {
          totalFollowers = 0;
          totalFollowing = 0;
        });
        return;
      }
      
      // Fetch YOUR profile using the seller API with YOUR user ID
      print('📡 Fetching YOUR profile for YOUR user ID: $yourUserId');
      final profileResult = await ApiService.getSellerProfile(yourUserId);
      
      if (profileResult['success'] == true) {
        final profileData = profileResult['data'];
        
        // Extract YOUR follower counts
        final followers = profileData['followers_count'] ?? 0;
        final following = profileData['following_count'] ?? 0;
        
        print('✅ Got YOUR follower counts - Followers: $followers, Following: $following');
        
        // Update UI
        setState(() {
          totalFollowers = followers;
          totalFollowing = following;
        });
        
        // Update cached user data with follower counts
        userData['followers_count'] = followers;
        userData['following_count'] = following;
        await prefs.setString('user_data', json.encode(userData));
        
        return;
      } else {
        print('❌ Failed to fetch YOUR profile: ${profileResult['error']}');
      }
      
      // Fallback to follower lists
      try {
        final followers = await ApiService.getMyFollowers();
        final following = await ApiService.getMyFollowing();
        
        setState(() {
          totalFollowers = followers.length;
          totalFollowing = following.length;
        });
        
        print('✅ Stats from lists - Followers: $totalFollowers, Following: $totalFollowing');
      } catch (e) {
        print('❌ Error fetching follower lists: $e');
        setState(() {
          totalFollowers = 0;
          totalFollowing = 0;
        });
      }
      
    } catch (e) {
      print('❌ Error in _fetchUserStats: $e');
      setState(() {
        totalFollowers = 0;
        totalFollowing = 0;
      });
    }
  }

  Future<void> _debugFollowersAPI() async {
    try {
      print('🔍 TESTING Followers API:');
      final followers = await ApiService.getMyFollowers();
      print('📊 Followers response: $followers');
      print('📊 Followers count: ${followers.length}');
      
      print('🔍 TESTING Following API:');
      final following = await ApiService.getMyFollowing();
      print('📊 Following response: $following');
      print('📊 Following count: ${following.length}');
      
      // Also try the stats endpoint
      print('🔍 TESTING Stats API:');
      final stats = await ApiService.getUserStats();
      print('📊 Stats response: $stats');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  // Update user data in SharedPreferences after follow/unfollow
  Future<void> _updateUserDataAfterFollow() async {
    try {
      // Just call _fetchUserStats to refresh the counts
      await _fetchUserStats();
    } catch (e) {
      print('❌ Error updating user data after follow: $e');
    }
  }

  // Show edit profile bottom sheet
  Future<void> _showEditProfileDialog() {
    _nameController.text = userName;
    _emailController.text = userEmail;
    _selectedImage = null;
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                    'Edit Profile',
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
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _getProfileImage(),
                              child: _selectedImage == null && 
                                     (userProfilePicture == null || userProfilePicture!.isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
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
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.red[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.red[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
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
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (userProfilePicture != null && userProfilePicture!.isNotEmpty) {
      if (userProfilePicture!.startsWith('http')) {
        return NetworkImage(userProfilePicture!);
      } else {
        return FileImage(File(userProfilePicture!));
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  // Update profile via API
  Future<void> _updateProfile() async {
    if (authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> nameParts = _nameController.text.trim().split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      Map<String, dynamic> updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailController.text.trim(),
      };

      print('📤 Updating profile with data: $updateData');
      
      String endpoint = '${ApiService.baseUrl}/api/v1/user/preferences';
      print('🌐 Endpoint: $endpoint');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'ngrok-skip-browser-warning': 'true',
          'Host': 'depop-backend.test',
        },
        body: json.encode(updateData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Update Profile Status: ${response.statusCode}');
      print('📡 Update Profile Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local data immediately
        setState(() {
          userName = _nameController.text;
          userEmail = _emailController.text;
        });
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = prefs.getString('user_data');
        if (userDataJson != null) {
          Map<String, dynamic> userData = json.decode(userDataJson);
          userData['first_name'] = firstName;
          userData['last_name'] = lastName;
          userData['email'] = _emailController.text.trim();
          await prefs.setString('user_data', json.encode(userData));
        }
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMsg = 'Update failed';
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['message'] ?? errorData['error'] ?? 'Update failed';
        } catch (_) {}
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Update error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          ),
          child: Image.asset('assets/logo.png', height: 35),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade100, width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: _getProfileImage(),
              child: userProfilePicture == null || userProfilePicture!.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: Colors.red,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildProfileHeader()),
                  SliverToBoxAdapter(child: _buildStatsCards()),
                  SliverToBoxAdapter(child: _buildTabBar()),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _tabController.index == 0
                        ? _buildSellingItemsSliver()
                        : _buildSoldItemsSliver(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 3),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _getProfileImage(),
                  child: userProfilePicture == null || userProfilePicture!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.red.shade300,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              userEmail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),

          const SizedBox(height: 12),
          if (memberSince.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_today, size: 12, color: Colors.red.shade400),
                ),
                const SizedBox(width: 6),
                Text(
                  'Member since $memberSince',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalItems = sellingItems.length + soldItems.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.inventory_2_outlined,
                  value: totalItems.toString(),
                  label: 'Total Items',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  value: 'PKR ${totalEarnings.toStringAsFixed(0)}',
                  label: 'Earnings',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_outline,
                  value: totalFollowers.toString(),
                  label: 'Followers',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.person_add_outlined,
                  value: totalFollowing.toString(),
                  label: 'Following',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.red,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Selling (${sellingItems.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 6),
                Text('Sold (${soldItems.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellingItemsSliver() {
    if (sellingItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(
          icon: Icons.storefront_outlined,
          title: 'No items for sale',
          message: 'Start selling by creating your first listing',
          actionText: 'Create Listing',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateListingScreen()),
            );
          },
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = sellingItems[index];
          return _buildProductCard(product, isSold: false);
        },
        childCount: sellingItems.length,
      ),
    );
  }

  Widget _buildSoldItemsSliver() {
    if (soldItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(
          icon: Icons.check_circle_outline,
          title: 'No sold items yet',
          message: 'Your sold items will appear here',
          actionText: 'Browse Items',
          onAction: () {
            Navigator.pop(context);
          },
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = soldItems[index];
          return _buildProductCard(product, isSold: true);
        },
        childCount: soldItems.length,
      ),
    );
  }

  Widget _buildProductCard(Product product, {required bool isSold}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen.fromProduct(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: Container(
                    width: 120,
                    height: 140,
                    color: Colors.grey[100],
                    child: product.photoUrls.isNotEmpty
                        ? Image.network(
                            product.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSold ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSold ? 'SOLD' : 'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSold ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PKR ${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSold ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (product.categoryName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.categoryName!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (product.conditionTitle != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.conditionTitle!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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