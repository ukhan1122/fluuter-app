  // lib/screens/received_offers_screen.dart

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:intl/intl.dart';
  import '../../models/offer.dart';
  import '../../models/cart_item.dart';
  import '../../models/product.dart' as model;
  import '../../services/api_service.dart';
  import '../../widgets/product_detail.dart';
  import '../checkout/cart_screen.dart';
  import '../../providers/cart_provider.dart';
  import 'dart:convert';
  import '../../utils/image_utils.dart';

  class ReceivedOffersScreen extends StatefulWidget {
    const ReceivedOffersScreen({super.key});

    @override
    State<ReceivedOffersScreen> createState() => _ReceivedOffersScreenState();
  }

  class _ReceivedOffersScreenState extends State<ReceivedOffersScreen> with SingleTickerProviderStateMixin {
    List<Offer> _offers = [];
    bool _isLoading = true;
    late TabController _tabController;
    int? _currentUserId;
    
    // Filters
    String _selectedFilter = 'all';

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 5, vsync: this);
      _tabController.addListener(_handleTabChange);
      _loadCurrentUser();
      _fetchOffers();
    }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');
    if (userDataJson != null) {
      final Map<String, dynamic> userData = json.decode(userDataJson);
      
      // Try to get ID from various possible locations
      int? userId;
      
      if (userData.containsKey('id')) {
        userId = userData['id'];
      } else if (userData.containsKey('user') && userData['user'] is Map) {
        userId = userData['user']['id'];
      } else if (userData.containsKey('data') && userData['data'] is Map) {
        userId = userData['data']['id'];
      }
      
      // For Openentuser (buyer), we know their ID is 165 from your logs
      // This is a temporary hardcoded fix
      if (userData['username'] == 'Openentuser' && userId == null) {
        userId = 165;
      }
      
      setState(() {
        _currentUserId = userId;
      });
      print('✅ Loaded current user ID: $_currentUserId');
    }
  }

    void _handleTabChange() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0: _selectedFilter = 'all'; break;
            case 1: _selectedFilter = 'pending'; break;
            case 2: _selectedFilter = 'accepted'; break;
            case 3: _selectedFilter = 'rejected'; break;
            case 4: _selectedFilter = 'countered'; break;
          }
        });
      }
    }

    @override
    void dispose() {
      _tabController.dispose();
      super.dispose();
    }

    Future<void> _fetchOffers() async {
      setState(() => _isLoading = true);
      try {
        _offers = await ApiService.getReceivedOffers();
      } catch (e) {
        print('❌ Error fetching offers: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading offers: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    List<Offer> get _filteredOffers {
      if (_selectedFilter == 'all') return _offers;
      return _offers.where((offer) => offer.status == _selectedFilter).toList();
    }

    int _getCountForStatus(String status) {
      if (status == 'all') return _offers.length;
      return _offers.where((offer) => offer.status == status).length;
    }

    void _navigateToConversation(Offer offer) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfferConversationScreen(
            offer: offer,
            currentUserId: _currentUserId,
            onOfferUpdated: _fetchOffers,
          ),
        ),
      );
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
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Received Offers', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.red,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'All (${_getCountForStatus('all')})'),
              Tab(text: 'Pending (${_getCountForStatus('pending')})'),
              Tab(text: 'Accepted (${_getCountForStatus('accepted')})'),
              Tab(text: 'Rejected (${_getCountForStatus('rejected')})'),
              Tab(text: 'Countered (${_getCountForStatus('countered')})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredOffers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchOffers,
                    color: Colors.red,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredOffers.length,
                      itemBuilder: (context, index) {
                        final offer = _filteredOffers[index];
                        return GestureDetector(
                          onTap: () => _navigateToConversation(offer),
                          child: _buildOfferCard(offer),
                        );
                      },
                    ),
                  ),
      );
    }


  Widget _buildOfferCard(Offer offer) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    final bool isMyProduct = _currentUserId == offer.sellerId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isMyProduct 
            ? const BorderSide(color: Colors.red, width: 2)  // Red border for your products
            : BorderSide.none,
      ),
      elevation: 2,
      child: Column(
        children: [
          // Product Info with red header for your products
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMyProduct ? Colors.red.shade50 : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: offer.productImage != null
      ? Image.network(fixImageUrl(offer.productImage!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
      : const Icon(Icons.image),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.productTitle ?? 'Unknown Product',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMyProduct)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'MY PRODUCT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Listed: ${currencyFormat.format(offer.productPrice ?? 0)}',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chat_bubble_outline, size: 16, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          
          // Buyer Info & Amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        offer.getCorrectActor()['name'][0].toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.getCorrectActor()['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            offer.getCorrectActor()['role'] == 'seller' ? 'Seller' : 'Buyer',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(offer.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(offer.status).withOpacity(0.5)),
                      ),
                      child: Text(
                        offer.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(offer.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Offer Amount', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(
                      currencyFormat.format(offer.price),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap to view conversation',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Color _getStatusColor(String status) {
      switch (status) {
        case 'accepted': return Colors.green;
        case 'rejected': return Colors.red;
        case 'countered': return Colors.blue;
        case 'pending': default: return Colors.orange;
      }
    }

    Widget _buildEmptyState() {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 24),
                const Text('No Offers Received', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _selectedFilter == 'all'
                      ? 'When buyers make offers on your products,\nthey will appear here'
                      : 'No ${_selectedFilter} offers at the moment',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ==================== WHATSAPP-STYLE CONVERSATION SCREEN ====================

  class OfferConversationScreen extends StatefulWidget {
    final Offer offer;
    final int? currentUserId;
    final VoidCallback onOfferUpdated;

    const OfferConversationScreen({
      super.key,
      required this.offer,
      required this.currentUserId,
      required this.onOfferUpdated,
    });

    @override
    State<OfferConversationScreen> createState() => _OfferConversationScreenState();
  }

  class _OfferConversationScreenState extends State<OfferConversationScreen> {
    List<Offer> _conversationOffers = [];
    bool _isLoading = false;
    bool _isSending = false;
    
    // For long-press actions
    Offer? _selectedOffer;

    @override
    void initState() {
      super.initState();
      _loadConversation();
    }

    Future<void> _loadConversation() async {
      setState(() => _isLoading = true);
      try {
        final offers = await ApiService.getOfferConversation(
          productId: widget.offer.productId,
          buyerId: widget.offer.buyerId,
          sellerId: widget.offer.sellerId,
        );
        setState(() {
          _conversationOffers = offers;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading conversation: $e');
        setState(() => _isLoading = false);
      }
    }

    Future<void> _handleAcceptOffer(Offer offer) async {
      Navigator.pop(context); // Close dialog
      try {
        final result = await ApiService.acceptOffer(offer.id);
        if (result['success'] == true) {
          widget.onOfferUpdated();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offer accepted successfully'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        _showError('Error accepting offer: $e');
      }
    }

    Future<void> _handleRejectOffer(Offer offer) async {
      Navigator.pop(context); // Close dialog
      try {
        final result = await ApiService.rejectOffer(offer.id);
        if (result['success'] == true) {
          widget.onOfferUpdated();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offer rejected'), backgroundColor: Colors.orange),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        _showError('Error rejecting offer: $e');
      }
    }

  Future<void> _handleBuyNow(Offer offer) async {
    try {

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      final cartItem = CartItem(
        productId: offer.productId,
        sellerId: offer.sellerId,
        title: offer.productTitle ?? 'Product',
        image: offer.productImage ?? '',
        price: 'Rs. ${offer.price.toStringAsFixed(0)}',
        quantity: 1,
      );
      
      cartProvider.addToCart(cartItem);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Navigate to cart screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CartScreen(),
        ),
      );
    } catch (e) {
      _showError('Error adding to cart: $e');
    }
  }

  Future<void> _showCancelConfirmation(Offer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Accepted Offer?'),
        content: Text(
          'Are you sure you want to cancel this accepted offer for ${_formatCurrency(offer.price)}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _handleRejectOffer(offer);
    }
  }


    void _showCounterDialog(Offer offer) {
      Navigator.pop(context); 
      
      final TextEditingController priceController = TextEditingController(text: offer.price.toString());
      final TextEditingController messageController = TextEditingController();
      bool isSending = false;

      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Counter Offer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Your counter price',
                      prefixText: 'Rs. ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: isSending ? null : () async {
                    final price = double.tryParse(priceController.text);
                    if (price == null || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid price'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    setState(() => isSending = true);

                    try {
                      final result = await ApiService.counterOffer(
                        offerId: offer.id,
                        price: price,
                        message: messageController.text.isNotEmpty ? messageController.text : null,
                      );

                      if (result['success'] == true) {
                        widget.onOfferUpdated();
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Counter offer sent'), backgroundColor: Colors.green),
                          );
                          Navigator.pop(context);
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    } finally {
                      if (mounted) setState(() => isSending = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SEND COUNTER'),
                ),
              ],
            );
          },
        ),
      );
    }

    void _showError(String message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }

  void _showActionMenu(Offer offer) {
    final bool isSeller = widget.currentUserId == widget.offer.sellerId;
    final bool isBuyer = widget.currentUserId == widget.offer.buyerId;
    
    final bool canCounter = isSeller;
    
    final bool canAcceptReject = 
        (isSeller && offer.actorId == widget.offer.buyerId) ||
        (isBuyer && offer.actorId == widget.offer.sellerId);
    
    if (offer.status != 'pending') return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              
              if (canAcceptReject) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: const Text('Accept Offer'),
                  subtitle: Text('Accept ${_formatCurrency(offer.price)} offer'),
                  onTap: () => _handleAcceptOffer(offer),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                  title: const Text('Reject Offer'),
                  subtitle: Text('Reject ${_formatCurrency(offer.price)} offer'),
                  onTap: () => _handleRejectOffer(offer),
                ),
              ],
              
              // Counter option ONLY for sellers
              if (canCounter)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.swap_horiz, color: Colors.blue),
                  ),
                  title: const Text('Counter Offer'),
                  subtitle: const Text('Send a counter offer'),
                  onTap: () => _showCounterDialog(offer),
                ),
            ],
          ),
        );
      },
    );
  }

    String _formatCurrency(double price) {
      return 'Rs. ${price.toStringAsFixed(0)}';
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
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              const Text('Conversation', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(widget.offer.productTitle ?? 'Product', style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProductSummary(),
                  
                  Expanded(
                    child: _conversationOffers.isEmpty
                        ? _buildEmptyConversation()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _conversationOffers.length,
                            itemBuilder: (context, index) {
                              final offer = _conversationOffers[index];
                              final isMe = offer.actorId == widget.currentUserId;
                              return _buildMessageBubble(offer, isMe);
                            },
                          ),
                  ),
                  
                  // Bottom Action Buttons
                  _buildBottomActionButtons(),
                ],
              ),
      );
    }

  Widget _buildProductSummary() {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        try {
          // Fetch all products and find the one matching this offer
          final products = await ProductCache.getProducts(limit: 100);
          final product = products.firstWhere(
            (p) => p.id == widget.offer.productId,
            orElse: () => throw Exception('Product not found'),
          );
          
          if (mounted) Navigator.pop(context); 
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen.fromProduct(product: product),
            ),
          );
        } catch (e) {
          if (mounted) Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading product: $e'), backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
              child: widget.offer.productImage != null
    ? Image.network(
        fixImageUrl(widget.offer.productImage!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image),
      )
    : const Icon(Icons.image),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.offer.productTitle ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Listed: ${currencyFormat.format(widget.offer.productPrice ?? 0)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.offer.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _getStatusColor(widget.offer.status).withOpacity(0.5)),
              ),
              child: Text(widget.offer.status.toUpperCase(), style: TextStyle(color: _getStatusColor(widget.offer.status), fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    if (_conversationOffers.isEmpty) return const SizedBox.shrink();
    
    final latestOffer = _conversationOffers.last;
    
    // ============ FOR ACCEPTED OFFERS - SHOW BUY BUTTON ============
    if (latestOffer.status == 'accepted') {
      final bool isSeller = widget.currentUserId == widget.offer.sellerId;
      final bool isBuyer = widget.currentUserId == widget.offer.buyerId;
      
      // Only buyer can buy, only seller can reject/cancel
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Offer Accepted!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Final Price: ${_formatCurrency(latestOffer.price)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (isBuyer)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleBuyNow(latestOffer),
                  icon: const Icon(Icons.shopping_cart, size: 20),
                  label: const Text(
                    'View Cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            if (isSeller)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelConfirmation(latestOffer),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text(
                    'Cancel Accepted Offer',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // ============ FOR PENDING OFFERS - SHOW ACCEPT/REJECT/COUNTER ============
    if (latestOffer.status != 'pending') return const SizedBox.shrink();
    
    final bool isSeller = widget.currentUserId == widget.offer.sellerId;
    final bool isBuyer = widget.currentUserId == widget.offer.buyerId;
    
    final bool shouldTakeAction = 
        (isSeller && latestOffer.actorId == widget.offer.buyerId) ||
        (isBuyer && latestOffer.actorId == widget.offer.sellerId);
    
    final bool canCounter = isSeller;
    
    if (!shouldTakeAction) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Latest Offer', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(_formatCurrency(latestOffer.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _handleRejectOffer(latestOffer), icon: const Icon(Icons.close), label: const Text('Reject'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: () => _handleAcceptOffer(latestOffer), icon: const Icon(Icons.check), label: const Text('Accept'))),
              if (canCounter) ...[
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => _showCounterDialog(latestOffer), icon: const Icon(Icons.swap_horiz), label: const Text('Counter'))),
              ],
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildEmptyConversation() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No conversation history', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    Widget _buildMessageBubble(Offer offer, bool isMe) {
      final bool isSeller = offer.actorId == widget.offer.sellerId;
      final bool isBuyer = offer.actorId == widget.offer.buyerId;
      final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
      
    // Determine the correct actor name using the offer's method
  String actorName = offer.getCorrectActor()['name'];
  String actorRole = offer.getCorrectActor()['role'] == 'seller' ? 'Seller' : 'Buyer';
      
      // Determine if this is a counter offer
      final bool isCounter = offer.parentId != null;
      
      // Check if this message is unread (messages from last 24 hours with pending status)
      final bool isUnread = offer.status == 'pending' && 
          DateTime.now().difference(offer.createdAt).inHours < 24;
      
      // Check if current user can act on this message
      final bool canActOnThis = 
          (widget.currentUserId == widget.offer.sellerId && offer.actorId == widget.offer.buyerId) ||
          (widget.currentUserId == widget.offer.buyerId && offer.actorId == widget.offer.sellerId);
      
      return GestureDetector(
        onLongPress: () {
          if (offer.status == 'pending' && canActOnThis) {
            _showActionMenu(offer);
          }
        },
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 50 : 0,
            right: isMe ? 0 : 50,
            bottom: 16,
          ),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (!isMe) ...[
    // Avatar with profile picture
    Stack(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: _getProfileImage(offer, isSeller, isBuyer),
          backgroundColor: Colors.grey[200],
          child: _getProfileImage(offer, isSeller, isBuyer) == null
              ? Icon(
                  isSeller ? Icons.store_outlined : Icons.person_outline,
                  size: 14,
                  color: isSeller ? Colors.green.shade800 : Colors.orange.shade800,
                )
              : null,
        ),
        if (isUnread)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
    const SizedBox(width: 8),
  ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue.shade500 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                    ),
                    // Add subtle border for interactive messages
                    border: (offer.status == 'pending' && canActOnThis)
                        ? Border.all(
                            color: isMe ? Colors.white : Colors.blue.shade300,
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender name, offer type, and action hint
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actorName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCounter ? Icons.repeat : Icons.add_circle_outline,
                                  size: 10,
                                  color: isMe ? Colors.white70 : Colors.grey[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isCounter ? 'Counter' : 'Initial',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isMe ? Colors.white70 : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Interactive message indicator
                          if (offer.status == 'pending' && canActOnThis)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 10,
                                    color: isMe ? Colors.white70 : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Hold',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isMe ? Colors.white70 : Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      
                      // Price
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        currencyFormat.format(offer.price),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isMe ? Colors.white : Colors.black87,
        ),
      ),
      if (offer.status == 'pending' && canActOnThis && !isMe)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: Colors.blue.shade400,
          ),
        ),
    ],
  ),

  // ✅ ADD THIS NEW SECTION - Show the action description
  const SizedBox(height: 4),
  Text(
    offer.getCorrectLastActionDescription(),
    style: TextStyle(
      fontSize: 11,
      color: isMe ? Colors.white70 : Colors.grey[600],
      fontStyle: FontStyle.italic,
    ),
  ),


                      // Message
                      if (offer.message != null && offer.message!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            offer.message!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isMe ? Colors.white : Colors.grey[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      
                      // Status and Time
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (offer.status != 'pending')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(offer.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                offer.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: _getStatusColor(offer.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (offer.status != 'pending') const SizedBox(width: 8),
                          
                          // Time
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: isMe ? Colors.white54 : Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDate(offer.createdAt),
                            style: TextStyle(
                              fontSize: 9,
                              color: isMe ? Colors.white54 : Colors.grey[500],
                            ),
                          ),
                          
                          // Green dot for unread messages
                          if (isUnread && !isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (isMe) ...[
    const SizedBox(width: 8),
    Stack(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: _getMyProfileImage(offer),
          backgroundColor: Colors.blue.shade100,
          child: _getMyProfileImage(offer) == null
              ? Icon(
                  widget.currentUserId == widget.offer.sellerId ? Icons.store_outlined : Icons.person,
                  size: 14,
                  color: Colors.blue.shade800,
                )
              : null,
        ),
        if (isUnread)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  ],
            ],
          ),
        ),
      );
    }

    Color _getStatusColor(String status) {
      switch (status) {
        case 'accepted': return Colors.green;
        case 'rejected': return Colors.red;
        case 'countered': return Colors.blue;
        case 'pending': default: return Colors.orange;
      }
    }

    String _formatDate(DateTime? date) {
      if (date == null) return '';
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) return DateFormat('MMM d, yyyy').format(date);
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    }

    
    // ==================== PROFILE PICTURE HELPER METHODS ====================
    
    ImageProvider? _getProfileImage(Offer offer, bool isSeller, bool isBuyer) {
      // Check for profile picture from the offer data
      if (isSeller && offer.sellerProfilePic != null && offer.sellerProfilePic!.isNotEmpty) {
  return NetworkImage(fixImageUrl(offer.sellerProfilePic!));
      }
      if (isBuyer && offer.buyerProfilePic != null && offer.buyerProfilePic!.isNotEmpty) {
      
  return NetworkImage(fixImageUrl(offer.buyerProfilePic!));
      }
      if (offer.actorProfilePic != null && offer.actorProfilePic!.isNotEmpty) {
      
  return NetworkImage(fixImageUrl(offer.actorProfilePic!));
      }
      return null;
    }

    ImageProvider? _getMyProfileImage(Offer offer) {
      // If current user is the seller, use seller's profile picture
      if (widget.currentUserId == offer.sellerId) {
        if (offer.sellerProfilePic != null && offer.sellerProfilePic!.isNotEmpty) {
        
  return NetworkImage(fixImageUrl(offer.sellerProfilePic!));
        }
      }
      // If current user is the buyer, use buyer's profile picture
      if (widget.currentUserId == offer.buyerId) {
        if (offer.buyerProfilePic != null && offer.buyerProfilePic!.isNotEmpty) {
        
  return NetworkImage(fixImageUrl(offer.buyerProfilePic!));
        }
      }
      return null;
    }
  }

