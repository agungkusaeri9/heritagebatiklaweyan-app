import '../../../home/data/models/home_dummy_data.dart';
import '../../data/models/product_filter_model.dart';

enum SearchStatus { initial, loading, success, error }

class SearchState {
  final SearchStatus status;
  final String query;
  final String submittedQuery;
  final List<String> history;
  final List<ProductItem> results;
  final int totalResults;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
  final bool hasExecutedSearch;
  final ProductFilter filter;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.submittedQuery = '',
    this.history = const [],
    this.results = const [],
    this.totalResults = 0,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.errorMessage,
    this.hasExecutedSearch = false,
    this.filter = const ProductFilter(),
  });

  bool get isLoading => status == SearchStatus.loading;
  bool get isSuccess => status == SearchStatus.success;
  bool get isError => status == SearchStatus.error;
  bool get showHistory => !hasExecutedSearch;
  int get activeFilterCount => filter.activeFilterCount;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    String? submittedQuery,
    List<String>? history,
    List<ProductItem>? results,
    int? totalResults,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    bool? hasExecutedSearch,
    ProductFilter? filter,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      history: history ?? this.history,
      results: results ?? this.results,
      totalResults: totalResults ?? this.totalResults,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
      hasExecutedSearch: hasExecutedSearch ?? this.hasExecutedSearch,
      filter: filter ?? this.filter,
    );
  }
}
