import 'package:flutter/material.dart';

class StatsCards extends StatelessWidget {
  final int totalItems;
  final double totalEarnings;
  final int totalFollowers;
  final int totalFollowing;
  final VoidCallback onViewOffers;

  const StatsCards({
    super.key,
    required this.totalItems,
    required this.totalEarnings,
    required this.totalFollowers,
    required this.totalFollowing,
    required this.onViewOffers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.inventory_2_outlined,
                value: totalItems.toString(),
                label: 'Total Items',
                color: Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                icon: Icons.attach_money,
                value: 'PKR ${totalEarnings.toStringAsFixed(0)}',
                label: 'Earnings',
                color: Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.people_outline,
                value: totalFollowers.toString(),
                label: 'Followers',
                color: Colors.purple,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                icon: Icons.person_add_outlined,
                value: totalFollowing.toString(),
                label: 'Following',
                color: Colors.orange,
              )),
            ],
          ),
          const SizedBox(height: 16),
          _buildOffersButton(),
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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOffersButton() {
    return GestureDetector(
      onTap: onViewOffers,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_offer, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Received Offers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('View and manage offers on your items',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}