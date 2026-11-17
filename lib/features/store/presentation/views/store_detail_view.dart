import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../home/data/models/home_dummy_data.dart';
import '../../../home/presentation/viewmodels/home_providers.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../data/models/store_setting_model.dart';
import '../viewmodels/store_providers.dart';

/// Halaman Detail Toko (Store Detail Screen)
/// Menampilkan identitas toko resmi, kontak, alamat, dan daftar koleksi produk toko.
class StoreDetailView extends ConsumerStatefulWidget {
  final int storeId;
  final StoreSettingModel? initialStore;

  const StoreDetailView({
    super.key,
    required this.storeId,
    this.initialStore,
  });

  @override
  ConsumerState<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends ConsumerState<StoreDetailView> {
  StoreSettingModel? _store;
  List<ProductItem> _storeProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _store = widget.initialStore ??
        (widget.storeId <= 0 ? ref.read(currentStoreSettingProvider) : null);
    _loadStoreAndProducts();
  }

  Future<void> _loadStoreAndProducts() async {
    if (_store == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final storeDataSource = ref.read(storeRemoteDataSourceProvider);
      final homeRepository = ref.read(homeRepositoryProvider);

      final Future<StoreSettingModel> storeFuture = widget.storeId > 0
          ? storeDataSource.getStoreById(widget.storeId).catchError(
                (_) => _store ?? HomeDummyData.defaultStore,
              )
          : storeDataSource.getStoreSetting().catchError(
                (_) => _store ?? HomeDummyData.defaultStore,
              );

      final results = await Future.wait([
        storeFuture,
        homeRepository.getOtherProducts(
          page: 1,
          perPage: 20,
          storeId: widget.storeId > 0 ? widget.storeId : null,
        ),
      ]);

      if (!mounted) return;

      final fetchedStore = results[0] as StoreSettingModel;
      final productsResult = results[1] as dynamic;
      final products = (productsResult.items as List<ProductItem>);

      setState(() {
        _store = fetchedStore;
        _storeProducts = products;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _store ??= HomeDummyData.defaultStore;
        _isLoading = false;
        _errorMessage =
            'Maaf, server sedang mengalami gangguan saat memuat produk toko.';
      });
    }
  }

  Future<void> _handleAddToCart(ProductItem product) async {
    final productId = int.tryParse(product.id) ?? 0;
    if (productId <= 0) return;

    final success = await ref.read(cartViewModelProvider.notifier).addToCart(
      productId,
      quantity: 1,
      onError: (msg) {
        if (mounted) AppSnackBar.showError(context, msg);
      },
    );

    if (success && mounted) {
      AppSnackBar.showSuccess(
        context,
        '${product.name} berhasil ditambahkan ke keranjang.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final cartCount = ref.watch(cartItemCountProvider);
    final store = _store ?? HomeDummyData.defaultStore;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading && _store == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadStoreAndProducts,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          _buildStoreProfileCard(store),
                          const SizedBox(height: 16),
                          _buildStoreContactCard(context, store),
                          const SizedBox(height: 20),
                          _buildStoreProductsSection(context),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('store_detail_back_button'),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/home');
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
            'Store Detail',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          // Spacer penyeimbang tombol back agar judul tetap di tengah
          const SizedBox(width: 42),

          /*
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('store_detail_cart_button'),
                  onTap: () => context.push('/cart'),
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
                      Icons.shopping_bag_outlined,
                      size: 20,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          */
        ],
      ),
    );
  }

  Widget _buildStoreProfileCard(StoreSettingModel store) {
    return Container(
      key: const Key('store_detail_profile_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                      ? Image.network(
                          store.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            store.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Official Batik Store · ID #${widget.storeId}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (store.description != null &&
              store.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              store.description!.trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreContactCard(BuildContext context, StoreSettingModel store) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi & Lokasi Toko',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Alamat Toko',
            store.address?.isNotEmpty == true
                ? store.address!
                : 'Kampung Batik Laweyan, Surakarta, Jawa Tengah',
          ),
          if (store.phone != null && store.phone!.isNotEmpty)
            _buildInfoRow(
              Icons.phone_outlined,
              'Telepon',
              store.phone!,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: store.phone!));
                AppSnackBar.showSuccess(context, 'Nomor telepon toko disalin.');
              },
            ),
          if (store.whatsapp != null && store.whatsapp!.isNotEmpty)
            _buildInfoRow(
              Icons.chat_outlined,
              'WhatsApp',
              store.whatsapp!,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: store.whatsapp!));
                AppSnackBar.showSuccess(context, 'Nomor WhatsApp toko disalin.');
              },
            ),
          if (store.email != null && store.email!.isNotEmpty)
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              store.email!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildStoreProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Koleksi Produk Toko (${_storeProducts.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_errorMessage != null && _storeProducts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadStoreAndProducts,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _storeProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.61,
            ),
            itemBuilder: (context, index) {
              final product = _storeProducts[index];
              return ProductCard(
                product: product,
                width: null,
                onProductTap: (p) =>
                    context.push('/product/${p.id}', extra: p),
                onAddToCart: () => _handleAddToCart(product),
              );
            },
          ),
      ],
    );
  }
}

