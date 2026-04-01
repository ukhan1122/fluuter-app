// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';  // ← Fix this path
import '../../screens/received_offers_screen.dart';  // ← Fix this path
import '../create_listing_screen.dart';
import 'providers/profile_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_cards.dart';
import 'widgets/product_card.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/edit_product_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUserData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: ProfileHeader(
                  userName: provider.userName,
                  userEmail: provider.userEmail,
                  userProfilePicture: provider.userProfilePicture,
                  memberSince: provider.memberSince,
                  onEditProfile: () => _showEditProfileDialog(provider),
                )),
                SliverToBoxAdapter(child: StatsCards(
                  totalItems: provider.sellingItems.length + provider.soldItems.length,
                  totalEarnings: provider.totalEarnings,
                  totalFollowers: provider.totalFollowers,
                  totalFollowing: provider.totalFollowing,
                  onViewOffers: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const ReceivedOffersScreen())
                  ),
                )),
                SliverToBoxAdapter(child: _buildTabBar(provider)),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _tabController.index == 0
                      ? _buildProductList(provider.sellingItems, false, provider)
                      : _buildProductList(provider.soldItems, true, provider),
                ),
              ],
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
                ? NetworkImage(provider.userProfilePicture!) 
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

  Widget _buildTabBar(ProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100], 
        borderRadius: BorderRadius.circular(30)
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30), 
          color: Colors.red
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
                Text('Selling (${provider.sellingItems.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 6),
                Text('Sold (${provider.soldItems.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> items, bool isSold, ProfileProvider provider) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                isSold ? 'No sold items yet' : 'No items for sale',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(
                isSold ? 'Your sold items will appear here' : 'Start selling by creating your first listing',
                style: TextStyle(color: Colors.grey[600])
              ),
              const SizedBox(height: 24),
              if (!isSold)
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const CreateListingScreen())
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Create Listing'),
                ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ProductCard(
          product: items[index],
          isSold: isSold,
          onEdit: () => _showEditProductDialog(items[index], provider),
          onDelete: () => _confirmDeleteProduct(items[index], provider),
        ),
        childCount: items.length,
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
        authToken: provider.authToken,
        onProfileUpdated: () => provider.loadUserData(),
      ),
    );
  }

  void _confirmDeleteProduct(Product product, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CANCEL')
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product product, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProductDialog(
        product: product,
        onProductUpdated: () => provider.loadUserData(),
      ),
    );
  }
}