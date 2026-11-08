import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/checkout_result_model.dart';
import '../../data/models/order_review_model.dart';
import '../viewmodels/checkout_providers.dart';

/// Layar Beri Ulasan Per Produk (Leave Review Screen)
/// Dipilih satu per satu dari daftar produk pada halaman Detail Transaksi yang sudah Selesai (Completed).
class LeaveReviewView extends ConsumerStatefulWidget {
  final String orderNumber;
  final CheckoutResultModel? initialOrder;
  final CheckoutOrderItemModel? targetItem;
  final int? targetProductId;

  const LeaveReviewView({
    super.key,
    required this.orderNumber,
    this.initialOrder,
    this.targetItem,
    this.targetProductId,
  });

  @override
  ConsumerState<LeaveReviewView> createState() => _LeaveReviewViewState();
}

class _LeaveReviewViewState extends ConsumerState<LeaveReviewView> {
  CheckoutResultModel? _order;
  CheckoutOrderItemModel? _selectedItem;
  bool _isLoadingOrder = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _selectedRating = 0;
  late final TextEditingController _commentController;
  final List<String> _photoPaths = [];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _order = widget.initialOrder;
    _selectedItem = widget.targetItem;
    if (_order != null) {
      _resolveSelectedItemAndInitForm(_order!);
    }
    _fetchOrderDetailIfNeeded();
  }

  void _resolveSelectedItemAndInitForm(CheckoutResultModel order) {
    CheckoutOrderItemModel? resolved = _selectedItem;

    if (widget.targetProductId != null && order.items.isNotEmpty) {
      resolved = order.items
              .where((item) => item.productId == widget.targetProductId)
              .firstOrNull ??
          resolved;
    }

    if (resolved == null && order.items.isNotEmpty) {
      // Pilih produk pertama yang belum diulas, atau produk pertama jika semua sudah
      resolved = order.items
              .where((item) => order.reviewForProduct(item.productId) == null)
              .firstOrNull ??
          order.items.first;
    } else if (resolved != null && order.items.isNotEmpty) {
      // Sinkronkan dengan item terbaru dari order
      resolved = order.items
              .where((item) => item.productId == resolved!.productId)
              .firstOrNull ??
          resolved;
    }

    _selectedItem = resolved;

    if (resolved != null) {
      final existingReview = order.reviewForProduct(resolved.productId);
      if (existingReview != null) {
        if (_selectedRating == 0 && existingReview.rating > 0) {
          _selectedRating = existingReview.rating;
        }
        if (_commentController.text.isEmpty && existingReview.comment != null) {
          _commentController.text = existingReview.comment!;
        }
        if (_photoPaths.isEmpty && existingReview.photoPaths.isNotEmpty) {
          _photoPaths.addAll(existingReview.photoPaths);
        }
      }
    }
  }

  Future<void> _fetchOrderDetailIfNeeded() async {
    final hasItems = _order != null && _order!.items.isNotEmpty;
    if (!hasItems) {
      setState(() {
        _isLoadingOrder = true;
        _errorMessage = null;
      });
    }

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final identifier = widget.orderNumber.isNotEmpty
          ? widget.orderNumber
          : (_order?.id ?? '');
      final detail = await repo.getOrderDetail(identifier);
      if (!mounted) return;
      final merged = _order != null ? _order!.mergeWithDetail(detail) : detail;
      setState(() {
        _order = merged;
        _isLoadingOrder = false;
        _errorMessage = null;
        _resolveSelectedItemAndInitForm(merged);
      });
    } catch (e) {
      if (!mounted) return;
      if (!hasItems) {
        setState(() {
          _isLoadingOrder = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= 3) {
      AppSnackBar.showInfo(context, 'Maksimal 3 foto untuk ulasan produk ini.');
      return;
    }

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
      );
      if (picked != null && mounted) {
        setState(() {
          _photoPaths.add(picked.path);
        });
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Tidak dapat membuka galeri foto pada perangkat ini.',
        );
      }
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photoPaths.length) return;
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    final order = _order;
    final item = _selectedItem ?? order?.primaryProduct;
    if (order == null || item == null || _isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (!order.isCompletedOrder) {
      AppSnackBar.showError(
        context,
        'Ulasan hanya dapat dikirimkan untuk transaksi yang telah selesai (Completed).',
      );
      return;
    }

    if (_selectedRating < 1 || _selectedRating > 5) {
      AppSnackBar.showError(
        context,
        'Silakan pilih rating bintang (1–5) terlebih dahulu.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final commentText = _commentController.text.trim();
      final itemReview = OrderItemReviewModel(
        orderId: order.id,
        productId: item.productId,
        rating: _selectedRating,
        comment: commentText.isNotEmpty ? commentText : null,
        photoPaths: List<String>.from(_photoPaths),
        createdAt: DateTime.now(),
      );

      final repo = ref.read(checkoutRepositoryProvider);
      final updatedOrder = await repo.submitOrderReviews(
        order: order,
        transactionRating: _selectedRating,
        transactionComment: commentText.isNotEmpty ? commentText : null,
        productReviews: [itemReview],
      );

      if (!mounted) return;

      ref
          .read(orderListViewModelProvider.notifier)
          .updateOrderInState(updatedOrder);

      AppSnackBar.showSuccess(
        context,
        'Terima kasih! Ulasan untuk "${item.productName}" berhasil dikirim.',
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, updatedOrder);
      } else {
        context.go('/orders');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      AppSnackBar.showError(
        context,
        msg.isNotEmpty ? msg : 'Gagal mengirim ulasan. Silakan coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final item = _selectedItem ?? order?.primaryProduct;
    final existingReview =
        (order != null && item != null) ? order.reviewForProduct(item.productId) : null;
    final bool isReadOnly = existingReview != null || (item?.isReviewed ?? false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, isReadOnly: isReadOnly),
            Expanded(
              child: _isLoadingOrder && order == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _errorMessage != null && order == null
                      ? _buildErrorState()
                      : (order != null && item != null)
                          ? _buildReviewContent(
                              context,
                              order,
                              item,
                              isReadOnly: isReadOnly,
                            )
                          : const SizedBox.shrink(),
            ),
            if (order != null && item != null)
              _buildBottomActionBar(context, isReadOnly: isReadOnly),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isReadOnly}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('leave_review_back_button'),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/orders');
                }
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Text(
            isReadOnly ? 'Your Review' : 'Leave Review',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat data transaksi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrderDetailIfNeeded,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewContent(
    BuildContext context,
    CheckoutResultModel order,
    CheckoutOrderItemModel item, {
    required bool isReadOnly,
  }) {
    final variantPart = item.hasVariant ? '${item.displayVariant} | ' : '';
    final subInfoText = '${variantPart}Qty : ${item.quantity.toString().padLeft(2, '0')} pcs';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ringkasan Produk yang Dipilih (Sesuai Desain Referensi)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: item.primaryImage != null &&
                          item.primaryImage!.isNotEmpty
                      ? Image.network(
                          item.primaryImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.checkroom_rounded,
                            size: 32,
                            color: Color(0xFFCBD5E1),
                          ),
                        )
                      : const Icon(
                          Icons.checkroom_rounded,
                          size: 32,
                          color: Color(0xFFCBD5E1),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subInfoText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.formattedTotalPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            order.orderNumber.isNotEmpty
                                ? '#${order.orderNumber}'
                                : 'Re-Order',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          // 2. Judul "How is your order?"
          Center(
            child: Text(
              'How is your order?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          // 3. Bintang Penilaian Interaktif (1 - 5 Bintang)
          Center(
            child: Column(
              children: [
                Text(
                  'Your overall rating',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (idx) {
                    final starValue = idx + 1;
                    final isSelected = starValue <= _selectedRating;
                    return GestureDetector(
                      key: Key('review_star_$starValue'),
                      onTap: isReadOnly
                          ? null
                          : () {
                              setState(() {
                                _selectedRating = starValue;
                              });
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Icon(
                          Icons.star_rounded,
                          size: 44,
                          color: isSelected
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          // 4. Add detailed review
          Text(
            'Add detailed review',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('review_comment_input'),
            controller: _commentController,
            readOnly: isReadOnly,
            maxLines: 4,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Enter here',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 5. Add photo
          if (!isReadOnly || _photoPaths.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!isReadOnly)
                  InkWell(
                    key: const Key('add_review_photo_button'),
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add photo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ..._photoPaths.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final path = entry.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(
                                Icons.image_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isReadOnly)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removePhoto(idx),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context, {
    required bool isReadOnly,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: isReadOnly
          ? SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('close_review_button'),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, _order);
                  } else {
                    context.go('/orders');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Kembali ke Detail Pesanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('cancel_review_button'),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                context.go('/orders');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('submit_review_button'),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
