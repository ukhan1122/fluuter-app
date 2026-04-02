import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userProfilePicture;
  final String shopDescription;
  final String memberSince;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userProfilePicture,
    required this.shopDescription,
    required this.memberSince,
    required this.onEditProfile,
  });

  String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // Extract just the filename from the URL
    String filename = url.split('/').last;
    // Use the direct storage URL
    return 'http://10.0.2.2/storage/profile_pictures/$filename';
  }

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[100],
                backgroundImage: userProfilePicture != null && userProfilePicture!.isNotEmpty
                    ? NetworkImage(_fixImageUrl(userProfilePicture))
                    : null,
                child: userProfilePicture == null
                    ? Icon(Icons.person, size: 50, color: Colors.red.shade300)
                    : null,
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: onEditProfile,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Shop Description Card (replaces email)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.store_outlined, color: Colors.red[400], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Description',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shopDescription.isEmpty ? 'No shop description yet' : shopDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: shopDescription.isEmpty ? Colors.grey[400] : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (memberSince.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Text('Member since $memberSince',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}