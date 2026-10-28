import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../home/data/models/home_dummy_data.dart';
import '../datasources/search_remote_data_source.dart';
import '../models/product_filter_model.dart';

abstract class SearchRepository {
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int perPage = 12,
    ProductFilter? filter,
  });

  List<String> getSearchHistory();
  Future<void> saveSearchQuery(String query);
  Future<void> removeSearchQuery(String query);
  Future<void> clearSearchHistory();
}

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final ILocalStorageService localStorageService;

  static const int _maxHistoryCount = 20;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorageService,
  });

  @override
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int perPage = 12,
    ProductFilter? filter,
  }) async {
    final cleanQuery = query.trim();
    final activeFilter = filter ?? const ProductFilter();

    try {
      final result = await remoteDataSource.searchProducts(
        query: cleanQuery,
        page: page,
        perPage: perPage,
        sort: activeFilter.apiSortColumn,
        direction: activeFilter.apiSortDirection,
      );

      final filteredItems = result.items.where((p) => activeFilter.matches(p)).toList();
      final sortedItems = activeFilter.sortProducts(filteredItems);

      return SearchResult(
        items: sortedItems,
        total: activeFilter.isDefault ? result.total : sortedItems.length,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
      );
    } catch (e, stack) {
      AppLogger.w('Gagal mengambil hasil pencarian dari API: $e. Menggunakan fallback lokal.');
      AppLogger.d('Stack trace: $stack');

      // Fallback lokal jika offline/error
      final lower = cleanQuery.toLowerCase();
      final allFallback = [
        ...HomeDummyData.recommendations,
      ];
      final filtered = allFallback.where((p) {
        final matchesQuery = cleanQuery.isEmpty ||
            p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower);
        return matchesQuery && activeFilter.matches(p);
      }).toList();

      final sortedItems = activeFilter.sortProducts(filtered);

      return SearchResult(
        items: sortedItems,
        total: sortedItems.length,
        currentPage: 1,
        hasMore: false,
      );
    }
  }

  @override
  List<String> getSearchHistory() {
    return localStorageService.getSearchHistory();
  }

  @override
  Future<void> saveSearchQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final history = List<String>.from(getSearchHistory());

    // Hapus query yang sama jika sudah ada sebelumnya (case-insensitive)
    history.removeWhere((item) => item.toLowerCase() == cleanQuery.toLowerCase());

    // Letakkan di posisi paling atas (paling baru)
    history.insert(0, cleanQuery);

    // Batasi maksimum history
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    await localStorageService.saveSearchHistory(history);
    AppLogger.d('Riwayat pencarian tersimpan secara lokal: $cleanQuery');
  }

  @override
  Future<void> removeSearchQuery(String query) async {
    final history = List<String>.from(getSearchHistory());
    history.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
    await localStorageService.saveSearchHistory(history);
    AppLogger.d('Riwayat pencarian dihapus: $query');
  }

  @override
  Future<void> clearSearchHistory() async {
    await localStorageService.clearSearchHistory();
    AppLogger.d('Seluruh riwayat pencarian lokal telah dibersihkan');
  }
}
