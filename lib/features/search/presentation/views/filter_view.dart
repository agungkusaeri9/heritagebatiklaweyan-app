import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/product_filter_model.dart';

/// Halaman Filter Produk Batik
class FilterView extends StatefulWidget {
  final ProductFilter? initialFilter;

  const FilterView({
    super.key,
    this.initialFilter,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  late ProductFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? const ProductFilter();
  }

  void _resetFilter() {
    setState(() {
      _currentFilter = const ProductFilter();
    });
  }

  void _applyFilter() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_currentFilter);
    } else {
      context.pop(_currentFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Filter',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilter,
            child: Text(
              'Reset',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gender Filter
            _buildSectionTitle('Gender'),
            const SizedBox(height: 12),
            _buildGenderChips(),

            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 20),

            // 2. Sort By Filter
            _buildSectionTitle('Sort By'),
            const SizedBox(height: 12),
            _buildSortByChips(),

            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 20),

            // 3. Pricing Range Filter
            _buildSectionTitle('Pricing Range'),
            const SizedBox(height: 8),
            _buildPriceRangeSelector(),

            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 20),

            // 4. Reviews / Rating Filter
            _buildSectionTitle('Reviews / Rating'),
            const SizedBox(height: 12),
            _buildRatingChips(),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFFF1F5F9),
      height: 1,
      thickness: 1,
    );
  }

  /// 1. Chips Pilihan Gender
  Widget _buildGenderChips() {
    final options = [
      {'label': 'All', 'value': GenderFilter.all},
      {'label': 'Men', 'value': GenderFilter.men},
      {'label': 'Women', 'value': GenderFilter.women},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final val = opt['value'] as GenderFilter;
        final isSelected = _currentFilter.gender == val;
        return _buildSelectableChip(
          label: opt['label'] as String,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _currentFilter = _currentFilter.copyWith(gender: val);
            });
          },
        );
      }).toList(),
    );
  }

  /// 2. Chips Pilihan Sort By
  Widget _buildSortByChips() {
    final options = [
      {'label': 'Most Recent', 'value': SortByFilter.mostRecent},
      {'label': 'Popular', 'value': SortByFilter.popular},
      {'label': 'Price: Low to High', 'value': SortByFilter.priceLowToHigh},
      {'label': 'Price: High to Low', 'value': SortByFilter.priceHighToLow},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final val = opt['value'] as SortByFilter;
        final isSelected = _currentFilter.sortBy == val;
        return _buildSelectableChip(
          label: opt['label'] as String,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _currentFilter = _currentFilter.copyWith(sortBy: val);
            });
          },
        );
      }).toList(),
    );
  }

  /// 3. Slider Pemilihan Range Harga
  Widget _buildPriceRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Harga Min dan Max
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(_currentFilter.minPrice),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '—',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(_currentFilter.maxPrice),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Range Slider (Smooth solid track tanpa putus-putus putih)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            rangeTickMarkShape: const RoundRangeSliderTickMarkShape(tickMarkRadius: 0),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          child: RangeSlider(
            values: RangeValues(_currentFilter.minPrice, _currentFilter.maxPrice),
            min: ProductFilter.defaultMinPrice,
            max: ProductFilter.defaultMaxPrice,
            activeColor: AppColors.primary,
            inactiveColor: const Color(0xFFE2E8F0),
            onChanged: (RangeValues values) {
              const step = 50000.0;
              final start = ((values.start / step).round() * step)
                  .clamp(ProductFilter.defaultMinPrice, values.end);
              final end = ((values.end / step).round() * step)
                  .clamp(values.start, ProductFilter.defaultMaxPrice);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  minPrice: start,
                  maxPrice: end,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  /// 4. Chips Pilihan Rating / Reviews
  Widget _buildRatingChips() {
    final options = [
      {'label': 'All', 'value': RatingFilter.all, 'icon': false},
      {'label': '4.5 and above', 'value': RatingFilter.fourPointFiveAndAbove, 'icon': true},
      {'label': '4.0 – 4.5', 'value': RatingFilter.fourToFourPointFive, 'icon': true},
      {'label': '3.5 – 4.0', 'value': RatingFilter.threePointFiveToFour, 'icon': true},
      {'label': '3.0 – 3.5', 'value': RatingFilter.threeToThreePointFive, 'icon': true},
      {'label': 'Below 3.0', 'value': RatingFilter.belowThree, 'icon': true},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final val = opt['value'] as RatingFilter;
        final hasIcon = opt['icon'] as bool;
        final isSelected = _currentFilter.rating == val;
        return _buildSelectableChip(
          label: opt['label'] as String,
          isSelected: isSelected,
          leadingIcon: hasIcon ? Icons.star_rounded : null,
          iconColor: isSelected ? Colors.amber.shade200 : const Color(0xFFF59E0B),
          onTap: () {
            setState(() {
              _currentFilter = _currentFilter.copyWith(rating: val);
            });
          },
        );
      }).toList(),
    );
  }

  /// Helper Widget Reusable Chip
  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? leadingIcon,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 17,
                  color: iconColor ?? (isSelected ? Colors.white : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fixed Bottom Action Bar: Reset Filter & Apply
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Tombol Reset Filter
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _resetFilter,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Reset Filter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Tombol Apply
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
