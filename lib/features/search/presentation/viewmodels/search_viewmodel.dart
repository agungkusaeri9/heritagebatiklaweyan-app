import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/repositories/search_repository.dart';
import 'search_providers.dart';
import 'search_state.dart';

import '../../data/models/product_filter_model.dart';

class SearchViewModel extends Notifier<SearchState> {
  late final SearchRepository _repository;

  @override
  SearchState build() {
    _repository = ref.watch(searchRepositoryProvider);
    Future.microtask(() => loadHistory());
    return const SearchState();
  }

  /// Memuat riwayat pencarian dari penyimpanan lokal
  void loadHistory() {
    try {
      final history = _repository.getSearchHistory();
      state = state.copyWith(history: history);
    } catch (e, stack) {
      AppLogger.e('Gagal memuat riwayat pencarian', error: e, stackTrace: stack);
    }
  }

  /// Menangani perubahan input teks pencarian
  void onQueryChanged(String newQuery) {
    state = state.copyWith(query: newQuery);
    if (newQuery.trim().isEmpty && state.filter.isDefault) {
      // Saat teks dikosongkan dan filter default, reset hasil dan tampilkan riwayat pencarian
      state = state.copyWith(
        hasExecutedSearch: false,
        results: const [],
        totalResults: 0,
        errorMessage: null,
      );
      loadHistory();
    }
  }

  /// Menjalankan pencarian produk berdasarkan query dan filter aktif
  Future<void> search(String query, {ProductFilter? filter}) async {
    final cleanQuery = query.trim();
    final effectiveFilter = filter ?? state.filter;

    state = state.copyWith(
      status: SearchStatus.loading,
      query: cleanQuery,
      submittedQuery: cleanQuery,
      filter: effectiveFilter,
      hasExecutedSearch: true,
      errorMessage: null,
      currentPage: 1,
    );

    // Simpan ke riwayat pencarian lokal jika query tidak kosong
    if (cleanQuery.isNotEmpty) {
      await _repository.saveSearchQuery(cleanQuery);
    }
    final updatedHistory = _repository.getSearchHistory();

    try {
      final SearchResult result = await _repository.searchProducts(
        query: cleanQuery,
        page: 1,
        perPage: 12,
        filter: effectiveFilter,
      );

      state = state.copyWith(
        status: SearchStatus.success,
        results: result.items,
        totalResults: result.total,
        hasMore: result.hasMore,
        currentPage: result.currentPage,
        history: updatedHistory,
        errorMessage: null,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal mengeksekusi pencarian: $e', error: e, stackTrace: stack);
      state = state.copyWith(
        status: SearchStatus.error,
        history: updatedHistory,
        errorMessage: 'Terjadi kesalahan saat mencari produk. Silakan coba lagi.',
      );
    }
  }

  /// Menerapkan filter produk yang dipilih dari Filter Screen
  Future<void> applyFilter(ProductFilter newFilter) async {
    state = state.copyWith(filter: newFilter);
    final queryToUse = state.query.isNotEmpty ? state.query : state.submittedQuery;
    await search(queryToUse, filter: newFilter);
  }

  /// Mereset seluruh filter produk ke nilai default
  Future<void> resetFilter() async {
    const defaultFilter = ProductFilter();
    state = state.copyWith(filter: defaultFilter);
    if (state.hasExecutedSearch) {
      final queryToUse = state.query.isNotEmpty ? state.query : state.submittedQuery;
      await search(queryToUse, filter: defaultFilter);
    }
  }

  /// Infinite scroll: Memuat halaman hasil pencarian berikutnya
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading || !state.hasExecutedSearch) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.searchProducts(
        query: state.submittedQuery,
        page: nextPage,
        perPage: 12,
        filter: state.filter,
      );

      final existingIds = state.results.map((p) => p.id).toSet();
      final newUniqueItems = result.items.where((p) => !existingIds.contains(p.id)).toList();

      state = state.copyWith(
        isLoadingMore: false,
        results: [...state.results, ...newUniqueItems],
        hasMore: result.hasMore,
        currentPage: result.currentPage,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memuat halaman berikutnya untuk pencarian', error: e, stackTrace: stack);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Menghapus 1 item riwayat pencarian tertentu
  Future<void> removeHistoryItem(String queryItem) async {
    await _repository.removeSearchQuery(queryItem);
    final updatedHistory = _repository.getSearchHistory();
    state = state.copyWith(history: updatedHistory);
  }

  /// Menghapus seluruh riwayat pencarian
  Future<void> clearAllHistory() async {
    await _repository.clearSearchHistory();
    state = state.copyWith(history: const []);
  }

  /// Membersihkan input pencarian dan kembali ke riwayat
  void clearSearch() {
    state = state.copyWith(
      query: '',
      hasExecutedSearch: false,
      results: const [],
      totalResults: 0,
      errorMessage: null,
    );
    loadHistory();
  }
}
