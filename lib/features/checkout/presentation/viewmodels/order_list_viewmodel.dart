import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/models/checkout_result_model.dart';
import '../../data/models/order_pagination_model.dart';
import 'checkout_providers.dart';
import 'order_list_state.dart';

class OrderListViewModel extends Notifier<OrderListState> {
  static const int _perPage = 10;

  @override
  OrderListState build() {
    Future.microtask(() => initOrders());
    return const OrderListState();
  }

  /// Inisialisasi data untuk tab aktif jika belum pernah dimuat
  Future<void> initOrders({bool forceRefresh = false}) async {
    final currentTab = state.selectedTab;
    final tabData = state.tabDataFor(currentTab);
    if (!forceRefresh && (tabData.hasLoaded || tabData.isLoading)) {
      return;
    }
    await fetchOrdersForTab(
      currentTab,
      reset: true,
      forceRefresh: forceRefresh,
    );
  }

  /// Berpindah tab antara Active, Completed, dan Cancelled
  Future<void> selectTab(OrderTabStatus tab) async {
    if (state.selectedTab != tab) {
      state = state.copyWith(selectedTab: tab);
    }

    final tabData = state.tabDataFor(tab);
    if (!tabData.hasLoaded && !tabData.isLoading) {
      await fetchOrdersForTab(tab, reset: true);
    }
  }

