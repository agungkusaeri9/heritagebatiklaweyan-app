import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../home/data/models/home_dummy_data.dart';
import '../../data/models/product_filter_model.dart';
import '../viewmodels/search_providers.dart';
import '../viewmodels/search_state.dart';
import '../widgets/search_history_section.dart';
import '../widgets/search_results_section.dart';

/// Halaman Pencarian Produk & Riwayat Pencarian Lokal
class SearchView extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchView({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFocusNode = FocusNode();
    _scrollController.addListener(_onScroll);

    // Jika ada query awal dari navigasi, jalankan pencarian langsung
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchViewModelProvider.notifier).search(widget.initialQuery!);
      });
    } else {
      // Fokuskan input saat pertama kali masuk ke Search Screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // Trigger infinite scroll jika mendekati 200px sebelum bawah
      if (currentScroll >= maxScroll - 200) {
        ref.read(searchViewModelProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Menangani aksi penambahan produk ke keranjang belanja
  Future<void> _handleAddToCart(ProductItem product) async {
    final productId = int.tryParse(product.id) ?? 0;
    if (productId <= 0) {
      AppSnackBar.showError(context, 'ID produk tidak valid.');
      return;
    }

    final success = await ref.read(cartViewModelProvider.notifier).addToCart(
      productId,
      quantity: 1,
      onError: (message) {
        if (!mounted) return;
        AppSnackBar.showError(context, message);
      },
    );

    if (success && mounted) {
      AppSnackBar.showSuccess(
        context,
        '${product.name} berhasil ditambahkan ke keranjang.',
      );
    }
  }

  void _submitSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _searchFocusNode.unfocus();
    ref.read(searchViewModelProvider.notifier).search(clean);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Header: Back Button, Input TextField, Clear Button & Filter Button
            _buildSearchHeader(searchState),

            const Divider(
              color: Color(0xFFF1F5F9),
              height: 1,
              thickness: 1,
            ),

            // 2. Konten Utama: Riwayat Pencarian vs Hasil Pencarian Produk
            Expanded(
              child: searchState.showHistory
                  ? SearchHistorySection(
                      history: searchState.history,
                      onSelect: (selectedQuery) {
                        _searchController.text = selectedQuery;
                        _submitSearch(selectedQuery);
                      },
                      onDelete: (item) {
                        ref.read(searchViewModelProvider.notifier).removeHistoryItem(item);
                      },
                      onClearAll: () {
                        ref.read(searchViewModelProvider.notifier).clearAllHistory();
                      },
                    )
                  : SearchResultsSection(
                      query: searchState.submittedQuery,
                      products: searchState.results,
                      totalCount: searchState.totalResults,
                      isLoading: searchState.isLoading,
                      isLoadingMore: searchState.isLoadingMore,
                      hasMore: searchState.hasMore,
                      errorMessage: searchState.errorMessage,
                      scrollController: _scrollController,
                      onRetry: () => _submitSearch(_searchController.text),
                      onProductTap: (product) {
                        context.push('/product/${product.id}');
                      },
                      onAddToCart: _handleAddToCart,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header Pencarian
  Widget _buildSearchHeader(SearchState searchState) {
    final hasText = _searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 16, top: 10, bottom: 10),
      child: Row(
        children: [
          // Tombol Kembali
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Kolom Input Pencarian
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                onChanged: (value) {
                  setState(() {});
                  ref.read(searchViewModelProvider.notifier).onQueryChanged(value);
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search here ...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  suffixIcon: hasText
                      ? IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref.read(searchViewModelProvider.notifier).clearSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol Filter
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await context.push<ProductFilter?>(
                      '/filter',
                      extra: searchState.filter,
                    );
                    if (result != null) {
                      ref
                          .read(searchViewModelProvider.notifier)
                          .applyFilter(result);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              if (searchState.activeFilterCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${searchState.activeFilterCount}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
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
}
