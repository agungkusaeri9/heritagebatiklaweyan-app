import 'checkout_result_model.dart';

/// Metadata paginasi dan hasil daftar pesanan dari endpoint GET /api/v1/orders
class PaginatedOrdersResult {
  final List<CheckoutResultModel> orders;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  const PaginatedOrdersResult({
    required this.orders,
    this.currentPage = 1,
    this.perPage = 10,
    this.total = 0,
    this.lastPage = 1,
    this.hasMorePages = false,
  });

  factory PaginatedOrdersResult.fromJson(Map<String, dynamic> responseData) {
    final List<CheckoutResultModel> parsedOrders = [];
    final rawData = responseData['data'];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          parsedOrders.add(CheckoutResultModel.fromJson(item));
        }
      }
    } else if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      // Fallback jika paginator dibungkus di dalam data.data
      for (final item in rawData['data'] as List) {
        if (item is Map<String, dynamic>) {
          parsedOrders.add(CheckoutResultModel.fromJson(item));
        }
      }
    }

    int curPage = 1;
    int pPage = 10;
    int tot = parsedOrders.length;
    int lPage = 1;
    bool hasMore = false;

    final meta = responseData['meta'];
    if (meta is Map<String, dynamic> && meta['pagination'] is Map<String, dynamic>) {
      final pag = meta['pagination'] as Map<String, dynamic>;
      curPage = (pag['current_page'] as num?)?.toInt() ?? 1;
      pPage = (pag['per_page'] as num?)?.toInt() ?? 10;
      tot = (pag['total'] as num?)?.toInt() ?? parsedOrders.length;
      lPage = (pag['last_page'] as num?)?.toInt() ?? 1;
      hasMore = pag['has_more_pages'] == true || curPage < lPage;
    } else if (rawData is Map<String, dynamic>) {
      curPage = (rawData['current_page'] as num?)?.toInt() ?? 1;
      pPage = (rawData['per_page'] as num?)?.toInt() ?? 10;
      tot = (rawData['total'] as num?)?.toInt() ?? parsedOrders.length;
      lPage = (rawData['last_page'] as num?)?.toInt() ?? 1;
      hasMore = curPage < lPage;
    }

    return PaginatedOrdersResult(
      orders: parsedOrders,
      currentPage: curPage,
      perPage: pPage,
      total: tot,
      lastPage: lPage,
      hasMorePages: hasMore,
    );
  }

  PaginatedOrdersResult copyWith({
    List<CheckoutResultModel>? orders,
    int? currentPage,
    int? perPage,
    int? total,
    int? lastPage,
    bool? hasMorePages,
  }) {
    return PaginatedOrdersResult(
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      lastPage: lastPage ?? this.lastPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }
}

