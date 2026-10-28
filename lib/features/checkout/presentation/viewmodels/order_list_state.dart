import '../../data/models/checkout_result_model.dart';

/// Definisi tab status pesanan yang dipetakan ke nilai filter status backend
enum OrderTabStatus {
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderTabStatus.active:
        return 'Active';
      case OrderTabStatus.completed:
        return 'Completed';
      case OrderTabStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Nilai parameter `status` pada API backend (`GET /api/v1/orders?status=...`)
  /// Sesuai definisi di OrderController & Dashboard:
  /// - Active: 'processing' & 'pending'
  /// - Completed: 'success'
  /// - Cancelled: 'failed'
  List<String> get backendStatuses {
    switch (this) {
      case OrderTabStatus.active:
        return const ['processing', 'pending'];
      case OrderTabStatus.completed:
        return const ['success'];
      case OrderTabStatus.cancelled:
        return const ['failed'];
    }
  }

  String get primaryBackendStatus => backendStatuses.first;

  bool matchesOrder(CheckoutResultModel order) {
    switch (this) {
      case OrderTabStatus.active:
        return order.isActiveOrder;
      case OrderTabStatus.completed:
        return order.isCompletedOrder;
      case OrderTabStatus.cancelled:
        return order.isCancelledOrder;
    }
  }
}

/// Kelompok pesanan berdasarkan tanggal
class OrderDateGroup {
  final String title;
  final DateTime date;
  final List<CheckoutResultModel> items;

  const OrderDateGroup({
    required this.title,
    required this.date,
    required this.items,
  });
}

/// State per tab (menyimpan daftar pesanan, paginasi, loading, & error masing-masing tab)
class OrderTabData {
  final List<CheckoutResultModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final bool hasMorePages;
  final int currentPage;
  final int totalCount;
  final String? errorMessage;

  const OrderTabData({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.hasMorePages = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.errorMessage,
  });

  /// Mengelompokkan pesanan berdasarkan tanggal pembuatan (Today, Yesterday, Date)
  List<OrderDateGroup> get dateGroups {
    if (orders.isEmpty) return const [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Map tanggal (yyyy-MM-dd) -> List<CheckoutResultModel>
    final Map<DateTime, List<CheckoutResultModel>> groupedMap = {};

    for (final order in orders) {
      final dt = order.createdAt ?? now;
      final dateKey = DateTime(dt.year, dt.month, dt.day);

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(order);
    }

    // Urutkan tanggal dari yang paling baru ke paling lama
    final sortedKeys = groupedMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((date) {
      String groupTitle;
      if (date == today) {
        groupTitle = 'Today';
      } else if (date == yesterday) {
        groupTitle = 'Yesterday';
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final month = _monthName(date.month);
        final year = date.year;
        groupTitle = '$day $month $year';
      }

      // Pastikan item di dalam kelompok juga terurut dari yang paling baru
      final items = List<CheckoutResultModel>.from(groupedMap[date]!);
      items.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return OrderDateGroup(
        title: groupTitle,
        date: date,
        items: items,
      );
    }).toList();
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  OrderTabData copyWith({
    List<CheckoutResultModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    bool? hasMorePages,
    int? currentPage,
    int? totalCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderTabData(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// State utama halaman My Orders (Order List)
class OrderListState {
  final OrderTabStatus selectedTab;
  final Map<OrderTabStatus, OrderTabData> tabDataMap;
  final String searchQuery;

  const OrderListState({
    this.selectedTab = OrderTabStatus.active,
    this.tabDataMap = const {
      OrderTabStatus.active: OrderTabData(),
      OrderTabStatus.completed: OrderTabData(),
      OrderTabStatus.cancelled: OrderTabData(),
    },
    this.searchQuery = '',
  });

  OrderTabData tabDataFor(OrderTabStatus tab) =>
      tabDataMap[tab] ?? const OrderTabData();

  OrderTabData get currentTabData => tabDataFor(selectedTab);

  List<CheckoutResultModel> get currentOrders => currentTabData.orders;
  bool get isLoading => currentTabData.isLoading;
  bool get isLoadingMore => currentTabData.isLoadingMore;
  bool get hasMorePages => currentTabData.hasMorePages;
  String? get errorMessage => currentTabData.errorMessage;

  OrderListState copyWith({
    OrderTabStatus? selectedTab,
    Map<OrderTabStatus, OrderTabData>? tabDataMap,
    String? searchQuery,
  }) {
    return OrderListState(
      selectedTab: selectedTab ?? this.selectedTab,
      tabDataMap: tabDataMap ?? this.tabDataMap,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

