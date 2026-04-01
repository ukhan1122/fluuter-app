import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userProfilePicture;
  final String memberSince;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userProfilePicture,
    required this.memberSince,
    required this.onEditProfile,
  });

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
                backgroundImage: _getProfileImage(),
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
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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

  ImageProvider? _getProfileImage() {
    if (userProfilePicture != null && userProfilePicture!.isNotEmpty) {
      return NetworkImage(userProfilePicture!);
    }
    return null;
  }
}