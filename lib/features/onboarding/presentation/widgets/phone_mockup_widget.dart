import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/onboarding_item.dart';

/// Mockup smartphone yang menampilkan antarmuka aplikasi fashion shopping
class PhoneMockupWidget extends StatelessWidget {
  final OnboardingMockupType type;

  const PhoneMockupWidget({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF2A2E35),
            width: 7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Mockup Status Bar & Dynamic Island Notch
                _buildMockupStatusBar(),

                // Mockup Screen Content based on type
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: _buildScreenContent(),
                  ),
                ),

                // Mockup Home Indicator Bar
                _buildMockupHomeIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupStatusBar() {
    return Container(
      padding: const EdgeInsets.only(top: 6, left: 14, right: 14, bottom: 4),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '09:41',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          // Dynamic Island Capsule
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Row(
            children: const [
              Icon(Icons.wifi, size: 10, color: Color(0xFF1E293B)),
              SizedBox(width: 3),
              Icon(Icons.battery_full, size: 10, color: Color(0xFF1E293B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockupHomeIndicator() {
    return Container(
      height: 14,
      alignment: Alignment.center,
      color: Colors.white,
      child: Container(
        width: 60,
        height: 3,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildScreenContent() {
    switch (type) {
      case OnboardingMockupType.shopping:
        return _buildShoppingScreen();
      case OnboardingMockupType.wishlist:
        return _buildWishlistScreen();
      case OnboardingMockupType.orderTracking:
        return _buildOrderTrackingScreen();
    }
  }

  // ==========================================
  // 1. SHOPPING EXPERIENCE MOCKUP
  // ==========================================
  Widget _buildShoppingScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ARBatika',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF704F38),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Solo, Jawa Tengah',
                  style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 13, color: Color(0xFF704F38)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Search Bar Mockup
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.search, size: 12, color: Color(0xFF94A3B8)),
              SizedBox(width: 4),
              Text(
                'Search motif batik...',
                style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Promo Banner
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF704F38), Color(0xFF8D674B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW ARRIVAL',
                        style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Batik Tulis Sogan 40% OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.checkroom, color: Colors.white70, size: 24),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All', true),
              _buildCategoryChip('Batik Tulis', false),
              _buildCategoryChip('Batik Cap', false),
              _buildCategoryChip('Kemeja', false),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 2 Product Grid Cards
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildProductCard('Kemeja Sogan', 'Rp 289K', Icons.male)),
              const SizedBox(width: 6),
              Expanded(child: _buildProductCard('Dress Kawung', 'Rp 450K', Icons.female)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF704F38) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF704F38) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildProductCard(String title, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFF704F38), size: 28),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF704F38),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. WISHLIST MOCKUP
  // ==========================================
  Widget _buildWishlistScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '3 items',
              style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Wishlist Items List
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildWishlistItem(
                title: 'Batik Parang Tulis',
                category: 'Kemeja Formal',
                price: 'Rp 450.000',
                icon: Icons.dry_cleaning_rounded,
              ),
              _buildWishlistItem(
                title: 'Dress Kawung Ayu',
                category: 'Batik Sutra Wanita',
                price: 'Rp 620.000',
                icon: Icons.checkroom,
              ),
              _buildWishlistItem(
                title: 'Selendang Sogan Solo',
                category: 'Aksesoris Tradisional',
                price: 'Rp 195.000',
                icon: Icons.style,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistItem({
    required String title,
    required String category,
    required String price,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: const Color(0xFF704F38), size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 7, color: Color(0xFF94A3B8)),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF704F38),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, size: 12, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. ORDER TRACKING MOCKUP
  // ==========================================
  Widget _buildOrderTrackingScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Order Tracking',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '#HB-8921',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF704F38),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Delivery Status Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping,
                    size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Out for Delivery',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Estimated: Today, 15:30',
                      style: TextStyle(fontSize: 7, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Live Route Visual Box
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 16,
                right: 16,
                child: Container(
                  height: 2,
                  color: const Color(0xFF93C5FD),
                ),
              ),
              Positioned(
                left: 18,
                child: _buildPin(Icons.store, const Color(0xFF64748B)),
              ),
              Center(
                child: _buildPin(Icons.delivery_dining, const Color(0xFF704F38)),
              ),
              Positioned(
                right: 18,
                child: _buildPin(Icons.home, const Color(0xFF10B981)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Timeline Tracking Steps
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTimelineStep('Order Confirmed', '10:30 WIB', true),
              _buildTimelineStep('Shipped from Solo Workshop', '14:20 WIB', true),
              _buildTimelineStep('Package In Transit', 'On Process', true),
              _buildTimelineStep('Delivered to Doorstep', 'Waiting', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPin(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  Widget _buildTimelineStep(String label, String time, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 11,
            color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 7, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
