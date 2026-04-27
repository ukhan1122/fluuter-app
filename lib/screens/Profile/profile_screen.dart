// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_splash_app/models/product.dart';
import '../product/create_listing_screen.dart';
import 'providers/profile_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/edit_profile_dialog.dart';
import '../../utils/image_utils.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(provider),
          body: RefreshIndicator(
            onRefresh: () => provider.loadUserData(),
            color: Colors.red,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  ProfileHeader(
                    userName: provider.userName,
                    userEmail: provider.userEmail,
                    userProfilePicture: provider.userProfilePicture,
                    shopDescription: provider.shopDescription,
                    memberSince: provider.memberSince,
                    onEditProfile: () => _showEditProfileDialog(provider),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activity
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (provider.sellingItems.isEmpty && provider.soldItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ...provider.sellingItems.take(3).map((product) => _buildRecentItem(product, isSold: false)),
                    ...provider.soldItems.take(2).map((product) => _buildRecentItem(product, isSold: true)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(ProfileProvider provider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Image.asset('assets/logo.png', height: 35),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            border: Border.all(color: Colors.red.shade100, width: 2)
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: provider.userProfilePicture != null 
                ? NetworkImage(fixImageUrl(provider.userProfilePicture!))
                : null,
            child: provider.userProfilePicture == null
                ? Text(
                    provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(Product product, {required bool isSold}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 55,
              height: 55,
              color: Colors.grey[200],
              child: product.photoUrls.isNotEmpty
                  ? Image.network(
                      fixImageUrl(product.photoUrls.first),
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey[400], size: 30),
                    )
                  : Icon(Icons.image, color: Colors.grey[400], size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSold ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSold ? 'Sold' : 'Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSold ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'PKR ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileDialog(
        userName: provider.userName,
        userEmail: provider.userEmail,
        userProfilePicture: provider.userProfilePicture,
        shopDescription: provider.shopDescription,
        authToken: provider.authToken,
        onProfileUpdated: () => provider.loadUserData(),
      ),
    );
  }
}