import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_dummy_data.dart';

/// Reusable Widget: CategorySection
/// Menampilkan deretan kategori batik dari backend dengan scroll horizontal
class CategorySection extends StatelessWidget {
  final List<ProductCategoryItem> categories;
  final String selectedCategoryId;
  final ValueChanged<ProductCategoryItem>? onCategorySelected;
  final VoidCallback? onSeeAllTap;

  const CategorySection({
    super.key,
    this.categories = HomeDummyData.categories,
    this.selectedCategoryId = 'all',
    this.onCategorySelected,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Judul Category
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              InkWell(
                onTap: onSeeAllTap ??
                    () {
                      if (categories.isNotEmpty && onCategorySelected != null) {
                        final allCategory = categories.firstWhere(
                          (c) => c.id == 'all',
                          orElse: () => categories.first,
                        );
                        onCategorySelected!(allCategory);
                      }
                    },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'See All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 2. Daftar Kategori Horizontal
        SizedBox(
          height: 94,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat.id == selectedCategoryId;

              return _buildCategoryItem(cat, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(ProductCategoryItem item, bool isSelected) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (onCategorySelected != null) {
          onCategorySelected!(item);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lingkaran Icon / Gambar Kategori
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1.2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      item.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    )
                  : Icon(
                      item.icon,
                      size: 24,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // Label Kategori
          SizedBox(
            width: 68,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
