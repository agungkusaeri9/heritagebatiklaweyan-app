import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../cart/presentation/viewmodels/cart_state.dart';
import '../../../store/data/models/store_setting_model.dart';
import '../../../store/presentation/viewmodels/store_providers.dart';
import '../../../wishlist/presentation/viewmodels/wishlist_providers.dart';
import '../../data/models/home_dummy_data.dart';
import '../viewmodels/home_providers.dart';
import '../viewmodels/tryon_progress_provider.dart';

/// Halaman Detail Produk (Product Detail Screen)
/// Menampilkan gambar besar produk dengan fitur preview, informasi harga & diskon,
/// jumlah pembeli, tombol wishlist (favorit), identitas toko yang dapat diklik,
/// deskripsi lengkap produk, pemilih kuantitas, serta tombol Add to Cart.
class ProductDetailView extends ConsumerStatefulWidget {
  final String productId;
  final ProductItem? initialProduct;

  const ProductDetailView({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  ProductItem? _product;
  StoreSettingModel? _store;
  bool _isLoading = false;
  String? _errorMessage;

  int _selectedImageIndex = 0;
  late final PageController _imagePageController;
  final ScrollController _scrollController = ScrollController();
  bool _isAddingToCart = false;
  bool? _localFavoriteOverride;

  // State Ulasan Produk (Reviews + Filter Bintang + Infinite Scroll Pagination)
  List<ProductReviewItem> _reviews = [];
  ProductRatingStats _ratingStats = const ProductRatingStats();
  int? _selectedReviewRatingFilter; // null = Semua, 1..5 = Filter bintang
  int _currentReviewsPage = 1;
  bool _hasMoreReviews = false;
  bool _isLoadingReviews = false;
  bool _isLoadingMoreReviews = false;
  String? _reviewsErrorMessage;

  // State Virtual Try-On & Background Progress
  VirtualTryOnTaskItem? _activeTryOnTask;
  Timer? _tryOnPollingTimer;
  bool _isRetryingTryOn = false;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController(initialPage: _selectedImageIndex);
    _scrollController.addListener(_onDetailScroll);
    _product = widget.initialProduct;
    _store = widget.initialProduct?.store;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cartState = ref.read(cartViewModelProvider);
      if (cartState.status == CartStatus.initial) {
        ref.read(cartViewModelProvider.notifier).loadCart();
      }
      _fetchProductAndStore(silent: _product != null);
      _fetchProductReviews(page: 1, reset: true);
    });
  }

  @override
  void dispose() {
    _stopTryOnPolling();
    _scrollController.removeListener(_onDetailScroll);
    _scrollController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _stopTryOnPolling() {
    _tryOnPollingTimer?.cancel();
    _tryOnPollingTimer = null;
  }

  void _startTryOnPolling(int tryOnId) {
    _stopTryOnPolling();
    _tryOnPollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollTryOnProgress(tryOnId),
    );
  }

  Future<void> _pollTryOnProgress(int tryOnId) async {
    try {
      final repo = ref.read(homeRepositoryProvider);
      final updated = await repo.getVirtualTryOnProgress(tryOnId);
      if (!mounted) return;

      setState(() {
        _activeTryOnTask = updated;
        ref.read(tryOnProgressProvider.notifier).addTask(updated);
        if (updated.isCompleted &&
            updated.photoUrl != null &&
            updated.photoUrl!.isNotEmpty &&
            _product != null) {
          final currentGallery = _product!.galleryImages;
          if (!currentGallery.contains(updated.photoUrl!)) {
            _product = _product!.copyWith(
              galleryImages: [updated.photoUrl!, ...currentGallery],
            );
          }
        }
      });

      if (updated.isCompleted || updated.isFailed) {
        _stopTryOnPolling();
        ref.read(tryOnProgressProvider.notifier).addTask(updated);
        if (updated.isCompleted &&
            updated.photoUrl != null &&
            updated.photoUrl!.isNotEmpty &&
            _product != null) {
          AppSnackBar.showSuccess(
            context,
            'Virtual Try-On selesai! Ketuk kartu progress untuk melihat hasil.',
          );
        }
      }
    } catch (_) {
      // Abaikan error jaringan sesaat saat polling di background
    }
  }

  Future<void> _handleRetryTryOn() async {
    final task = _activeTryOnTask;
    if (task == null || _isRetryingTryOn) return;

    setState(() {
      _isRetryingTryOn = true;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final retried = await repo.retryVirtualTryOn(task.id);
      if (!mounted) return;
      setState(() {
        _activeTryOnTask = retried;
        _isRetryingTryOn = false;
      });
      ref.read(tryOnProgressProvider.notifier).addTask(retried);
      _startTryOnPolling(retried.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRetryingTryOn = false;
      });
      AppSnackBar.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _showVirtualTryOnBottomSheet(
    BuildContext context,
    ProductItem product,
  ) async {
    final authState = ref.read(authViewModelProvider);
    if (!authState.isAuthenticated) {
      AppSnackBar.showInfo(
        context,
        'Silakan masuk ke akun Anda terlebih dahulu untuk mencoba fitur Virtual Try-On.',
      );
      context.push('/login');
      return;
    }

    final createdTask = await showModalBottomSheet<VirtualTryOnTaskItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VirtualTryOnBottomSheet(product: product),
    );

    if (createdTask != null && mounted) {
      ref.read(tryOnProgressProvider.notifier).addTask(createdTask);
      setState(() {
        _activeTryOnTask = createdTask;
      });
      AppSnackBar.showInfo(
        context,
        'Virtual Try-On sedang diproses di background. Progress ditampilkan di kanan bawah.',
      );
      if (createdTask.isActive) {
        _startTryOnPolling(createdTask.id);
      }
    }
  }

  void _showVirtualTryOnResultDialog(
    BuildContext context,
    ProductItem product,
    VirtualTryOnTaskItem task,
  ) {
    if (task.photoUrl == null || task.photoUrl!.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (dialogContext) => _VirtualTryOnResultDialog(
        product: product,
        photoUrl: task.photoUrl!,
      ),
    );
  }

  void _onDetailScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 220) {
      _loadMoreReviews();
    }
  }

  Future<void> _fetchProductReviews({int page = 1, bool reset = false}) async {
    if (_isLoadingReviews) return;

    setState(() {
      _isLoadingReviews = true;
      if (reset) {
        _reviewsErrorMessage = null;
      }
    });

    try {
      final homeRepository = ref.read(homeRepositoryProvider);
      final targetIdOrSlug = (_product?.slug.isNotEmpty == true)
          ? _product!.slug
          : widget.productId;

      final result = await homeRepository.getProductReviews(
        targetIdOrSlug,
        page: page,
        perPage: 5,
        rating: _selectedReviewRatingFilter,
      );

      if (!mounted) return;

      setState(() {
        _reviews = result.items;
        if (result.stats.totalCount > 0 ||
            _selectedReviewRatingFilter == null) {
          _ratingStats = result.stats;
        }
        _currentReviewsPage = result.currentPage;
        _hasMoreReviews = result.hasMore;
        _isLoadingReviews = false;
        _reviewsErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
        _reviewsErrorMessage =
            'Gagal memuat ulasan produk dari server. Silakan coba lagi.';
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMoreReviews || _isLoadingReviews || !_hasMoreReviews) {
      return;
    }

    setState(() {
      _isLoadingMoreReviews = true;
    });

    try {
      final homeRepository = ref.read(homeRepositoryProvider);
      final targetIdOrSlug = (_product?.slug.isNotEmpty == true)
          ? _product!.slug
          : widget.productId;
      final nextPage = _currentReviewsPage + 1;

      final result = await homeRepository.getProductReviews(
        targetIdOrSlug,
        page: nextPage,
        perPage: 5,
        rating: _selectedReviewRatingFilter,
      );

      if (!mounted) return;

      final existingIds = _reviews.map((r) => r.id).toSet();
      final uniqueNew = result.items
          .where((r) => !existingIds.contains(r.id))
          .toList();

      setState(() {
        _reviews = [..._reviews, ...uniqueNew];
        if (result.stats.totalCount > 0) {
          _ratingStats = result.stats;
        }
        _currentReviewsPage = result.currentPage;
        _hasMoreReviews = result.hasMore;
        _isLoadingMoreReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMoreReviews = false;
      });
    }
  }

  void _handleSelectReviewRatingFilter(int? star) {
    final nextFilter = (_selectedReviewRatingFilter == star) ? null : star;
    setState(() {
      _selectedReviewRatingFilter = nextFilter;
      _currentReviewsPage = 1;
      _hasMoreReviews = false;
    });
    _fetchProductReviews(page: 1, reset: true);
  }

  void _selectImageIndex(int index, {bool animatePage = true}) {
    if (_selectedImageIndex != index) {
      setState(() {
        _selectedImageIndex = index;
      });
    }
    if (animatePage && _imagePageController.hasClients) {
      _imagePageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _fetchProductAndStore({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final homeRepository = ref.read(homeRepositoryProvider);
      final storeDataSource = ref.read(storeRemoteDataSourceProvider);
      final cachedStore = ref.read(currentStoreSettingProvider);

      final fetchedProduct = await homeRepository.getProductDetail(
        widget.productId,
      );

      StoreSettingModel? resolvedStore = fetchedProduct.store ?? cachedStore;
      if (resolvedStore == null) {
        try {
          resolvedStore = await storeDataSource.getStoreSetting();
        } catch (_) {
          resolvedStore = HomeDummyData.defaultStore;
        }
      }

      final StoreSettingModel finalStore =
          resolvedStore ?? HomeDummyData.defaultStore;

      if (!mounted) return;

      setState(() {
        _product = fetchedProduct.copyWith(
          store: finalStore,
          storeId: finalStore.id,
          // Pertahankan informasi diskon dari kartu awal bila API belum menyertakannya
          originalPrice:
              (_product != null &&
                  _product!.hasDiscount &&
                  !fetchedProduct.hasDiscount)
              ? _product!.originalPrice
              : fetchedProduct.originalPrice,
          discountPercentage:
              (_product != null &&
                  _product!.hasDiscount &&
                  !fetchedProduct.hasDiscount)
              ? _product!.discountPercentage
              : fetchedProduct.discountPercentage,
        );
        _store = finalStore;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_product == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal memuat detail produk. Silakan periksa koneksi Anda.';
        });
      } else {
        setState(() {
          _store ??=
              ref.read(currentStoreSettingProvider) ??
              HomeDummyData.defaultStore;
          _isLoading = false;
        });
      }
    }
  }

  bool _isWishlisted(ProductItem product) {
    if (_localFavoriteOverride != null) {
      return _localFavoriteOverride!;
    }
    final wishlistIds = ref.watch(wishlistIdsProvider);
    if (wishlistIds.contains(product.id)) {
      return true;
    }
    return product.isFavorite;
  }

  Future<void> _handleToggleWishlist(ProductItem product) async {
    final productIdInt = int.tryParse(product.id) ?? 0;
    if (productIdInt <= 0) {
      AppSnackBar.showError(context, 'ID produk tidak valid.');
      return;
    }

    final nextState = await ref
        .read(wishlistViewModelProvider.notifier)
        .toggleWishlist(
          productIdInt,
          onError: (msg) {
            if (mounted) AppSnackBar.showError(context, msg);
          },
        );

    if (!mounted) return;
    setState(() {
      _localFavoriteOverride = nextState;
      _product = product.copyWith(isFavorite: nextState);
    });
    if (nextState) {
      AppSnackBar.showSuccess(context, 'Ditambahkan ke wishlist.');
    } else {
      AppSnackBar.showSuccess(context, 'Dihapus dari wishlist.');
    }
  }

  void _showAddToCartBottomSheet(BuildContext context, ProductItem product) {
    if (!product.isInStock || product.stock <= 0) {
      AppSnackBar.showError(
        context,
        'Maaf, produk ini sedang kehabisan stok (Out of Stock).',
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddToCartBottomSheet(
          product: product,
          onConfirmAddToCart: (int quantity, String? variantInfo) async {
            return _executeAddToCart(
              product,
              quantity: quantity,
              variantInfo: variantInfo,
            );
          },
        );
      },
    );
  }

  Future<bool> _executeAddToCart(
    ProductItem product, {
    required int quantity,
    String? variantInfo,
  }) async {
    if (_isAddingToCart) return false;

    if (!product.isInStock || product.stock <= 0) {
      AppSnackBar.showError(
        context,
        'Maaf, produk ini sedang kehabisan stok (Out of Stock).',
      );
      return false;
    }

    if (quantity < 1) {
      AppSnackBar.showError(context, 'Jumlah pembelian minimal 1 pcs.');
      return false;
    }

    final int productIdInt = int.tryParse(product.id) ?? 0;
    if (productIdInt <= 0) {
      AppSnackBar.showError(context, 'ID produk tidak valid.');
      return false;
    }

    // Periksa jumlah produk yang sudah ada di keranjang agar tidak melampaui stok
    final cartState = ref.read(cartViewModelProvider);
    final existingCartItem = cartState.items
        .where((item) => item.productId == productIdInt)
        .firstOrNull;
    final int currentInCartQty = existingCartItem?.qty ?? 0;

    if (currentInCartQty + quantity > product.stock) {
      final int remainingAllowed = (product.stock - currentInCartQty).clamp(
        0,
        product.stock,
      );
      if (remainingAllowed <= 0) {
        AppSnackBar.showError(
          context,
          'Seluruh stok tersedia (${product.stock} pcs) sudah ada di keranjang Anda.',
        );
      } else {
        AppSnackBar.showError(
          context,
          'Stok tersisa ${product.stock} pcs ($currentInCartQty pcs sudah di keranjang). Maksimal tambah $remainingAllowed pcs lagi.',
        );
      }
      return false;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      String? errorMsg;
      final success = await ref
          .read(cartViewModelProvider.notifier)
          .addToCart(
            productIdInt,
            quantity: quantity,
            variantInfo: variantInfo,
            onError: (msg) {
              errorMsg = msg;
            },
          );

      if (!mounted) return false;

      if (success) {
        final variantLabel = (variantInfo != null && variantInfo.isNotEmpty)
            ? ' ($variantInfo)'
            : '';
        AppSnackBar.showSuccess(
          context,
          '${product.name}$variantLabel (${quantity}x) berhasil ditambahkan ke keranjang.',
        );
        return true;
      } else {
        AppSnackBar.showError(
          context,
          errorMsg ?? 'Gagal menambahkan produk ke keranjang.',
        );
        return false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  void _handleOpenStoreDetail(ProductItem product, StoreSettingModel store) {
    final storeId = store.id > 0 ? store.id : product.storeId;
    context.push('/store/$storeId', extra: store);
  }

  void _showImagePreviewDialog(
    BuildContext context,
    ProductItem product,
    List<String> images,
    int initialIndex,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return _ProductGalleryPreviewDialog(
          product: product,
          images: images,
          initialIndex: initialIndex,
          onIndexChanged: (newIndex) {
            _selectImageIndex(newIndex, animatePage: true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);
    final product = _product;
    final store =
        _store ??
        product?.store ??
        ref.watch(currentStoreSettingProvider) ??
        HomeDummyData.defaultStore;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Screen Header: Back Button, "Details product" Title, & Cart Icon with Badge
                _buildHeader(context, cartCount),

                // 2. Scrollable Content Area
                Expanded(
                  child: _isLoading && product == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : _errorMessage != null && product == null
                      ? _buildErrorState()
                      : product == null
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            await Future.wait([
                              _fetchProductAndStore(silent: false),
                              _fetchProductReviews(page: 1, reset: true),
                            ]);
                          },
                          child: _buildProductDetailBody(
                            context,
                            product,
                            store,
                          ),
                        ),
                ),

                // 3. Fixed Bottom Action Bar: Try On (30%) & Add to Cart (70%)
                if (product != null) _buildBottomActionBar(context, product),
              ],
            ),
          ),

        ],
      ),
    );
  }

  /// 1. Screen Header
  Widget _buildHeader(BuildContext context, int cartCount) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Navigation Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('product_detail_back_button'),
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

          // Page Title: "Details product"
          Text(
            'Details product',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),

          // Shopping Cart Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('product_detail_cart_button'),
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
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    key: const Key('product_detail_cart_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 19,
                      minHeight: 19,
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailBody(
    BuildContext context,
    ProductItem product,
    StoreSettingModel store,
  ) {
    final allImages = product.allImages;
    final int galleryCount = allImages.isNotEmpty ? allImages.length : 1;
    final int safeIndex = _selectedImageIndex.clamp(0, galleryCount - 1);
    final isWishlisted = _isWishlisted(product);

    final descriptionText = product.description.trim().isNotEmpty
        ? product.description.trim()
        : 'Koleksi ${product.name} autentik dari pengrajin Kampung Batik Laweyan, Surakarta. '
              'Dibuat menggunakan bahan pilihan berkualitas tinggi dengan motif batik filosofis yang nyaman dipakai untuk berbagai kesempatan formal maupun kasual.';

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2A. Compact Primary Image (Bisa digeser kiri/kanan & diklik untuk preview)
          GestureDetector(
            key: const Key('product_detail_image_preview'),
            onTap: () =>
                _showImagePreviewDialog(context, product, allImages, safeIndex),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _imagePageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: galleryCount,
                      onPageChanged: (index) {
                        if (_selectedImageIndex != index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        }
                      },
                      itemBuilder: (context, index) {
                        final imgUrl = allImages.isNotEmpty
                            ? allImages[index]
                            : product.imageUrl;
                        if (imgUrl != null && imgUrl.isNotEmpty) {
                          return Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildLargePlaceholder(product),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFFF8FAFC),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return _buildLargePlaceholder(product);
                      },
                    ),

                    // Tombol Geser Kiri pada Gambar Utama (jika ada > 1 gambar)
                    if (galleryCount > 1 && safeIndex > 0)
                      Positioned(
                        left: 10,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _selectImageIndex(safeIndex - 1),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Tombol Geser Kanan pada Gambar Utama (jika ada > 1 gambar)
                    if (galleryCount > 1 && safeIndex < galleryCount - 1)
                      Positioned(
                        right: 10,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _selectImageIndex(safeIndex + 1),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Indikator Posisi Foto (1 / N) di Pojok Kiri Bawah
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${safeIndex + 1} / $galleryCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Indikator Preview Gambar di Pojok Kanan Bawah Gambar
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_in_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Preview',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Deretan Gallery Thumbnail di bawah Gambar Utama (selalu tampil)
          const SizedBox(height: 12),
          SizedBox(
            key: const Key('product_detail_gallery_strip'),
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: galleryCount,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final String? img = allImages.isNotEmpty
                    ? allImages[index]
                    : product.imageUrl;
                final bool isSelected = index == safeIndex;
                return GestureDetector(
                  key: Key('product_detail_gallery_item_$index'),
                  onTap: () => _selectImageIndex(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9.5),
                      child: (img != null && img.isNotEmpty)
                          ? Image.network(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildThumbnailPlaceholder(product),
                            )
                          : _buildThumbnailPlaceholder(product),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // 2B. Product Information: Name, Discount Badge, Prices, Purchase Count & Favorite Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      key: const Key('product_detail_name'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Discount Badge + Strikethrough Original Price + Selling Price
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (product.hasDiscount)
                          Container(
                            key: const Key('product_detail_discount_badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${product.discountPercentage}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        if (product.hasDiscount)
                          Text(
                            product.formattedOriginalPrice,
                            key: const Key('product_detail_original_price'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          product.formattedDiscountedPrice,
                          key: const Key('product_detail_selling_price'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Number of People Who Purchased + Rating & Stock Status
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${product.soldCount} people have bought this',
                          key: const Key('product_detail_sold_count'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: product.isInStock
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.isInStock
                                ? 'Stok: ${product.stock}'
                                : 'Stok Habis',
                            key: const Key('product_detail_stock_badge'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: product.isInStock
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Favorite / Wishlist Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('product_detail_wishlist_button'),
                  onTap: () => _handleToggleWishlist(product),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isWishlisted
                          ? const Color(0xFFFFF1F2)
                          : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isWishlisted
                            ? const Color(0xFFFECDD3)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 22,
                      color: isWishlisted
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Store Identity Section (Clickable Card -> Navigates to Store Detail Screen)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: const Key('product_detail_store_card'),
              onTap: () => _handleOpenStoreDetail(product, store),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Store Logo or Icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child:
                            store.logoUrl != null && store.logoUrl!.isNotEmpty
                            ? Image.network(
                                store.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              )
                            : const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Store Name & Identity Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  store.name,
                                  key: const Key('product_detail_store_name'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (store.address != null &&
                                    store.address!.trim().isNotEmpty)
                                ? store.address!.trim()
                                : (store.description != null &&
                                          store.description!.trim().isNotEmpty
                                      ? store.description!.trim()
                                      : 'Official Store · Kampung Batik Laweyan'),
                            key: const Key('product_detail_store_identity'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 4. Product Description Section ("Description of product")
          Text(
            'Description of product',
            key: const Key('product_detail_description_title'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            descriptionText,
            key: const Key('product_detail_description_text'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.65,
            ),
          ),

          const SizedBox(height: 28),

          // 5. Customer Reviews Section (Breakdown 5..1 Bintang, Filter Bintang, & Infinite Scroll)
          _buildReviewsSection(context, product),
        ],
      ),
    );
  }

  /// Bagian Ulasan Pelanggan (Customer Reviews):
  /// - Ringkasan nilai rata-rata + rincian jumlah bintang 5, 4, 3, 2, 1
  /// - Filter per bintang (Semua, ★5, ★4, ★3, ★2, ★1)
  /// - Daftar ulasan dengan Infinite Scroll Pagination
  Widget _buildReviewsSection(BuildContext context, ProductItem product) {
    final double avgRating = _ratingStats.totalCount > 0
        ? _ratingStats.averageRating
        : product.rating;
    final int totalReviews = _ratingStats.totalCount > 0
        ? _ratingStats.totalCount
        : product.reviewCount;

    return Column(
      key: const Key('product_detail_reviews_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bagian Ulasan
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Reviews',
              key: const Key('product_detail_reviews_title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalReviews Ulasan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kartu Ringkasan & Rincian Bintang 5 s/d 1
        Container(
          key: const Key('product_detail_rating_summary_card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            children: [
              // Kolom Kiri: Skor Rata-rata Besar
              SizedBox(
                width: 96,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < avgRating.round();
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 15,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews reviews',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 92,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: const Color(0xFFE2E8F0),
              ),

              // Kolom Kanan: Rincian Bintang 5, 4, 3, 2, 1 (Bisa diklik untuk filter)
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final int count = _ratingStats.countForStar(star);
                    final int pct = _ratingStats.percentageForStar(star);
                    final bool isSelected = _selectedReviewRatingFilter == star;

                    return InkWell(
                      key: Key('review_breakdown_row_$star'),
                      onTap: () => _handleSelectReviewRatingFilter(star),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            Text(
                              '$star',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (pct / 100.0).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 26,
                              child: Text(
                                '$count',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Deretan Chip Filter Bintang (Semua, ★ 5, ★ 4, ★ 3, ★ 2, ★ 1)
        SizedBox(
          key: const Key('product_detail_review_filter_bar'),
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Chip "Semua"
              _buildStarFilterChip(
                key: const Key('review_filter_all'),
                label: 'Semua ($totalReviews)',
                isSelected: _selectedReviewRatingFilter == null,
                onTap: () {
                  if (_selectedReviewRatingFilter != null) {
                    _handleSelectReviewRatingFilter(null);
                  }
                },
              ),
              const SizedBox(width: 8),
              // Chip Bintang 5 s/d 1
              ...[5, 4, 3, 2, 1].map((star) {
                final int count = _ratingStats.countForStar(star);
                final bool isSelected = _selectedReviewRatingFilter == star;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildStarFilterChip(
                    key: Key('review_filter_star_$star'),
                    label: '$star ($count)',
                    showStarIcon: true,
                    isSelected: isSelected,
                    onTap: () => _handleSelectReviewRatingFilter(star),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Daftar Ulasan Pelanggan (Paginated + Infinite Scroll)
        if (_isLoadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          )
        else if (_reviewsErrorMessage != null && _reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _reviewsErrorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _fetchProductReviews(page: 1, reset: true),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Muat Ulang Ulasan'),
                ),
              ],
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.rate_review_outlined,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedReviewRatingFilter != null
                      ? 'Belum ada ulasan dengan bintang $_selectedReviewRatingFilter.'
                      : 'Belum ada ulasan untuk produk ini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ..._reviews.map((review) => _buildReviewItemCard(review)),
              if (_isLoadingMoreReviews)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Memuat ulasan lainnya...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStarFilterChip({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool showStarIcon = false,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showStarIcon) ...[
              Icon(
                Icons.star_rounded,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItemCard(ProductReviewItem review) {
    final String initial = review.customerName.isNotEmpty
        ? review.customerName[0].toUpperCase()
        : 'U';
    final String dateText = _formatReviewDate(review.createdAt);

    return Container(
      key: Key('product_review_item_${review.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Pelanggan
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child:
                      (review.customerAvatarUrl != null &&
                          review.customerAvatarUrl!.isNotEmpty)
                      ? Image.network(
                          review.customerAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Nama Pelanggan & Tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),

              // Deretan Bintang (1..5)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 15,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!.trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(String? rawIso) {
    if (rawIso == null || rawIso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(rawIso.trim())?.toLocal();
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final m = months[(dt.month - 1).clamp(0, 11)];
    return '${dt.day} $m ${dt.year}';
  }

  /// 5. Bottom Action Bar: Tombol "Try On" (30%) dan "Add to Cart" (70%)
  Widget _buildBottomActionBar(BuildContext context, ProductItem product) {
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
      child: Row(
        children: [
          // Tombol Try On (30%)
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                key: const Key('product_detail_try_on_button'),
                onPressed: () => _showVirtualTryOnBottomSheet(context, product),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                  side: const BorderSide(color: AppColors.primary, width: 1.4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Try On',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Add to Cart (70%)
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('product_detail_add_to_cart_button'),
                onPressed: (!product.isInStock || _isAddingToCart)
                    ? null
                    : () => _showAddToCartBottomSheet(context, product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isAddingToCart
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        product.isInStock ? 'Add to Cart' : 'Out of Stock',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
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

  Widget _buildLargePlaceholder(ProductItem product, {double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            product.placeholderColor,
            product.placeholderColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(ProductItem product) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            product.placeholderColor,
            product.placeholderColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 22,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 52,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'Produk Tidak Ditemukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
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
              _errorMessage ?? 'Gagal memuat detail produk.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchProductAndStore(silent: false),
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
}

/// Dialog Preview Gambar Produk & Galeri yang dapat digeser (swipe) ke kiri dan kanan.
class _ProductGalleryPreviewDialog extends StatefulWidget {
  final ProductItem product;
  final List<String> images;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;

  const _ProductGalleryPreviewDialog({
    required this.product,
    required this.images,
    required this.initialIndex,
    required this.onIndexChanged,
  });

  @override
  State<_ProductGalleryPreviewDialog> createState() =>
      _ProductGalleryPreviewDialogState();
}

class _ProductGalleryPreviewDialogState
    extends State<_ProductGalleryPreviewDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  int get _itemCount => widget.images.isNotEmpty ? widget.images.length : 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _itemCount - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToIndex(int index) {
    final target = index.clamp(0, _itemCount - 1);
    if (target == _currentIndex) return;
    setState(() {
      _currentIndex = target;
    });
    widget.onIndexChanged(target);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar: Indikator (1 / N) & Tombol Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / $_itemCount',
                  key: const Key('product_preview_dialog_counter'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                key: const Key('product_preview_dialog_close'),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Area Gambar Utama Preview (Dapat digeser ke kanan / kiri & di-zoom)
          SizedBox(
            height: 360,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: PageView.builder(
                    key: const Key('product_preview_dialog_pageview'),
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _itemCount,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                      widget.onIndexChanged(index);
                    },
                    itemBuilder: (context, index) {
                      final imgUrl = widget.images.isNotEmpty
                          ? widget.images[index]
                          : widget.product.imageUrl;
                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: (imgUrl != null && imgUrl.isNotEmpty)
                            ? Image.network(
                                imgUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _buildDialogPlaceholder(),
                              )
                            : _buildDialogPlaceholder(),
                      );
                    },
                  ),
                ),

                // Tombol Geser Kiri
                if (_itemCount > 1 && _currentIndex > 0)
                  Positioned(
                    left: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('product_preview_dialog_prev'),
                        customBorder: const CircleBorder(),
                        onTap: () => _goToIndex(_currentIndex - 1),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF0F172A),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Tombol Geser Kanan
                if (_itemCount > 1 && _currentIndex < _itemCount - 1)
                  Positioned(
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('product_preview_dialog_next'),
                        customBorder: const CircleBorder(),
                        onTap: () => _goToIndex(_currentIndex + 1),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF0F172A),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Deretan Thumbnail Galeri di dalam Dialog Preview
          const SizedBox(height: 14),
          SizedBox(
            height: 58,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _itemCount,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imgUrl = widget.images.isNotEmpty
                    ? widget.images[index]
                    : widget.product.imageUrl;
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () => _goToIndex(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        width: isSelected ? 2.2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: (imgUrl != null && imgUrl.isNotEmpty)
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDialogPlaceholder(iconSize: 22),
                            )
                          : _buildDialogPlaceholder(iconSize: 22),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogPlaceholder({double iconSize = 68}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.product.placeholderColor,
            widget.product.placeholderColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Bottom Modal Sheet untuk memilih Varian Produk (Size, Color/Warna, dll. dari DB)
/// serta menentukan Kuantitas (Qty) saat tombol Add to Cart ditekan.
class _AddToCartBottomSheet extends StatefulWidget {
  final ProductItem product;
  final Future<bool> Function(int quantity, String? variantInfo)
  onConfirmAddToCart;

  const _AddToCartBottomSheet({
    required this.product,
    required this.onConfirmAddToCart,
  });

  @override
  State<_AddToCartBottomSheet> createState() => _AddToCartBottomSheetState();
}

class _AddToCartBottomSheetState extends State<_AddToCartBottomSheet> {
  late final Map<String, List<ProductVariantOption>> _groupedVariants;
  late final Map<String, String> _selectedByType;
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _groupedVariants = <String, List<ProductVariantOption>>{};
    for (final v in widget.product.variants) {
      final typeKey = v.type.trim().isNotEmpty ? v.type.trim() : 'Variant';
      final list = _groupedVariants.putIfAbsent(typeKey, () => []);
      if (!list.any((item) => item.value == v.value)) {
        list.add(v);
      }
    }

    _selectedByType = <String, String>{};
    for (final entry in _groupedVariants.entries) {
      if (entry.value.isNotEmpty) {
        _selectedByType[entry.key] = entry.value.first.value;
      }
    }
  }

  String? _buildVariantInfoString() {
    if (_selectedByType.isEmpty) return null;
    if (_selectedByType.length == 1) {
      final entry = _selectedByType.entries.first;
      return '${entry.key}: ${entry.value}';
    }
    return _selectedByType.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }

  void _decreaseQty() {
    if (_isSubmitting || _quantity <= 1) return;
    setState(() {
      _quantity -= 1;
    });
  }

  void _increaseQty() {
    if (_isSubmitting) return;
    if (_quantity >= widget.product.stock) {
      AppSnackBar.showInfo(
        context,
        'Maksimal pembelian sesuai stok tersedia (${widget.product.stock} pcs).',
      );
      return;
    }
    setState(() {
      _quantity += 1;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    // Pastikan setiap tipe varian sudah dipilih
    for (final typeKey in _groupedVariants.keys) {
      final selected = _selectedByType[typeKey];
      if (selected == null || selected.trim().isEmpty) {
        AppSnackBar.showError(
          context,
          'Silakan pilih varian $typeKey terlebih dahulu.',
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await widget.onConfirmAddToCart(
        _quantity,
        _buildVariantInfoString(),
      );
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool canDecrease = _quantity > 1 && !_isSubmitting;
    final bool canIncrease =
        product.isInStock && _quantity < product.stock && !_isSubmitting;
    final String? thumbUrl = product.allImages.isNotEmpty
        ? product.allImages.first
        : product.imageUrl;

    return Container(
      key: const Key('add_to_cart_bottom_sheet'),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            18,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Ringkasan Produk (Thumbnail, Nama, Harga, Stok, Tombol Close)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: (thumbUrl != null && thumbUrl.isNotEmpty)
                        ? Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildThumbFallback(product),
                          )
                        : _buildThumbFallback(product),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            product.formattedDiscountedPrice,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          if (product.hasDiscount)
                            Text(
                              product.formattedOriginalPrice,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok tersedia: ${product.stock} pcs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('add_to_cart_sheet_close_button'),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // 2. Pilihan Varian dari Database (misal: Size / Ukuran, Color / Warna, dll.)
            if (_groupedVariants.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._groupedVariants.entries.map((entry) {
                final String variantType = entry.key;
                final List<ProductVariantOption> options = entry.value;
                final String? selectedVal = _selectedByType[variantType];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            variantType,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (selectedVal != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· $selectedVal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options.map((opt) {
                          final bool isSelected = selectedVal == opt.value;
                          return GestureDetector(
                            key: Key(
                              'variant_option_${variantType}_${opt.value}',
                            ),
                            onTap: () {
                              setState(() {
                                _selectedByType[variantType] = opt.value;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: 1.3,
                                ),
                              ),
                              child: Text(
                                opt.value,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
            ],

            const SizedBox(height: 16),

            // 3. Pemilih Kuantitas (Quantity Selector: - 1 +) di dalam Bottom Sheet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Maks. ${product.stock} pcs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('product_detail_qty_decrease'),
                        onPressed: canDecrease ? _decreaseQty : null,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.remove_rounded,
                          size: 19,
                          color: canDecrease
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          key: const Key('product_detail_qty_value'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('product_detail_qty_increase'),
                        onPressed: canIncrease ? _increaseQty : null,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.add_rounded,
                          size: 19,
                          color: canIncrease
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 4. Tombol Konfirmasi "Add to Cart" di dalam Bottom Sheet
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('product_detail_confirm_add_to_cart_button'),
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Add to Cart · ${ProductItem.formatRupiah(product.discountedPrice * _quantity)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbFallback(ProductItem product) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            product.placeholderColor,
            product.placeholderColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 28,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Bottom Modal Sheet untuk Virtual Try-On Produk (Pilih Model DB atau Foto Galeri)
class _VirtualTryOnBottomSheet extends ConsumerStatefulWidget {
  final ProductItem product;

  const _VirtualTryOnBottomSheet({required this.product});

  @override
  ConsumerState<_VirtualTryOnBottomSheet> createState() =>
      _VirtualTryOnBottomSheetState();
}

class _VirtualTryOnBottomSheetState
    extends ConsumerState<_VirtualTryOnBottomSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  // 0 = Pilih Model, 1 = Foto Galeri, 2 = Model & Product (default, user_id NULL)
  int _activeTab = 0;
  bool get _useGalleryPhoto => _activeTab == 1;
  List<VirtualTryOnModelItem> _models = [];
  bool _isLoadingModels = true;
  String? _modelsError;
  VirtualTryOnModelItem? _selectedDbModel;
  String? _selectedGalleryPhotoPath;
  String _selectedGalleryGender = 'female';
  bool _isSubmitting = false;

  List<VirtualTryOnTaskItem> _defaultTryOns = [];
  bool _isLoadingDefaults = false;
  bool _defaultsLoaded = false;
  String? _defaultsError;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadDefaultTryOns() async {
    final productId = int.tryParse(widget.product.id) ?? 0;
    if (productId <= 0) return;
    setState(() {
      _isLoadingDefaults = true;
      _defaultsError = null;
    });
    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.getProductVirtualTryOns(productId);
      if (!mounted) return;
      setState(() {
        _defaultTryOns = list
            .where((e) => e.photoUrl != null || e.videoUrl != null)
            .toList();
        _isLoadingDefaults = false;
        _defaultsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDefaults = false;
        _defaultsError = 'Gagal memuat model & product.';
      });
    }
  }

  void _selectTab(int index) {
    setState(() => _activeTab = index);
    if (index == 2 && !_defaultsLoaded && !_isLoadingDefaults) {
      _loadDefaultTryOns();
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
      _modelsError = null;
    });
    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.getVirtualTryOnModels();
      if (!mounted) return;
      setState(() {
        _models = list;
        if (list.isNotEmpty) {
          _selectedDbModel = list.first;
        }
        _isLoadingModels = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingModels = false;
        _modelsError = 'Gagal memuat daftar model dari server.';
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() {
          _selectedGalleryPhotoPath = file.path;
          _activeTab = 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Gagal mengambil foto dari galeri.');
    }
  }

  Future<void> _handleStartTryOn() async {
    if (_isSubmitting) return;

    final productId = int.tryParse(widget.product.id) ?? 0;
    if (productId <= 0) {
      AppSnackBar.showError(context, 'ID produk tidak valid untuk Try-On.');
      return;
    }

    if (_useGalleryPhoto) {
      if (_selectedGalleryPhotoPath == null ||
          _selectedGalleryPhotoPath!.isEmpty) {
        AppSnackBar.showInfo(
          context,
          'Silakan pilih foto model dari galeri terlebih dahulu.',
        );
        return;
      }
    } else {
      if (_selectedDbModel == null) {
        AppSnackBar.showInfo(
          context,
          'Silakan pilih salah satu model terlebih dahulu.',
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final task = await repo.createVirtualTryOn(
        productId: productId,
        virtualTryOnModelId: _useGalleryPhoto ? null : _selectedDbModel?.id,
        galleryPhotoPath: _useGalleryPhoto ? _selectedGalleryPhotoPath : null,
        gender: _useGalleryPhoto
            ? _selectedGalleryGender
            : _selectedDbModel?.gender,
      );

      if (!mounted) return;
      Navigator.of(context).pop(task);
    } catch (e) {
      if (!mounted) return;
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      AppSnackBar.showError(
        context,
        rawMsg.isNotEmpty ? rawMsg : 'Gagal memulai Virtual Try-On. Silakan coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + bottomInset + 18,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Modal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual Try-On Produk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tabs: Pilih Model | Foto Galeri | Model & Product
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildSheetTab(0, Icons.people_alt_rounded, 'Pilih Model'),
                  _buildSheetTab(1, Icons.photo_library_rounded, 'Foto Galeri'),
                  _buildSheetTab(2, Icons.auto_awesome_mosaic_rounded, 'Model & Product'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Konten sesuai tab aktif
            if (_activeTab == 0)
              _buildDatabaseModelsSection()
            else if (_activeTab == 1)
              _buildGalleryUploadSection()
            else
              _buildDefaultTryOnsSection(),

            if (_activeTab != 2) ...[
            const SizedBox(height: 16),

            // Informasi Proses di Background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Proses generasi foto Try-On akan berjalan otomatis di background. Anda tetap dapat menjelajahi halaman sementara indikator progress melayang di pojok kanan bawah.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Tombol Mulai Try-On
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('product_detail_confirm_try_on_button'),
                onPressed: _isSubmitting ? null : _handleStartTryOn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Memulai Proses...' : 'Mulai Try On Sekarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetTab(int index, IconData icon, String label) {
    final bool active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab "Model & Product": hasil try-on default produk (user_id NULL)
  Widget _buildDefaultTryOnsSection() {
    if (_isLoadingDefaults || (!_defaultsLoaded && _defaultsError == null)) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_defaultsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _defaultsError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
            TextButton(
              onPressed: _loadDefaultTryOns,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    if (_defaultTryOns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              size: 34,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada model & product untuk produk ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _defaultTryOns
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DefaultTryOnMediaCard(item: item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDatabaseModelsSection() {
    if (_isLoadingModels) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_modelsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _modelsError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
            TextButton(
              onPressed: _loadModels,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    if (_models.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 34,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada model tersedia di database. Silakan gunakan tab Foto Galeri.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _models.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final model = _models[index];
          final isSelected = _selectedDbModel?.id == model.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedDbModel = model),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 128,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 2.2 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child: (model.photoUrl != null &&
                                  model.photoUrl!.isNotEmpty)
                              ? Image.network(
                                  model.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 40,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              model.genderLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGalleryUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedGalleryPhotoPath != null)
          Container(
            height: 175,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.5),
                  child: Image.file(
                    File(_selectedGalleryPhotoPath!),
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: Text(
                      'Ganti Foto',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: () => _pickPhoto(ImageSource.gallery),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1.3,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pilih Foto Model dari Galeri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gunakan foto berdiri menghadap depan dengan pencahayaan jelas (Maks. 5MB)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Dialog Preview Hasil Virtual Try-On ketika Selesai
class _VirtualTryOnResultDialog extends StatelessWidget {
  final ProductItem product;
  final String photoUrl;

  const _VirtualTryOnResultDialog({
    required this.product,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hasil Virtual Try-On',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.62,
                ),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu hasil try-on default (Model & Product) dengan toggle Foto / Video
class _DefaultTryOnMediaCard extends StatefulWidget {
  final VirtualTryOnTaskItem item;

  const _DefaultTryOnMediaCard({required this.item});

  @override
  State<_DefaultTryOnMediaCard> createState() => _DefaultTryOnMediaCardState();
}

class _DefaultTryOnMediaCardState extends State<_DefaultTryOnMediaCard> {
  bool _showVideo = false;
  VideoPlayerController? _videoController;
  bool _videoError = false;

  bool get _hasPhoto =>
      widget.item.photoUrl != null && widget.item.photoUrl!.isNotEmpty;
  bool get _hasVideo =>
      widget.item.videoUrl != null && widget.item.videoUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasPhoto && _hasVideo) {
      _showVideo = true;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    if (_videoController != null || !_hasVideo) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.item.videoUrl!),
    );
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  void _toggle(bool video) {
    setState(() => _showVideo = video);
    if (video) {
      _initVideo();
      _videoController?.play();
    } else {
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Widget _placeholder(IconData icon) => Container(
        color: const Color(0xFFF1F5F9),
        child: Center(
          child: Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
        ),
      );

  Widget _buildMedia() {
    if (_showVideo) {
      final c = _videoController;
      if (_videoError) return _placeholder(Icons.videocam_off_rounded);
      if (c == null || !c.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      }
      return GestureDetector(
        onTap: () {
          setState(() {
            c.value.isPlaying ? c.pause() : c.play();
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            if (!c.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
          ],
        ),
      );
    }

    if (!_hasPhoto) return _placeholder(Icons.image_not_supported_outlined);
    return Image.network(
      widget.item.photoUrl!,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
      errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_rounded),
    );
  }

  Widget _chip(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final genderLabel = item.gender == 'male'
        ? 'Pria'
        : item.gender == 'female'
        ? 'Wanita'
        : 'Unisex';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 320,
            color: const Color(0xFFF8FAFC),
            child: _buildMedia(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.modelName ?? 'Model Default',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        genderLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasPhoto)
                  _chip(
                    'Foto',
                    Icons.photo_rounded,
                    !_showVideo,
                    () => _toggle(false),
                  ),
                if (_hasPhoto && _hasVideo) const SizedBox(width: 6),
                if (_hasVideo)
                  _chip(
                    'Video',
                    Icons.videocam_rounded,
                    _showVideo,
                    () => _toggle(true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
