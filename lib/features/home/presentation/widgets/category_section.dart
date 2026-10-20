import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_dummy_data.dart';

/// Reusable Widget: CategorySection
/// Menampilkan deretan kategori batik (Sarung, Kain, Tunik, Anak-Anak, All) dengan interaksi lokal
class CategorySection extends StatefulWidget {
  final List<ProductCategoryItem> categories;
  final ValueChanged<ProductCategoryItem>? onCategorySelected;
  final String? initialSelectedId;

  const CategorySection({
    super.key,
    this.categories = HomeDummyData.categories,
    this.onCategorySelected,
    this.initialSelectedId = 'all',
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialSelectedId ?? 'all';
  }

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
                onTap: () {
                  setState(() {
                    _selectedCategoryId = 'all';
                  });
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
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = widget.categories[index];
              final isSelected = cat.id == _selectedCategoryId;

              return _buildCategoryItem(cat, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(ProductCategoryItem item, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = item.id;
        });
        if (widget.onCategorySelected != null) {
          widget.onCategorySelected!(item);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lingkaran Icon Kategori
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
            child: Icon(
              item.icon,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 8),

          // Label Kategori
          Text(
            item.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
