import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/cart/data/models/cart_item_model.dart';
import 'package:heritage_batik/features/cart/data/repositories/cart_repository.dart';
import 'package:heritage_batik/features/cart/presentation/viewmodels/cart_providers.dart';
import 'package:heritage_batik/features/home/data/datasources/home_remote_data_source.dart';
import 'package:heritage_batik/features/home/data/models/home_dummy_data.dart';
import 'package:heritage_batik/features/home/data/repositories/home_repository.dart';
import 'package:heritage_batik/features/home/presentation/viewmodels/home_providers.dart';
import 'package:heritage_batik/features/home/presentation/views/product_detail_view.dart';
import 'package:heritage_batik/features/store/data/datasources/store_remote_data_source.dart';
import 'package:heritage_batik/features/store/data/models/faq_model.dart';
import 'package:heritage_batik/features/store/data/models/payment_method_model.dart';
import 'package:heritage_batik/features/store/data/models/store_setting_model.dart';
import 'package:heritage_batik/features/store/presentation/viewmodels/store_providers.dart';
import 'package:heritage_batik/features/store/presentation/views/store_detail_view.dart';

class FakeProductDetailHomeRepository implements HomeRepository {
  final Map<String, ProductItem> productsById;

  FakeProductDetailHomeRepository({required this.productsById});

  @override
  Future<List<PromoBannerItem>> getBanners() async => HomeDummyData.banners;

  @override
  Future<List<ProductCategoryItem>> getCategories() async =>
      HomeDummyData.categories;

  @override
  Future<List<ProductItem>> getRecommendations() async =>
      productsById.values.toList();

  @override
  Future<List<ProductItem>> getBestSellers() async =>
      productsById.values.toList();

