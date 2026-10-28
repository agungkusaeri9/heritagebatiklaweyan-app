import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/local_storage_service.dart';
import 'package:heritage_batik/features/home/data/models/home_dummy_data.dart';
import 'package:heritage_batik/features/search/data/datasources/search_remote_data_source.dart';
import 'package:heritage_batik/features/search/data/models/product_filter_model.dart';
import 'package:heritage_batik/features/search/data/repositories/search_repository.dart';
import 'package:heritage_batik/features/search/presentation/viewmodels/search_providers.dart';
import 'package:heritage_batik/features/search/presentation/viewmodels/search_viewmodel.dart';
import 'package:heritage_batik/features/search/presentation/views/filter_view.dart';

class MockLocalStorageService implements ILocalStorageService {
  final Map<String, dynamic> _data = {};

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = List<String>.from(value);
    return true;
  }

  @override
  List<String> getSearchHistory() {
    return getStringList('PREF_SEARCH_HISTORY') ?? <String>[];
  }

  @override
  Future<void> saveSearchHistory(List<String> history) async {
    await setStringList('PREF_SEARCH_HISTORY', history);
  }

  @override
  Future<void> clearSearchHistory() async {
    _data.remove('PREF_SEARCH_HISTORY');
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  String? getLastUsername() => _data['username'] as String?;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool hasCompletedOnboarding() => false;

  @override
  bool isDarkMode() => false;

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<void> saveLastUsername(String username) async {}

  @override
  Future<bool> setBool(String key, bool value) async => true;

  @override
  Future<void> setDarkMode(bool isDark) async {}

  @override
  Future<bool> setInt(String key, int value) async => true;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}

  @override
  Future<bool> setString(String key, String value) async => true;
}

class FakeSearchRemoteDataSource implements SearchRemoteDataSource {
  @override
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int perPage = 12,
    String? sort,
    String? direction,
  }) async {
    return const SearchResult(
      items: [],
      total: 0,
      currentPage: 1,
      hasMore: false,
    );
  }
}

