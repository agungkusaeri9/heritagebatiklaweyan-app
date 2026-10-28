import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/checkout/data/models/checkout_result_model.dart';
import 'package:heritage_batik/features/checkout/data/models/customer_address_model.dart';
import 'package:heritage_batik/features/checkout/data/models/order_pagination_model.dart';
import 'package:heritage_batik/features/checkout/data/models/region_model.dart';
import 'package:heritage_batik/features/checkout/data/models/shipping_type_model.dart';
import 'package:heritage_batik/features/checkout/data/repositories/checkout_repository.dart';
import 'package:heritage_batik/features/checkout/presentation/viewmodels/checkout_providers.dart';
import 'package:heritage_batik/features/checkout/presentation/viewmodels/order_list_state.dart';
import 'package:heritage_batik/features/checkout/presentation/views/order_detail_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/order_list_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/track_order_view.dart';
import 'package:heritage_batik/features/store/data/models/payment_method_model.dart';

class FakeOrdersCheckoutRepository implements CheckoutRepository {
  final Map<String, List<CheckoutResultModel>> ordersByStatus;
  final List<String> requestedStatuses = [];
  bool shouldThrow = false;

  FakeOrdersCheckoutRepository({required this.ordersByStatus});

  @override
  Future<PaginatedOrdersResult> getOrders({
    String? status,
    String? search,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    if (shouldThrow) {
      throw Exception('Failed to connect to server');
    }
    if (status != null) {
      requestedStatuses.add(status);
    }
    final list = status != null ? (ordersByStatus[status] ?? const []) : const <CheckoutResultModel>[];
    return PaginatedOrdersResult(
      orders: list,
      currentPage: page,
      perPage: perPage,
      total: list.length,
      lastPage: 1,
      hasMorePages: false,
    );
  }

  @override
  Future<CheckoutResultModel> getOrderDetail(dynamic idOrOrderNumber) async {
    if (shouldThrow) {
      throw Exception('Failed to load order detail');
    }
    for (final list in ordersByStatus.values) {
      for (final order in list) {
        if (order.orderNumber == idOrOrderNumber.toString() ||
            order.id.toString() == idOrOrderNumber.toString()) {
          return order;
        }
      }
    }
    throw Exception('Order not found');
  }

  @override
  Future<List<CustomerAddressModel>> getAddresses() async => const [];

  @override
  Future<CustomerAddressModel> addAddress(Map<String, dynamic> data) =>
      throw UnimplementedError();

  @override
  Future<bool> setPrimaryAddress(int addressId) async => true;

  @override
  Future<List<ShippingTypeModel>> getShippingTypes() async => const [];

  @override
  Future<List<ShippingTypeModel>> checkShippingCost({
    required dynamic destination,
    required int weight,
    String? courier,
    dynamic origin,
  }) async =>
      const [];

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async => const [];

  @override
  Future<CheckoutResultModel> processCheckout(Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<CheckoutResultModel> uploadPaymentProof({
    required dynamic idOrOrderNumber,
    required String filePath,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<ProvinceModel>> getProvinces() async => const [];

  @override
  Future<List<CityModel>> getCities(int provinceId) async => const [];

  @override
  Future<List<SubdistrictModel>> getSubdistricts(int cityId) async => const [];
}

void main() {
  final sampleActiveMultiProductOrder = CheckoutResultModel(
    id: 10,
    orderNumber: 'ORD-ACTIVE-001',
    status: 'processing',
    paymentStatus: 'paid',
    subtotal: 1230000,
    shippingFee: 20000,
    totalAmount: 1250000,
    totalItemsCount: 10,
    paymentMethodName: 'BCA Virtual Account',
    paymentAccountNumber: '8830192841',
    paymentAccountName: 'PT Batik Nusantara',
    courierName: 'JNE',
    shippingName: 'JNE - Reguler',
    trackingNumber: 'JNE998877665',
    recipientName: 'Agung Kusaeri',
    recipientPhone: '081234567890',
    recipientAddress: 'Jl. Dr. Rajiman No. 515',
    subdistrictName: 'Laweyan',
    cityName: 'Kota Surakarta',
    provinceName: 'Jawa Tengah',
    postalCode: '57148',
    items: const [
      CheckoutOrderItemModel(
        id: 1,
        productId: 101,
        productName: 'Kemeja Batik Tulis Parang',
        variantInfo: 'Size: XL',
        price: 350000,
        quantity: 2,
        totalPrice: 700000,
      ),
      CheckoutOrderItemModel(
        id: 2,
        productId: 102,
        productName: 'Tunik Batik Sogan Klasik',
        variantInfo: 'Size: M',
        price: 150000,
        quantity: 3,
        totalPrice: 450000,
      ),
      CheckoutOrderItemModel(
        id: 3,
        productId: 103,
        productName: 'Selendang Batik Kawung',
        variantInfo: 'All Size',
        price: 16000,
        quantity: 5,
        totalPrice: 80000,
      ),
    ],
  );

  final sampleCompletedOrder = CheckoutResultModel(
    id: 11,
    orderNumber: 'ORD-COMP-002',
    status: 'success',
    paymentStatus: 'paid',
    subtotal: 250000,
    shippingFee: 15000,
    totalAmount: 265000,
    totalItemsCount: 1,
    paymentMethodName: 'Bank Mandiri',
    shippingName: 'POS Indonesia',
    items: const [
      CheckoutOrderItemModel(
        id: 4,
        productId: 104,
        productName: 'Sarung Batik Mahkota Laweyan',
        variantInfo: 'Size: All Size',
        price: 250000,
        quantity: 1,
        totalPrice: 250000,
      ),
    ],
  );

  final sampleCancelledOrder = CheckoutResultModel(
    id: 12,
    orderNumber: 'ORD-CANC-003',
    status: 'failed',
    paymentStatus: 'failed',
    subtotal: 180000,
    shippingFee: 15000,
    totalAmount: 195000,
    totalItemsCount: 2,
    paymentMethodName: 'BRI',
    items: const [
      CheckoutOrderItemModel(
        id: 5,
        productId: 105,
        productName: 'Kain Batik Cap Sekar Jagad',
        variantInfo: '2 Meter',
        price: 90000,
        quantity: 2,
        totalPrice: 180000,
      ),
    ],
  );

  group('CheckoutResultModel Summary & Status Mapping Tests', () {
    test('Correctly calculates distinctProductCount, totalQuantity, primaryProduct, and additionalProductCount', () {
      expect(sampleActiveMultiProductOrder.primaryProduct?.productName, 'Kemeja Batik Tulis Parang');
      expect(sampleActiveMultiProductOrder.distinctProductCount, 3);
      expect(sampleActiveMultiProductOrder.additionalProductCount, 2);
      expect(sampleActiveMultiProductOrder.totalQuantity, 10);
      expect(sampleActiveMultiProductOrder.formattedTotal, 'Rp 1.250.000');
      expect(sampleActiveMultiProductOrder.isActiveOrder, isTrue);
      expect(sampleActiveMultiProductOrder.canTrackOrder, isTrue);
    });

    test('Completed and Cancelled orders hide active tracking actions', () {
      expect(sampleCompletedOrder.isCompletedOrder, isTrue);
      expect(sampleCompletedOrder.canTrackOrder, isFalse);

      expect(sampleCancelledOrder.isCancelledOrder, isTrue);
      expect(sampleCancelledOrder.canTrackOrder, isFalse);
    });

    test('OrderTabData groups orders by date correctly into dateGroups', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      final yesterday = today.subtract(const Duration(days: 1));
      final olderDate = today.subtract(const Duration(days: 5));

      final orderToday1 = sampleActiveMultiProductOrder.copyWith(createdAt: today);
      final orderToday2 = sampleCompletedOrder.copyWith(createdAt: today.add(const Duration(minutes: 10)));
      final orderYesterday = sampleCancelledOrder.copyWith(createdAt: yesterday);
      final orderOlder = sampleCompletedOrder.copyWith(createdAt: olderDate);

      final tabData = OrderTabData(
        orders: [orderToday1, orderYesterday, orderToday2, orderOlder],
      );

      final groups = tabData.dateGroups;
      expect(groups.length, 3);
      expect(groups[0].title, 'Today');
      expect(groups[0].items.length, 2);
      expect(groups[1].title, 'Yesterday');
      expect(groups[1].items.length, 1);
      expect(groups[2].items.length, 1);
    });
  });

  group('OrderListView & OrderDetailView Widget Tests', () {
    late FakeOrdersCheckoutRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeOrdersCheckoutRepository(
        ordersByStatus: {
          'processing': [sampleActiveMultiProductOrder],
          'pending': const [],
          'success': [sampleCompletedOrder],
          'failed': [sampleCancelledOrder],
        },
      );
    });

    testWidgets(
      'OrderListView displays My Orders header, status tabs, primary product summary for multi-product order, and switches tabs using backend status filters',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: OrderListView(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Page title & Tabs
        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Cancelled'), findsOneWidget);

        // 2. Verify backend filter statuses requested for Active tab
        expect(fakeRepo.requestedStatuses, containsAll(['processing', 'pending']));

        // 3. Multi-product order displays ONLY the first product as primary summary
        expect(find.text('Kemeja Batik Tulis Parang'), findsOneWidget);
        expect(find.text('Tunik Batik Sogan Klasik'), findsNothing);
        expect(find.text('Selendang Batik Kawung'), findsNothing);

        // 4. Displays distinct product count, total quantity, additional products indicator, and total order price
        expect(find.text('3 Products · Total Qty: 10 pcs'), findsOneWidget);
        expect(find.text('+2 other products'), findsOneWidget);
        expect(find.text('Rp 1.250.000'), findsOneWidget);
        expect(find.text('Track Order'), findsOneWidget);

        // 5. Switch to Completed tab -> fetches 'success' status and hides Track Order
        await tester.tap(find.byKey(const Key('order_tab_completed')));
        await tester.pumpAndSettle();

        expect(fakeRepo.requestedStatuses, contains('success'));
        expect(find.text('Sarung Batik Mahkota Laweyan'), findsOneWidget);
        expect(find.text('1 Product · Total Qty: 1 pcs'), findsOneWidget);
        expect(find.text('Rp 265.000'), findsOneWidget);
        expect(find.byKey(const Key('completed_badge_ORD-COMP-002')), findsOneWidget);

        // 6. Switch to Cancelled tab -> fetches 'failed' status and shows Cancelled badge
        await tester.tap(find.byKey(const Key('order_tab_cancelled')));
        await tester.pumpAndSettle();

        expect(fakeRepo.requestedStatuses, contains('failed'));
        expect(find.text('Kain Batik Cap Sekar Jagad'), findsOneWidget);
        expect(find.text('1 Product · Total Qty: 2 pcs'), findsOneWidget);
        expect(find.text('Rp 195.000'), findsOneWidget);
        expect(find.byKey(const Key('cancelled_badge_ORD-CANC-003')), findsOneWidget);
      },
    );

    testWidgets(
      'OrderDetailView displays ALL products in a multi-product order, complete order information, price breakdown, and Track Order action',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              home: OrderDetailView(
                orderNumber: sampleActiveMultiProductOrder.orderNumber,
                initialOrder: sampleActiveMultiProductOrder,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Order Information
        expect(find.text('Order Details'), findsOneWidget);
        expect(find.text('ORD-ACTIVE-001'), findsOneWidget);
        expect(find.text('Processing'), findsOneWidget);
        expect(find.text('Paid'), findsWidgets);

        // 2. All 3 products are displayed in OrderDetailView
        expect(find.text('Kemeja Batik Tulis Parang'), findsOneWidget);
        expect(find.text('Tunik Batik Sogan Klasik'), findsOneWidget);
        expect(find.text('Selendang Batik Kawung'), findsOneWidget);
        expect(find.text('Total Qty: 10 pcs'), findsOneWidget);

        // 3. Shipping & Recipient Information
        expect(find.text('JNE - Reguler'), findsOneWidget);
        expect(find.text('JNE998877665'), findsOneWidget);
        expect(find.text('Agung Kusaeri'), findsOneWidget);

        // 4. Price Summary
        expect(find.text('Rp 1.230.000'), findsOneWidget);
        expect(find.text('Rp 20.000'), findsOneWidget);
        expect(find.text('Rp 1.250.000'), findsOneWidget);

        // 5. Track Order action button is present for active order
        expect(find.byKey(const Key('detail_track_order_button')), findsOneWidget);
      },
    );

    testWidgets(
      'TrackOrderView displays product summary, tracking number, and order status timeline',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              home: TrackOrderView(
                orderNumber: sampleActiveMultiProductOrder.orderNumber,
                initialOrder: sampleActiveMultiProductOrder,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Track Order'), findsOneWidget);
        expect(find.text('Kemeja Batik Tulis Parang'), findsOneWidget);
        expect(find.text('ORD-ACTIVE-001'), findsOneWidget);
        expect(find.text('JNE998877665'), findsOneWidget);
        expect(find.text('Order Placed'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Shipped'), findsOneWidget);
      },
    );
  });
}

