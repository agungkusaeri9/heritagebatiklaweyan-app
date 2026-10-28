import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/cart_item_model.dart';

/// Kartu produk dalam keranjang belanja dengan judul multi-line, harga, kontrol kuantitas kotak,
/// serta animasi geser ke kiri saat tombol edit diklik untuk memunculkan tombol hapus.
class CartItemCard extends StatefulWidget {
  final CartItemModel item;
  final bool isUpdating;
  final bool isDeleting;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const CartItemCard({
    super.key,
    required this.item,
    this.isUpdating = false,
    this.isDeleting = false,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _curvedAnimation;
  bool _showDeleteButton = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _showDeleteButton = !_showDeleteButton;
      if (_showDeleteButton) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            // 1. Tombol Hapus di Belakang Sisi Kanan (Bg Merah Pink, Icon Merah)
            Positioned(
              right: 0,
              child: IgnorePointer(
                ignoring: !_showDeleteButton,
                child: FadeTransition(
                  opacity: _curvedAnimation,
                  child: _buildSlidingDeleteButton(),
                ),
              ),
            ),

            // 2. Konten Kartu Item (Geser ke Kiri saat Edit Ditekan)
            AnimatedBuilder(
              animation: _curvedAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-64.0 * _curvedAnimation.value, 0),
                  child: child,
                );
              },
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gambar Produk
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                        ),
                        child: widget.item.primaryImage != null && widget.item.primaryImage!.isNotEmpty
                            ? Image.network(
                                widget.item.primaryImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _buildPlaceholderImage(),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Detail Produk & Kontrol Kuantitas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Baris Atas: Nama Produk & Tombol Edit
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.productName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Tombol Edit
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: Key('cart_item_edit_button_${widget.item.id}'),
                                  onTap: widget.isDeleting ? null : _toggleEditMode,
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _showDeleteButton
                                          ? const Color(0xFFF1F5F9)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _showDeleteButton
                                          ? Icons.close_rounded
                                          : Icons.edit_outlined,
                                      size: 19,
                                      color: _showDeleteButton
                                          ? const Color(0xFF475569)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 3),

                          // Baris Varian/Ukuran Produk
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.item.displayVariant,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Baris Bawah: Harga Satuan & Tombol Stepper Kuantitas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Harga Produk
                              Flexible(
                                child: Text(
                                  widget.item.formattedPrice,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Kontrol Kuantitas Stepper
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Kurang (-) Kotak
                                  _buildStepperButton(
                                    icon: Icons.remove_rounded,
                                    onTap: widget.isUpdating ? null : widget.onDecrement,
                                    isPrimary: false,
                                  ),

                                  // Angka Kuantitas
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 26),
                                    alignment: Alignment.center,
                                    child: widget.isUpdating
                                        ? const SizedBox(
                                            width: 13,
                                            height: 13,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                            ),
                                          )
                                        : Text(
                                            '${widget.item.qty}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                  ),

                                  // Tombol Tambah (+) Kotak
                                  _buildStepperButton(
                                    icon: Icons.add_rounded,
                                    onTap: (widget.isUpdating || widget.item.qty >= 20)
                                        ? null
                                        : widget.onIncrement,
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol Hapus dengan background merah pink dan icon berwarna merah
  Widget _buildSlidingDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('cart_item_delete_button_${widget.item.id}'),
        onTap: widget.isDeleting ? null : widget.onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2), // Merah pink (pastel red-pink)
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFECACA), // Border merah pink lembut
              width: 1.0,
            ),
          ),
          child: Center(
            child: widget.isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), // Icon merah
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(
        Icons.checkroom_rounded,
        size: 32,
        color: Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: isPrimary
                ? null
                : Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isPrimary ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}


