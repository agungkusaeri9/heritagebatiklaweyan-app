import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/local_storage_service.dart';
import 'package:heritage_batik/features/cart/presentation/viewmodels/cart_providers.dart';
import 'package:heritage_batik/features/home/data/datasources/home_remote_data_source.dart';
import 'package:heritage_batik/features/home/data/models/home_dummy_data.dart';
import 'package:heritage_batik/features/home/data/repositories/home_repository.dart';
import 'package:heritage_batik/features/home/presentation/viewmodels/home_providers.dart';
import 'package:heritage_batik/features/home/presentation/views/category_list_view.dart';
import 'package:heritage_batik/features/home/presentation/views/category_products_view.dart';
import 'package:heritage_batik/features/home/presentation/widgets/category_section.dart';

class MockHomeRepository implements HomeRepository {
  final List<ProductCategoryItem> categories;
  final List<ProductItem> products;

  MockHomeRepository({
    List<ProductCategoryItem>? categories,
    List<ProductItem>? products,
  })  : categories = categories ?? HomeDummyData.categories,
        products = products ?? HomeDummyData.recommendations;

  @override
  Future<List<PromoBannerItem>> getBanners() async => HomeDummyData.banners;

  @override
  Future<List<ProductCategoryItem>> getCategories() async => categories;

  @override
  Future<List<ProductItem>> getRecommendations() async => products;

  @override
  Future<List<ProductItem>> getBestSellers() async => products;

  @override
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
  }) async {
    final filtered = categorySlug != null && categorySlug.isNotEmpty && categorySlug != 'all'
        ? products.where((p) => p.category.toLowerCase().contains(categorySlug.toLowerCase())).toList()
        : products;

    return PaginatedProductsResult(
      items: filtered,
      hasMore: false,
      currentPage: page,
      total: filtered.length,
    );
  }
}

class MockLocalStorageService implements ILocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Category Navigation & Screens Tests', () {
    test('ProductCategoryItem fromJson parses description and totalItems correctly', () {
      final json = {
        'id': 3,
        'name': 'Kemeja Pria Formal',
        'slug': 'kemeja-pria-formal',
        'description': 'Kemeja batik pria lengan panjang dan pendek',
        'image_url': 'http://127.0.0.1:8000/storage/categories/kemeja.jpg',
        'total_items': 12,
        'is_active': true,
      };

      final item = ProductCategoryItem.fromJson(json);

      expect(item.id, '3');
      expect(item.name, 'Kemeja Pria Formal');
      expect(item.slug, 'kemeja-pria-formal');
      expect(item.description, 'Kemeja batik pria lengan panjang dan pendek');
      expect(item.totalItems, 12);
      expect(item.imageUrl, isNotNull);
    });

    testWidgets('CategorySection triggers onCategorySelected and onSeeAllTap', (tester) async {
      ProductCategoryItem? selectedCategory;
      bool seeAllTapped = false;

      final testCategories = [
        const ProductCategoryItem(
          id: '1',
          name: 'Batik Tulis',
          slug: 'batik-tulis',
        ),
        const ProductCategoryItem(
          id: '2',
          name: 'Batik Cap',
          slug: 'batik-cap',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySection(
              categories: testCategories,
              onCategorySelected: (cat) {
                selectedCategory = cat;
              },
              onSeeAllTap: () {
                seeAllTapped = true;
              },
            ),
          ),
        ),
      );

      // Verify header rendered
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      // Tap See All
      await tester.tap(find.text('See All'));
      await tester.pump();
      expect(seeAllTapped, isTrue);

      // Tap Category item "Batik Tulis"
      expect(find.text('Batik Tulis'), findsOneWidget);
      await tester.tap(find.text('Batik Tulis'));
      await tester.pump();
      expect(selectedCategory?.name, 'Batik Tulis');
    });

    testWidgets('CategoryListView displays categories and filters via search', (tester) async {
      final mockRepo = MockHomeRepository(
        categories: [
          const ProductCategoryItem(
            id: '1',
            name: 'Batik Tulis',
            slug: 'batik-tulis',
            description: 'Koleksi tulis nusantara',
            totalItems: 5,
          ),
          const ProductCategoryItem(
            id: '2',
            name: 'Dress Modern',
            slug: 'dress-modern',
            description: 'Dress batik wanita cantik',
            totalItems: 8,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeRepositoryProvider.overrideWithValue(mockRepo),
            cartItemCountProvider.overrideWithValue(2),
          ],
          child: const MaterialApp(
            home: CategoryListView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify categories listed
      expect(find.text('Kategori Batik'), findsOneWidget);
      expect(find.text('Batik Tulis'), findsOneWidget);
      expect(find.text('Dress Modern'), findsOneWidget);
      expect(find.text('5 Produk'), findsOneWidget);
      expect(find.text('8 Produk'), findsOneWidget);

      // Type in search box: 'Dress'
      await tester.enterText(find.byType(TextField), 'Dress');
      await tester.pumpAndSettle();

      // Should only show Dress Modern
      expect(find.text('Dress Modern'), findsOneWidget);
      expect(find.text('Batik Tulis'), findsNothing);

      // Search non-existent
      await tester.enterText(find.byType(TextField), 'NonExistentCategoryXYZ');
      await tester.pumpAndSettle();

      expect(find.text('Kategori Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Reset Pencarian'), findsOneWidget);

      // Reset
      await tester.tap(find.text('Reset Pencarian'));
      await tester.pumpAndSettle();

      expect(find.text('Batik Tulis'), findsOneWidget);
      expect(find.text('Dress Modern'), findsOneWidget);
    });

    testWidgets('CategoryProductsView displays category banner and products', (tester) async {
      const category = ProductCategoryItem(
        id: '2',
        name: 'Sarung Batik',
        slug: 'sarung',
        description: 'Sarung primisima nyaman',
        totalItems: 1,
      );

      final sampleProduct = ProductItem(
        id: '101',
        name: 'Sarung Batik Klasik Solo',
        category: 'Sarung',
        discountedPrice: 150000,
        originalPrice: 150000,
        discountPercentage: 0,
        rating: 4.8,
        soldCount: 40,
        placeholderColor: const Color(0xFF704F38),
      );

      final mockRepo = MockHomeRepository(products: [sampleProduct]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeRepositoryProvider.overrideWithValue(mockRepo),
            cartItemCountProvider.overrideWithValue(0),
          ],
          child: const MaterialApp(
            home: CategoryProductsView(category: category),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header AppBar title
      expect(find.text('Sarung Batik'), findsWidgets);
      // Banner description
      expect(find.text('Sarung primisima nyaman'), findsOneWidget);
      // Filter & Sort buttons
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Terbaru'), findsOneWidget);
      expect(find.text('Terpopuler'), findsOneWidget);

      // Product card
      expect(find.text('Sarung Batik Klasik Solo'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsOneWidget);
    });
  });
}