  @override
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
  }) async {
    final list = productsById.values.toList();
    return PaginatedProductsResult(
      items: list,
      hasMore: false,
      currentPage: 1,
      total: list.length,
    );
  }

  @override
  Future<ProductItem> getProductDetail(dynamic idOrSlug) async {
    final key = idOrSlug.toString();
    final matched = productsById[key];
    if (matched != null) return matched;
    throw Exception('Product not found');
  }

  @override
  Future<PaginatedProductReviewsResult> getProductReviews(
    dynamic idOrSlug, {
    int page = 1,
    int perPage = 10,
    int? rating,
  }) async {
    const allReviews = [
      ProductReviewItem(
        id: 1,
        customerName: 'Siti Rahmawati',
        rating: 5,
        comment: 'Kain batiknya sangat halus dan adem dipakai!',
        createdAt: '2026-10-30T10:00:00Z',
      ),
      ProductReviewItem(
        id: 2,
        customerName: 'Budi Santoso',
        rating: 4,
        comment: 'Motif Parang Kusumo sangat rapi.',
        createdAt: '2026-10-29T08:30:00Z',
      ),
    ];

    final filtered = rating == null
        ? allReviews
        : allReviews.where((r) => r.rating == rating).toList();

    return PaginatedProductReviewsResult(
      items: filtered,
      stats: const ProductRatingStats(
        averageRating: 4.5,
        totalCount: 2,
        starCounts: {5: 1, 4: 1, 3: 0, 2: 0, 1: 0},
        starPercentages: {5: 50, 4: 50, 3: 0, 2: 0, 1: 0},
      ),
      hasMore: false,
      currentPage: page,
      total: filtered.length,
    );
  }

  @override
  Future<List<VirtualTryOnModelItem>> getVirtualTryOnModels() async => const [];

  @override
  Future<VirtualTryOnTaskItem> createVirtualTryOn({
    required int productId,
    int? virtualTryOnModelId,
    String? galleryPhotoPath,
    String? gender,
    bool? generateVideo,
  }) async =>
      const VirtualTryOnTaskItem(
        id: 1,
        productId: 1,
        status: 'queued',
        progress: 10,
      );

  @override
  Future<VirtualTryOnTaskItem> getVirtualTryOnProgress(int tryOnId) async =>
      const VirtualTryOnTaskItem(
        id: 1,
        productId: 1,
        status: 'completed',
        progress: 100,
      );

  @override
  Future<VirtualTryOnTaskItem> retryVirtualTryOn(int tryOnId) async =>
      const VirtualTryOnTaskItem(
        id: 1,
        productId: 1,
        status: 'queued',
        progress: 10,
      );

  @override
  Future<List<VirtualTryOnTaskItem>> getUserVirtualTryOns({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async =>
      const [];

  @override
  Future<VirtualTryOnTaskItem> getVirtualTryOnDetail(int tryOnId) async =>
      const VirtualTryOnTaskItem(
        id: 1,
        productId: 1,
        status: 'completed',
        progress: 100,
      );

  @override
  Future<List<VirtualTryOnTaskItem>> getProductVirtualTryOns(int productId) async =>
      const [];
}

class FakeStoreRemoteDataSource implements StoreRemoteDataSource {
  final StoreSettingModel storeSetting;

  FakeStoreRemoteDataSource({required this.storeSetting});

  @override
  Future<bool> pingServer() async => true;

  @override
  Future<StoreSettingModel> getStoreSetting() async => storeSetting;

  @override
  Future<StoreSettingModel> getPrivacyPolicy() async => storeSetting;

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async => const [];

  @override
  Future<List<FaqModel>> getFaqs({String? category, String? search}) async =>
      const [];

  @override
  Future<List<String>> getFaqCategories() async => const [];
}

class FakeProductDetailCartRepository implements CartRepository {
  final List<CartItemModel> items = [];

  @override
  Future<CartResult> getCart() async {
    final totalQty = items.fold<int>(0, (sum, item) => sum + item.qty);
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    return CartResult(
      items: List.from(items),
      summary: CartSummaryModel(
        totalItems: items.length,
        totalQuantity: totalQty,
        totalWeight: items.fold<int>(0, (sum, item) => sum + item.totalWeight),
        subtotal: subtotal,
      ),
    );
  }

  @override
  Future<CartItemModel> addToCart(
    int productId,
    int quantity, {
    String? variantInfo,
  }) async {
    final existingIdx = items.indexWhere((i) => i.productId == productId);
    if (existingIdx != -1) {
      final current = items[existingIdx];
      final newQty = current.qty + quantity;
      final updated = current.copyWith(
        qty: newQty,
        total: current.productPrice * newQty,
      );
      items[existingIdx] = updated;
      return updated;
    }

    final created = CartItemModel(
      id: items.length + 1,
      productId: productId,
      productName: 'Kain Batik Tulis Sogan Parang',
      productPrice: 345000,
      qty: quantity,
      total: 345000.0 * quantity,
      stock: 5,
      weight: 350,
      totalWeight: 350 * quantity,
      variantInfo: variantInfo,
    );
    items.add(created);
    return created;
  }

  @override
  Future<CartItemModel> updateQuantity(int cartId, int qty) async {
    final idx = items.indexWhere((i) => i.id == cartId);
    final updated = items[idx].copyWith(qty: qty);
    items[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteItem(int cartId) async {
    items.removeWhere((i) => i.id == cartId);
    return true;
  }
}

void main() {
  const sampleStore = StoreSettingModel(
    id: 7,
    name: 'Galeri Batik Mahkota Laweyan',
    description: 'Pengrajin Batik Tulis & Cap Asli Kampung Batik Laweyan Solo.',
    address: 'Jl. Sidoluhur No. 18, Laweyan, Surakarta',
    phone: '0271-718899',
    whatsapp: '628123456789',
  );

  const sampleProduct = ProductItem(
    id: '101',
    name: 'Kain Batik Tulis Sogan Parang Kusumo',
    slug: 'kain-batik-tulis-sogan-parang-kusumo',
    description:
        'Batik tulis sogan asli Kampung Batik Laweyan menggunakan kain katun primisima halus yang adem dan nyaman dipakai.',
    category: 'Kain',
    discountedPrice: 345000,
    originalPrice: 450000,
    discountPercentage: 23,
    rating: 4.9,
    reviewCount: 42,
    soldCount: 142,
    variants: [
      ProductVariantOption(id: 1, type: 'Size', value: 'M'),
      ProductVariantOption(id: 2, type: 'Size', value: 'L'),
      ProductVariantOption(id: 3, type: 'Color', value: 'Sogan'),
      ProductVariantOption(id: 4, type: 'Color', value: 'Hitam'),
    ],
    placeholderColor: Color(0xFF8B5E3C),
    isFavorite: false,
    stock: 3,
    weight: 350,
    storeId: 7,
    store: sampleStore,
  );

  group('ProductDetailView & StoreDetailView Widget Tests', () {
    testWidgets(
      'Displays header, product details, discount, store card, description, quantity selector, and adds to cart',
      (tester) async {
        final fakeHomeRepo = FakeProductDetailHomeRepository(
          productsById: {'101': sampleProduct},
        );
        final fakeStoreDataSource = FakeStoreRemoteDataSource(
          storeSetting: sampleStore,
        );
        final fakeCartRepo = FakeProductDetailCartRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeRepositoryProvider.overrideWithValue(fakeHomeRepo),
              storeRemoteDataSourceProvider.overrideWithValue(
                fakeStoreDataSource,
              ),
              cartRepositoryProvider.overrideWithValue(fakeCartRepo),
            ],
            child: const MaterialApp(
              home: ProductDetailView(
                productId: '101',
                initialProduct: sampleProduct,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Header
        expect(find.text('Details product'), findsOneWidget);
        expect(
          find.byKey(const Key('product_detail_back_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('product_detail_cart_button')),
          findsOneWidget,
        );

        // 2. Product Information & Gallery Strip
        expect(
          find.byKey(const Key('product_detail_gallery_strip')),
          findsOneWidget,
        );
        expect(
          find.text('Kain Batik Tulis Sogan Parang Kusumo'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('product_detail_discount_badge')),
          findsOneWidget,
        );
        expect(find.text('-23%'), findsOneWidget);
        expect(find.text('Rp 450.000'), findsOneWidget);
        expect(find.text('Rp 345.000'), findsOneWidget);
        expect(find.text('142 people have bought this'), findsOneWidget);

        // 3. Wishlist toggle
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        await tester.tap(
          find.byKey(const Key('product_detail_wishlist_button')),
        );
        await tester.pump();
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

        // 4. Store Identity Section
        expect(
          find.byKey(const Key('product_detail_store_card')),
          findsOneWidget,
        );
        expect(find.text('Galeri Batik Mahkota Laweyan'), findsOneWidget);
        expect(
          find.text('Jl. Sidoluhur No. 18, Laweyan, Surakarta'),
          findsOneWidget,
        );

        // 5. Product Description & Customer Reviews (with Star Breakdown & Filter)
        expect(find.text('Description of product'), findsOneWidget);
        expect(
          find.textContaining('Batik tulis sogan asli Kampung Batik Laweyan'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('product_detail_reviews_section')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('product_detail_rating_summary_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('product_detail_review_filter_bar')),
          findsOneWidget,
        );
        expect(find.text('Siti Rahmawati'), findsOneWidget);
        expect(find.text('Budi Santoso'), findsOneWidget);

        // 6. Quantity Selector TIDAK tampil di halaman utama, melainkan muncul di Bottom Modal saat klik Add to Cart
        expect(find.byKey(const Key('product_detail_qty_value')), findsNothing);
        await tester.tap(
          find.byKey(const Key('product_detail_add_to_cart_button')),
        );
        await tester.pumpAndSettle();

        // Bottom Sheet muncul dengan pilihan varian (Size & Color) dan Quantity
        expect(
          find.byKey(const Key('add_to_cart_bottom_sheet')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('variant_option_Size_L')), findsOneWidget);
        expect(
          find.byKey(const Key('variant_option_Color_Hitam')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('variant_option_Size_L')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('variant_option_Color_Hitam')));
        await tester.pump();

        expect(
          find.byKey(const Key('product_detail_qty_value')),
          findsOneWidget,
        );
        expect(find.text('1'), findsOneWidget);

        await tester.tap(find.byKey(const Key('product_detail_qty_increase')));
        await tester.pump();
        expect(find.text('2'), findsOneWidget);

        await tester.tap(find.byKey(const Key('product_detail_qty_increase')));
        await tester.pump();
        expect(find.text('3'), findsOneWidget);

        // Decrease back to 2
        await tester.tap(find.byKey(const Key('product_detail_qty_decrease')));
        await tester.pump();
        expect(find.text('2'), findsOneWidget);

        // 7. Confirm Add to Cart di dalam Bottom Sheet
        await tester.tap(
          find.byKey(const Key('product_detail_confirm_add_to_cart_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('product_detail_cart_badge')),
          findsOneWidget,
        );
        expect(fakeCartRepo.items.first.qty, 2);
        expect(fakeCartRepo.items.first.variantInfo, 'Size: L, Color: Hitam');
      },
    );

    testWidgets(
      'StoreDetailView displays store profile, contact info, and store products',
      (tester) async {
        final fakeHomeRepo = FakeProductDetailHomeRepository(
          productsById: {'101': sampleProduct},
        );
        final fakeStoreDataSource = FakeStoreRemoteDataSource(
          storeSetting: sampleStore,
        );
        final fakeCartRepo = FakeProductDetailCartRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeRepositoryProvider.overrideWithValue(fakeHomeRepo),
              storeRemoteDataSourceProvider.overrideWithValue(
                fakeStoreDataSource,
              ),
              cartRepositoryProvider.overrideWithValue(fakeCartRepo),
            ],
            child: const MaterialApp(
              home: StoreDetailView(storeId: 7, initialStore: sampleStore),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Store Detail'), findsOneWidget);
        expect(find.text('Galeri Batik Mahkota Laweyan'), findsOneWidget);
        expect(find.text('Official Batik Store · ID #7'), findsOneWidget);
        expect(
          find.text('Jl. Sidoluhur No. 18, Laweyan, Surakarta'),
          findsOneWidget,
        );
        expect(
          find.text('Kain Batik Tulis Sogan Parang Kusumo'),
          findsOneWidget,
        );
      },
    );
  });
}