void main() {
  group('ProductFilter Model Unit Tests', () {
    test('Default ProductFilter has 0 active filters and isDefault is true', () {
      const filter = ProductFilter();
      expect(filter.gender, GenderFilter.all);
      expect(filter.sortBy, SortByFilter.mostRecent);
      expect(filter.minPrice, ProductFilter.defaultMinPrice);
      expect(filter.maxPrice, ProductFilter.defaultMaxPrice);
      expect(filter.rating, RatingFilter.all);
      expect(filter.activeFilterCount, 0);
      expect(filter.isDefault, isTrue);
    });

    test('activeFilterCount correctly reflects individual and combined filters', () {
      // 1. Gender filter active
      var filter = const ProductFilter(gender: GenderFilter.men);
      expect(filter.activeFilterCount, 1);
      expect(filter.isDefault, isFalse);

      // 2. Add Sort By
      filter = filter.copyWith(sortBy: SortByFilter.priceLowToHigh);
      expect(filter.activeFilterCount, 2);

      // 3. Add Min Price change
      filter = filter.copyWith(minPrice: 100000);
      expect(filter.activeFilterCount, 3);

      // 4. Add Rating filter
      filter = filter.copyWith(rating: RatingFilter.fourPointFiveAndAbove);
      expect(filter.activeFilterCount, 4);

      // 5. Reset via copyWith
      final resetFilter = filter.copyWith(
        gender: GenderFilter.all,
        sortBy: SortByFilter.mostRecent,
        minPrice: ProductFilter.defaultMinPrice,
        maxPrice: ProductFilter.defaultMaxPrice,
        rating: RatingFilter.all,
      );
      expect(resetFilter.activeFilterCount, 0);
      expect(resetFilter.isDefault, isTrue);
    });

    test('apiSortColumn and apiSortDirection map properly for backend compatibility', () {
      const mostRecent = ProductFilter(sortBy: SortByFilter.mostRecent);
      expect(mostRecent.apiSortColumn, 'created_at');
      expect(mostRecent.apiSortDirection, 'desc');

      const lowToHigh = ProductFilter(sortBy: SortByFilter.priceLowToHigh);
      expect(lowToHigh.apiSortColumn, 'price');
      expect(lowToHigh.apiSortDirection, 'asc');

      const highToLow = ProductFilter(sortBy: SortByFilter.priceHighToLow);
      expect(highToLow.apiSortColumn, 'price');
      expect(highToLow.apiSortDirection, 'desc');

      const popular = ProductFilter(sortBy: SortByFilter.popular);
      expect(popular.apiSortColumn, 'created_at');
      expect(popular.apiSortDirection, 'desc');
    });

    test('matches() accurately filters products by price range', () {
      const product = ProductItem(
        id: '1',
        name: 'Kain Batik Tulis Solo',
        category: 'Kain',
        discountedPrice: 200000,
        originalPrice: 250000,
        discountPercentage: 20,
        placeholderColor: Color(0xFF8B5E3C),
        rating: 4.8,
        soldCount: 50,
      );

      const inRangeFilter = ProductFilter(minPrice: 100000, maxPrice: 300000);
      expect(inRangeFilter.matches(product), isTrue);

      const tooHighMin = ProductFilter(minPrice: 250000, maxPrice: 500000);
      expect(tooHighMin.matches(product), isFalse);

      const tooLowMax = ProductFilter(minPrice: 50000, maxPrice: 150000);
      expect(tooLowMax.matches(product), isFalse);
    });

    test('matches() accurately filters products by gender', () {
      const menProduct = ProductItem(
        id: '1',
        name: 'Kemeja Batik Pria Parang',
        category: 'Pria',
        discountedPrice: 150000,
        originalPrice: 200000,
        discountPercentage: 25,
        placeholderColor: Color(0xFF8B5E3C),
        rating: 4.8,
        soldCount: 20,
      );

      const womenProduct = ProductItem(
        id: '2',
        name: 'Tunik Batik Wanita Floral',
        category: 'Tunik',
        discountedPrice: 180000,
        originalPrice: 220000,
        discountPercentage: 18,
        placeholderColor: Color(0xFF8B5E3C),
        rating: 4.9,
        soldCount: 30,
      );

      const menFilter = ProductFilter(gender: GenderFilter.men);
      expect(menFilter.matches(menProduct), isTrue);
      expect(menFilter.matches(womenProduct), isFalse);

      const womenFilter = ProductFilter(gender: GenderFilter.women);
      expect(womenFilter.matches(menProduct), isFalse);
      expect(womenFilter.matches(womenProduct), isTrue);
    });

    test('matches() accurately filters products by rating', () {
      const highRated = ProductItem(
        id: '1',
        name: 'Batik Premium',
        category: 'Kain',
        discountedPrice: 100000,
        originalPrice: 100000,
        discountPercentage: 0,
        placeholderColor: Color(0xFF8B5E3C),
        rating: 4.7,
        soldCount: 100,
      );

      const lowerRated = ProductItem(
        id: '2',
        name: 'Batik Standar',
        category: 'Kain',
        discountedPrice: 100000,
        originalPrice: 100000,
        discountPercentage: 0,
        placeholderColor: Color(0xFF8B5E3C),
        rating: 3.2,
        soldCount: 10,
      );

      const fourPointFiveFilter = ProductFilter(rating: RatingFilter.fourPointFiveAndAbove);
      expect(fourPointFiveFilter.matches(highRated), isTrue);
      expect(fourPointFiveFilter.matches(lowerRated), isFalse);

      const threeToThreePointFiveFilter = ProductFilter(rating: RatingFilter.threeToThreePointFive);
      expect(threeToThreePointFiveFilter.matches(highRated), isFalse);
      expect(threeToThreePointFiveFilter.matches(lowerRated), isTrue);
    });

    test('sortProducts() orders products properly', () {
      final List<ProductItem> items = [
        const ProductItem(
          id: '1',
          name: 'Produk B',
          category: 'Kain',
          discountedPrice: 300000,
          originalPrice: 300000,
          discountPercentage: 0,
          placeholderColor: Color(0xFF8B5E3C),
        rating: 4.5,
          soldCount: 10,
        ),
        const ProductItem(
          id: '2',
          name: 'Produk A',
          category: 'Kain',
          discountedPrice: 100000,
          originalPrice: 100000,
          discountPercentage: 0,
          placeholderColor: Color(0xFF8B5E3C),
        rating: 4.9,
          soldCount: 80,
        ),
      ];

      const lowToHigh = ProductFilter(sortBy: SortByFilter.priceLowToHigh);
      final sortedAsc = lowToHigh.sortProducts(items);
      expect(sortedAsc.first.discountedPrice, 100000);
      expect(sortedAsc.last.discountedPrice, 300000);

      const highToLow = ProductFilter(sortBy: SortByFilter.priceHighToLow);
      final sortedDesc = highToLow.sortProducts(items);
      expect(sortedDesc.first.discountedPrice, 300000);
      expect(sortedDesc.last.discountedPrice, 100000);

      const popular = ProductFilter(sortBy: SortByFilter.popular);
      final sortedPop = popular.sortProducts(items);
      expect(sortedPop.first.soldCount, 80);
      expect(sortedPop.last.soldCount, 10);
    });
  });

  group('SearchViewModel ProductFilter Integration Tests', () {
    late ProviderContainer container;
    late SearchViewModel viewModel;

    setUp(() {
      final repository = SearchRepositoryImpl(
        remoteDataSource: FakeSearchRemoteDataSource(),
        localStorageService: MockLocalStorageService(),
      );
      container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(repository),
        ],
      );
      viewModel = container.read(searchViewModelProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial filter in SearchViewModel is default with 0 active filter count', () {
      expect(viewModel.state.filter.isDefault, isTrue);
      expect(viewModel.state.activeFilterCount, 0);
    });

    test('applyFilter updates filter in state and calculates activeFilterCount', () async {
      const customFilter = ProductFilter(
        gender: GenderFilter.men,
        sortBy: SortByFilter.priceLowToHigh,
      );

      await viewModel.applyFilter(customFilter);

      expect(viewModel.state.filter.gender, GenderFilter.men);
      expect(viewModel.state.filter.sortBy, SortByFilter.priceLowToHigh);
      expect(viewModel.state.activeFilterCount, 2);
    });

    test('resetFilter restores filter to default with 0 active filter count', () async {
      const customFilter = ProductFilter(
        gender: GenderFilter.women,
        rating: RatingFilter.fourPointFiveAndAbove,
      );

      await viewModel.applyFilter(customFilter);
      expect(viewModel.state.activeFilterCount, 2);

      await viewModel.resetFilter();
      expect(viewModel.state.filter.isDefault, isTrue);
      expect(viewModel.state.activeFilterCount, 0);
    });
  });

  group('FilterView Widget Tests', () {
    testWidgets('FilterView displays all filter sections and responds to chip taps', (tester) async {
      ProductFilter? returnedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<ProductFilter>(
                    MaterialPageRoute(
                      builder: (_) => const FilterView(),
                    ),
                  );
                  returnedFilter = result;
                },
                child: const Text('Open Filter'),
              );
            },
          ),
        ),
      );

      // Open filter screen
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Check titles
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Sort By'), findsOneWidget);
      expect(find.text('Pricing Range'), findsOneWidget);
      expect(find.text('Reviews / Rating'), findsOneWidget);

      // Check chips exist
      expect(find.text('Men'), findsOneWidget);
      expect(find.text('Women'), findsOneWidget);
      expect(find.text('Price: Low to High'), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
      expect(find.text('4.5 and above'), findsOneWidget);

      // Tap 'Men'
      await tester.tap(find.text('Men'));
      await tester.pumpAndSettle();

      // Tap 'Apply'
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(returnedFilter, isNotNull);
      expect(returnedFilter!.gender, GenderFilter.men);
      expect(returnedFilter!.activeFilterCount, 1);
    });

    testWidgets('FilterView Reset Filter button restores selections', (tester) async {
      ProductFilter? returnedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<ProductFilter>(
                    MaterialPageRoute(
                      builder: (_) => const FilterView(
                        initialFilter: ProductFilter(gender: GenderFilter.women),
                      ),
                    ),
                  );
                  returnedFilter = result;
                },
                child: const Text('Open Filter With Women'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Filter With Women'));
      await tester.pumpAndSettle();

      // Tap 'Reset Filter' button
      await tester.tap(find.text('Reset Filter'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(returnedFilter, isNotNull);
      expect(returnedFilter!.isDefault, isTrue);
      expect(returnedFilter!.activeFilterCount, 0);
    });
  });
}
