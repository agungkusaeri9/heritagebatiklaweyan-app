import '../../data/models/home_dummy_data.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState {
  final HomeStatus status;
  final List<PromoBannerItem> banners;
  final List<ProductCategoryItem> categories;
  final String selectedCategoryId;
  final String? selectedCategorySlug;
  final List<ProductItem> recommendations;
  final List<ProductItem> bestSellers;
  final List<ProductItem> otherProducts;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMoreOtherProducts;
  final int currentOtherPage;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.categories = const [],
    this.selectedCategoryId = 'all',
    this.selectedCategorySlug,
    this.recommendations = const [],
    this.bestSellers = const [],
    this.otherProducts = const [],
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMoreOtherProducts = true,
    this.currentOtherPage = 1,
    this.errorMessage,
  });

  bool get isLoading => status == HomeStatus.loading;

  HomeState copyWith({
    HomeStatus? status,
    List<PromoBannerItem>? banners,
    List<ProductCategoryItem>? categories,
    String? selectedCategoryId,
    String? selectedCategorySlug,
    bool clearCategorySlug = false,
    List<ProductItem>? recommendations,
    List<ProductItem>? bestSellers,
    List<ProductItem>? otherProducts,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMoreOtherProducts,
    int? currentOtherPage,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategorySlug: clearCategorySlug ? null : (selectedCategorySlug ?? this.selectedCategorySlug),
      recommendations: recommendations ?? this.recommendations,
      bestSellers: bestSellers ?? this.bestSellers,
      otherProducts: otherProducts ?? this.otherProducts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMoreOtherProducts: hasMoreOtherProducts ?? this.hasMoreOtherProducts,
      currentOtherPage: currentOtherPage ?? this.currentOtherPage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
