// lib/providers/follow_provider.dart

import 'package:flutter/material.dart';

class FollowProvider extends ChangeNotifier {
  Map<String, bool> _followStatus = {};
  Map<String, int> _followersCount = {};
  
  bool isFollowing(String sellerId) {
    return _followStatus[sellerId] ?? false;
  }
  
  int getFollowersCount(String sellerId) {
    return _followersCount[sellerId] ?? 0;
  }
  
  void toggleFollow(String sellerId) {
    final currentStatus = _followStatus[sellerId] ?? false;
    _followStatus[sellerId] = !currentStatus;
    
    // Update followers count
    final currentCount = _followersCount[sellerId] ?? 0;
    _followersCount[sellerId] = currentStatus ? currentCount - 1 : currentCount + 1;
    
    notifyListeners();
  }
  
  void initializeSeller(String sellerId, int initialFollowers, bool isFollowed) {
    if (!_followStatus.containsKey(sellerId)) {
      _followStatus[sellerId] = isFollowed;
      _followersCount[sellerId] = initialFollowers;
    }
  }
}