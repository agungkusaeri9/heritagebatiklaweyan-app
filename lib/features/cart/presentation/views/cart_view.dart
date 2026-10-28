import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/cart_providers.dart';
import '../viewmodels/cart_state.dart';
import '../widgets/cart_delete_bottom_sheet.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_price_summary_card.dart';
import '../widgets/cart_skeleton.dart';

/// Halaman Keranjang Belanja (My Cart)
/// Menampilkan daftar produk yang dimasukkan ke keranjang, kontrol kuantitas (+/-),
/// aksi hapus dengan konfirmasi, seksi kode promo ringkas non-editable,
/// rincian harga (order summary), dan tombol checkout tetap di bagian bawah.
class CartView extends ConsumerStatefulWidget {
  const CartView({super.key});

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  @override
  void initState() {
    super.initState();
    // Memuat data keranjang saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartViewModelProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header dengan tombol Back dan Judul "My Cart"
            _buildAppBar(context, state.totalItemCount),

            // 2. Konten Halaman Keranjang
            Expanded(
              child: _buildBody(context, state),
            ),
          ],
        ),
      ),
    );
  }

  /// App Bar Header kustom dengan tombol kembali dan judul tengah
  Widget _buildAppBar(BuildContext context, int totalItemCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali (Back Button)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/home');
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // Judul Halaman
          Text(
            'My Cart',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),

          // Sisi Kanan Penyeimbang / Badge Total Barang
          if (totalItemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalItemCount items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            )
          else
            const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }

  /// Memilih widget isi sesuai status state
  Widget _buildBody(BuildContext context, CartState state) {
    if (state.isLoading) {
      return const CartSkeleton();
    }

    if (state.isError) {
      return _buildErrorState(state.errorMessage ?? 'Gagal memuat keranjang belanja.');
    }

    if (state.isEmpty) {
      return _buildEmptyCartState(context);
    }

    return Column(
      children: [
        // Daftar Produk yang Dapat Di-scroll
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await ref.read(cartViewModelProvider.notifier).loadCart(isRefresh: true);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                // 1. Daftar Item Produk di Keranjang
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return CartItemCard(
                      item: item,
                      isUpdating: state.isItemUpdating(item.id),
                      isDeleting: state.isItemDeleting(item.id),
                      onIncrement: () {
                        ref.read(cartViewModelProvider.notifier).incrementQuantity(
                          item.id,
                          onError: (msg) => _showSnackBar(msg),
                        );
                      },
                      onDecrement: () {
                        ref.read(cartViewModelProvider.notifier).decrementQuantity(
                          item.id,
                          onDeleteConfirm: () {
                            CartDeleteBottomSheet.show(
                              context,
                              item: item,
                              onConfirmDelete: () {
                                ref.read(cartViewModelProvider.notifier).deleteItem(
                                  item.id,
                                  onError: (msg) => _showSnackBar(msg),
                                );
                              },
                            );
                          },
                          onError: (msg) => _showSnackBar(msg),
                        );
                      },
                      onDelete: () {
                        CartDeleteBottomSheet.show(
                          context,
                          item: item,
                          onConfirmDelete: () {
                            ref.read(cartViewModelProvider.notifier).deleteItem(
                              item.id,
                              onError: (msg) => _showSnackBar(msg),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // 2. Order Summary & Tombol Proceed to Checkout (Fixed di Bagian Bawah)
        _buildBottomFixedSection(context, state),
      ],
    );
  }

  /// Bagian rincian harga dan tombol checkout tetap di bagian bawah
  Widget _buildBottomFixedSection(BuildContext context, CartState state) {
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
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rincian Harga (Subtotal & Total Cost tanpa delivery fee)
          CartPriceSummaryCard(
            subtotal: state.formattedSubtotal,
            totalCost: state.formattedSubtotal,
          ),

          const SizedBox(height: 16),

          // Tombol Proceed to Checkout
          ElevatedButton(
            onPressed: () {
              _handleProceedToCheckout(context, state);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Checkout',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menangani aksi navigasi checkout
  void _handleProceedToCheckout(BuildContext context, CartState state) {
    if (state.items.isEmpty) {
      _showSnackBar('Keranjang belanja Anda masih kosong.');
      return;
    }

    context.push('/checkout');
  }


  /// Tampilan jika keranjang kosong
  Widget _buildEmptyCartState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 46,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your Cart is Empty',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Looks like you haven\'t added any authentic batik collections to your cart yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        height: 1.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Start Shopping',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tampilan jika terjadi kesalahan saat memuat keranjang
  Widget _buildErrorState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 38,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Failed to Load Cart',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(cartViewModelProvider.notifier).loadCart();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Try Again',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
