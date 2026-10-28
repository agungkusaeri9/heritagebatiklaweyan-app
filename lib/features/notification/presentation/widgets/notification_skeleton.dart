import 'package:flutter/material.dart';

/// Loading skeleton untuk halaman Notifikasi
class NotificationSkeleton extends StatefulWidget {
  const NotificationSkeleton({super.key});

  @override
  State<NotificationSkeleton> createState() => _NotificationSkeletonState();
}

class _NotificationSkeletonState extends State<NotificationSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildSectionHeaderSkeleton(opacity),
            const SizedBox(height: 12),
            _buildTileSkeleton(opacity),
            const SizedBox(height: 14),
            _buildTileSkeleton(opacity),
            const SizedBox(height: 24),
            _buildSectionHeaderSkeleton(opacity),
            const SizedBox(height: 12),
            _buildTileSkeleton(opacity),
            const SizedBox(height: 14),
            _buildTileSkeleton(opacity),
            const SizedBox(height: 14),
            _buildTileSkeleton(opacity),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeaderSkeleton(double opacity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildTileSkeleton(double opacity) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9).withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9).withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