  /// Mengambil daftar pesanan dari backend sesuai filter status tab
  Future<void> fetchOrdersForTab(
    OrderTabStatus tab, {
    bool reset = true,
    bool forceRefresh = false,
  }) async {
    final existingTabData = state.tabDataFor(tab);

    // Cegah duplikasi request yang sedang berjalan
    if (!forceRefresh) {
      if (reset && existingTabData.isLoading) return;
      if (!reset && (existingTabData.isLoading || existingTabData.isLoadingMore)) {
        return;
      }
    }

    final int targetPage = reset ? 1 : existingTabData.currentPage + 1;

    _updateTabData(
      tab,
      existingTabData.copyWith(
        isLoading: reset,
        isLoadingMore: !reset,
        clearError: true,
      ),
    );

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final search = state.searchQuery.trim().isNotEmpty
          ? state.searchQuery.trim()
          : null;

      final statuses = tab.backendStatuses;
      late final PaginatedOrdersResult combinedResult;

      if (statuses.length == 1) {
        combinedResult = await repo.getOrders(
          status: statuses.first,
          search: search,
          page: targetPage,
          perPage: _perPage,
          forceRefresh: forceRefresh && targetPage == 1,
        );
      } else {
        // Tab Active mengambil status 'processing' dan 'pending' menggunakan filter status backend
        final results = await Future.wait(
          statuses.map(
            (st) => repo.getOrders(
              status: st,
              search: search,
              page: targetPage,
              perPage: _perPage,
              forceRefresh: forceRefresh && targetPage == 1,
            ),
          ),
        );

        final mergedMap = <String, CheckoutResultModel>{};
        int sumTotal = 0;
        bool anyHasMore = false;
        int maxLastPage = 1;

        for (final res in results) {
          sumTotal += res.total;
          if (res.hasMorePages) anyHasMore = true;
          if (res.lastPage > maxLastPage) maxLastPage = res.lastPage;
          for (final order in res.orders) {
            final key = order.orderNumber.isNotEmpty
                ? order.orderNumber
                : order.id.toString();
            mergedMap[key] = order;
          }
        }

        final sortedOrders = mergedMap.values.toList()
          ..sort((a, b) {
            if (a.id != b.id && a.id > 0 && b.id > 0) {
              return b.id.compareTo(a.id);
            }
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        combinedResult = PaginatedOrdersResult(
          orders: sortedOrders,
          currentPage: targetPage,
          perPage: _perPage,
          total: sumTotal,
          lastPage: maxLastPage,
          hasMorePages: anyHasMore,
        );
      }

      // Pastikan hanya pesanan yang sesuai dengan status tab yang ditampilkan
      final filteredPageOrders = combinedResult.orders
          .where((order) => tab.matchesOrder(order))
          .toList();

      final latestTabData = state.tabDataFor(tab);
      final List<CheckoutResultModel> finalOrders;

      if (reset) {
        finalOrders = filteredPageOrders;
      } else {
        final existingKeys = latestTabData.orders
            .map((o) => o.orderNumber.isNotEmpty ? o.orderNumber : o.id.toString())
            .toSet();
        final newUnique = filteredPageOrders.where((o) {
          final k = o.orderNumber.isNotEmpty ? o.orderNumber : o.id.toString();
          return !existingKeys.contains(k);
        }).toList();
        finalOrders = [...latestTabData.orders, ...newUnique];
      }

      _updateTabData(
        tab,
        latestTabData.copyWith(
          orders: finalOrders,
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          currentPage: targetPage,
          hasMorePages: combinedResult.hasMorePages,
          totalCount: combinedResult.total > 0
              ? combinedResult.total
              : finalOrders.length,
          clearError: true,
        ),
      );
    } catch (e) {
      final latestTabData = state.tabDataFor(tab);
      _updateTabData(
        tab,
        latestTabData.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  /// Memuat halaman berikutnya (Infinite Scrolling) untuk tab yang sedang dipilih
  Future<void> loadMore() async {
    final tab = state.selectedTab;
    final tabData = state.tabDataFor(tab);
    if (!tabData.hasMorePages || tabData.isLoading || tabData.isLoadingMore) {
      return;
    }
    await fetchOrdersForTab(tab, reset: false);
  }

  /// Memuat ulang data tab yang sedang aktif (Pull-to-Refresh)
  Future<void> refreshCurrentTab() async {
    await fetchOrdersForTab(
      state.selectedTab,
      reset: true,
      forceRefresh: true,
    );
  }

  /// Memperbarui satu pesanan di dalam state (misalnya setelah upload bukti bayar atau fetch detail)
  void updateOrderInState(CheckoutResultModel updatedOrder) {
    final updatedMap = <OrderTabStatus, OrderTabData>{};

    for (final tab in OrderTabStatus.values) {
      final tabData = state.tabDataFor(tab);
      if (!tabData.hasLoaded) {
        updatedMap[tab] = tabData;
        continue;
      }

      final idx = tabData.orders.indexWhere(
        (o) =>
            (updatedOrder.orderNumber.isNotEmpty &&
                o.orderNumber == updatedOrder.orderNumber) ||
            (updatedOrder.id > 0 && o.id == updatedOrder.id),
      );

      if (tab.matchesOrder(updatedOrder)) {
        if (idx >= 0) {
          final newList = List<CheckoutResultModel>.from(tabData.orders);
          newList[idx] = newList[idx].mergeWithDetail(updatedOrder);
          updatedMap[tab] = tabData.copyWith(orders: newList);
        } else {
          updatedMap[tab] = tabData.copyWith(
            orders: [updatedOrder, ...tabData.orders],
            totalCount: tabData.totalCount + 1,
          );
        }
      } else if (idx >= 0) {
        // Jika status pesanan berubah sehingga berpindah tab, hapus dari tab lama
        final newList = List<CheckoutResultModel>.from(tabData.orders)
          ..removeAt(idx);
        updatedMap[tab] = tabData.copyWith(
          orders: newList,
          totalCount: tabData.totalCount > 0 ? tabData.totalCount - 1 : 0,
        );
      } else {
        updatedMap[tab] = tabData;
      }
    }

    state = state.copyWith(tabDataMap: updatedMap);
  }

  void _updateTabData(OrderTabStatus tab, OrderTabData newData) {
    final newMap = Map<OrderTabStatus, OrderTabData>.from(state.tabDataMap);
    newMap[tab] = newData;
    state = state.copyWith(tabDataMap: newMap);
  }

  String _cleanError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceAll('Exception: ', '');
  }
}

