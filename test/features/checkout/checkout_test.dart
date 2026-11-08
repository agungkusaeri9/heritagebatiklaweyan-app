import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/cart/data/models/cart_item_model.dart';
import 'package:heritage_batik/features/checkout/data/models/checkout_result_model.dart';
import 'package:heritage_batik/features/checkout/data/models/customer_address_model.dart';
import 'package:heritage_batik/features/checkout/data/models/order_pagination_model.dart';
import 'package:heritage_batik/features/checkout/data/models/order_review_model.dart';
import 'package:heritage_batik/features/checkout/data/models/region_model.dart';
import 'package:heritage_batik/features/checkout/data/models/shipping_type_model.dart';
import 'package:heritage_batik/features/checkout/data/repositories/checkout_repository.dart';
import 'package:heritage_batik/features/checkout/presentation/viewmodels/checkout_providers.dart';
import 'package:heritage_batik/features/checkout/presentation/viewmodels/checkout_state.dart';
import 'package:heritage_batik/features/checkout/presentation/views/checkout_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/order_detail_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/payment_success_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/shipping_address_selection_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/shipping_type_selection_view.dart';
import 'package:heritage_batik/features/checkout/presentation/views/upload_payment_proof_view.dart';
import 'package:heritage_batik/features/store/data/models/payment_method_model.dart';
import 'package:heritage_batik/features/store/presentation/viewmodels/store_providers.dart';

class MockCheckoutRepository implements CheckoutRepository {
  List<CustomerAddressModel> mockAddresses = [];
  List<ShippingTypeModel> mockShippingTypes = [];
  List<PaymentMethodModel> mockPaymentMethods = [];
  bool shouldThrow = false;
  Map<String, dynamic>? lastCheckoutPayload;

  @override
  Future<List<CustomerAddressModel>> getAddresses() async {
    if (shouldThrow) throw Exception('Addresses fetch failed');
    return mockAddresses;
  }

  @override
  Future<CustomerAddressModel> addAddress(Map<String, dynamic> data) async {
    if (shouldThrow) throw Exception('Address create failed');
    final newAddress = CustomerAddressModel(
      id: 999,
      recipientName: data['recipient_name']?.toString() ?? 'New Recipient',
      phone: data['phone']?.toString() ?? '08123456789',
      addressLine1: data['address_line_1']?.toString() ?? 'New Street',
      city: data['city']?.toString() ?? 'Surakarta',
      province: data['province']?.toString() ?? 'Jawa Tengah',
      postalCode: data['postal_code']?.toString() ?? '57147',
      isPrimary: data['is_primary'] == true,
    );
    mockAddresses.insert(0, newAddress);
    return newAddress;
  }

  @override
  Future<bool> setPrimaryAddress(int addressId) async {
    return true;
  }

  @override
  Future<List<ShippingTypeModel>> getShippingTypes() async {
    if (shouldThrow) throw Exception('Shipping types fetch failed');
    return mockShippingTypes;
  }

  @override
  Future<List<ShippingTypeModel>> checkShippingCost({
    required dynamic destination,
    required int weight,
    String? courier,
    dynamic origin,
  }) async {
    if (shouldThrow) throw Exception('Shipping cost check failed');
    return mockShippingTypes;
  }

  @override
  Future<PaginatedOrdersResult> getOrders({
    String? status,
    String? search,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    if (shouldThrow) throw Exception('Orders fetch failed');
    return const PaginatedOrdersResult(orders: []);
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    if (shouldThrow) throw Exception('Payment methods fetch failed');
    return mockPaymentMethods;
  }

  @override
  Future<CheckoutResultModel> processCheckout(Map<String, dynamic> payload) async {
    if (shouldThrow) throw Exception('Checkout process failed');
    lastCheckoutPayload = payload;
    return const CheckoutResultModel(
      orderId: 101,
      orderNumber: 'ORD-20261025-000101',
      status: 'pending',
      totalAmount: 420000.0,
      paymentMethod: 'BCA Virtual Account',
    );
  }

  @override
  Future<CheckoutResultModel> getOrderDetail(dynamic idOrOrderNumber) async {
    if (shouldThrow) throw Exception('Get order detail failed');
    return const CheckoutResultModel(
      orderId: 101,
      orderNumber: 'ORD-20261025-000101',
      status: 'pending',
      totalAmount: 420000.0,
      paymentMethod: 'BCA Virtual Account',
      paymentAccountNumber: '8830192841',
      paymentAccountName: 'PT Batik Nusantara',
    );
  }

  @override
  Future<CheckoutResultModel> uploadPaymentProof({
    required dynamic idOrOrderNumber,
    required String filePath,
  }) async {
    if (shouldThrow) throw Exception('Upload payment proof failed');
    return const CheckoutResultModel(
      orderId: 101,
      orderNumber: 'ORD-20261025-000101',
      status: 'pending',
      totalAmount: 420000.0,
      paymentMethod: 'BCA Virtual Account',
      paymentProof: 'proofs/sample.jpg',
    );
  }

  @override
  Future<CheckoutResultModel> submitOrderReviews({
    required CheckoutResultModel order,
    required int transactionRating,
    String? transactionComment,
    required List<OrderItemReviewModel> productReviews,
  }) async {
    if (shouldThrow) throw Exception('Submit order reviews failed');
    return order.copyWith(
      isReviewedExplicit: true,
      reviewedCount: productReviews.length,
      transactionRating: transactionRating,
      transactionReviewComment: transactionComment,
      reviews: productReviews,
    );
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    return const [
      ProvinceModel(id: 10, name: 'Jawa Tengah'),
    ];
  }

  @override
  Future<List<CityModel>> getCities(int provinceId) async {
    return const [
      CityModel(id: 445, provinceId: 10, name: 'Kota Surakarta (Solo)', postalCode: '57113'),
    ];
  }

  @override
  Future<List<SubdistrictModel>> getSubdistricts(int cityId) async {
    return const [
      SubdistrictModel(id: 6164, cityId: 445, name: 'Laweyan'),
    ];
  }
}

void main() {
  final sampleAddresses = [
    const CustomerAddressModel(
      id: 1,
      recipientName: 'Agung Kusaeri',
      phone: '081234567890',
      addressLine1: 'Jl. Dr. Rajiman No. 515, Laweyan',
      city: 'Surakarta',
      province: 'Jawa Tengah',
      postalCode: '57148',
      isPrimary: true,
      label: 'Home',
    ),
    const CustomerAddressModel(
      id: 2,
      recipientName: 'Kantor Heritage',
      phone: '089876543210',
      addressLine1: 'Jl. Slamet Riyadi No. 100',
      city: 'Surakarta',
      province: 'Jawa Tengah',
      postalCode: '57141',
      isPrimary: false,
      label: 'Office',
    ),
  ];

  final sampleShippingTypes = [
    const ShippingTypeModel(
      id: 1,
      name: 'JNE Regular',
      code: 'jne',
      description: 'Reguler (2-3 hari kerja)',
      fee: 20000.0,
      estimatedDays: '2-3 hari',
    ),
    const ShippingTypeModel(
      id: 2,
      name: 'J&T Express',
      code: 'jnt',
      description: 'Kilat (1-2 hari kerja)',
      fee: 25000.0,
      estimatedDays: '1-2 hari',
    ),
  ];

  final samplePaymentMethods = [
    const PaymentMethodModel(
      id: 1,
      name: 'Bank Central Asia (BCA)',
      accountName: 'PT Batik Nusantara',
      accountNumber: '8830192841',
      isActive: true,
    ),
    const PaymentMethodModel(
      id: 2,
      name: 'Bank Mandiri',
      accountName: 'PT Batik Nusantara',
      accountNumber: '1370019284712',
      isActive: true,
    ),
  ];

  final sampleCartItems = [
    const CartItemModel(
      id: 1,
      productId: 10,
      productName: 'Kemeja Batik Laweyan Slim Fit',
      productPrice: 200000.0,
      qty: 2,
      total: 400000.0,
      variantInfo: 'Size: L',
      stock: 10,
    ),
  ];

  group('CheckoutViewModel Tests', () {
    late MockCheckoutRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockCheckoutRepository();
      mockRepo.mockAddresses = List.from(sampleAddresses);
      mockRepo.mockShippingTypes = List.from(sampleShippingTypes);
      mockRepo.mockPaymentMethods = List.from(samplePaymentMethods);

      container = ProviderContainer(
        overrides: [
          checkoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initCheckout sets items, loads addresses, shipping types, and payment methods with default selections', () async {
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      final state = container.read(checkoutViewModelProvider);
      expect(state.status, CheckoutStatus.success);
      expect(state.items.length, 1);
      expect(state.addresses.length, 2);
      expect(state.selectedAddress?.id, 1); // Primary address
      expect(state.shippingTypes.length, 2);
      expect(state.selectedShippingType?.id, 1); // First courier
      expect(state.paymentMethods.length, 2);
      expect(state.selectedPaymentMethod?.id, 1); // First payment method
      expect(state.subtotal, 400000.0);
      expect(state.shippingFee, 20000.0);
      expect(state.totalAmount, 420000.0);
    });

    test('selectPaymentMethod immediately updates selectedPaymentMethod', () async {
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      notifier.selectPaymentMethod(samplePaymentMethods[1]);

      final state = container.read(checkoutViewModelProvider);
      expect(state.selectedPaymentMethod?.id, 2);
      expect(state.selectedPaymentMethod?.name, 'Bank Mandiri');
    });

    test('selectAddress immediately updates selectedAddress', () async {
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      notifier.selectAddress(sampleAddresses[1]);

      final state = container.read(checkoutViewModelProvider);
      expect(state.selectedAddress?.id, 2);
      expect(state.selectedAddress?.recipientName, 'Kantor Heritage');
    });

    test('selectShippingType updates selected shipping and recalculates total', () async {
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      notifier.selectShippingType(sampleShippingTypes[1]); // Fee: 25000

      final state = container.read(checkoutViewModelProvider);
      expect(state.selectedShippingType?.id, 2);
      expect(state.shippingFee, 25000.0);
      expect(state.totalAmount, 425000.0);
    });

    test('addNewAddress adds to list and selects it immediately', () async {
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      bool successCalled = false;
      final added = await notifier.addNewAddress(
        {
          'recipient_name': 'Budi Santoso',
          'phone': '081122334455',
          'address_line_1': 'Jl. Solo Baru No. 12',
          'city': 'Sukoharjo',
          'province': 'Jawa Tengah',
          'postal_code': '57552',
        },
        onSuccess: () => successCalled = true,
      );

      expect(added, isTrue);
      expect(successCalled, isTrue);

      final state = container.read(checkoutViewModelProvider);
      expect(state.addresses.length, 3);
      expect(state.selectedAddress?.recipientName, 'Budi Santoso');
      expect(state.selectedAddress?.city, 'Sukoharjo');
    });

    test('processCheckout executes repository checkout with correct payload', () async {
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      CheckoutResultModel? successResult;
      final result = await notifier.processCheckout(
        paymentMethodId: 3,
        onSuccess: (res) => successResult = res,
      );

      expect(result, isNotNull);
      expect(successResult?.orderNumber, 'ORD-20261025-000101');
      expect(mockRepo.lastCheckoutPayload?['address_id'], 1);
      expect(mockRepo.lastCheckoutPayload?['courier_id'], 1);
      expect(mockRepo.lastCheckoutPayload?['payment_method_id'], 3);
      expect(mockRepo.lastCheckoutPayload?['shipping_fee'], 20000.0);
    });

    test('initCheckout sets error state on failure', () async {
      mockRepo.shouldThrow = true;
      final notifier = container.read(checkoutViewModelProvider.notifier);
      await notifier.initCheckout(sampleCartItems);

      final state = container.read(checkoutViewModelProvider);
      expect(state.status, CheckoutStatus.error);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('CheckoutView Widget Tests', () {
    testWidgets('Renders all Checkout sections correctly including Select Payment Method with 2-column radio buttons', (tester) async {
      final mockRepo = MockCheckoutRepository();
      mockRepo.mockAddresses = List.from(sampleAddresses);
      mockRepo.mockShippingTypes = List.from(sampleShippingTypes);
      mockRepo.mockPaymentMethods = List.from(samplePaymentMethods);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CheckoutView(),
          ),
        ),
      );

      // Trigger initState postFrameCallback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. App Bar
      expect(find.text('Checkout'), findsOneWidget);

      // 2. Shipping Address section
      expect(find.text('Shipping Address'), findsOneWidget);
      expect(find.text('Agung Kusaeri'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Jl. Dr. Rajiman No. 515, Laweyan, Surakarta, Jawa Tengah 57148'), findsOneWidget);

      // 3. Choose Shipping Type section
      expect(find.text('Choose Shipping Type'), findsOneWidget);
      expect(find.text('JNE Regular'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsWidgets); // Courier fee and summary row

      // 4. Select Payment Method section (1 baris 2 kolom radio button)
      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('8830192841'), findsOneWidget);
      expect(find.text('Bank Mandiri'), findsOneWidget);
      expect(find.text('1370019284712'), findsOneWidget);

      // 5. CHANGE buttons for both address and shipping type
      expect(find.text('CHANGE'), findsNWidgets(2));

      // 6. Order List
      expect(find.text('Order List'), findsOneWidget);

      // 7. Price Summary
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('Total Cost'), findsOneWidget);

      // 8. Fixed Bottom Button
      expect(find.text('Continue to Payment'), findsOneWidget);

      // Test tapping Bank Mandiri updates selection
      await tester.tap(find.text('Bank Mandiri'));
      await tester.pump();
    });

    testWidgets('ShippingAddressSelectionView displays addresses, radio selection, and updates state upon tapping Apply', (tester) async {
      final mockRepo = MockCheckoutRepository();
      mockRepo.mockAddresses = List.from(sampleAddresses);
      mockRepo.mockShippingTypes = List.from(sampleShippingTypes);
      mockRepo.mockPaymentMethods = List.from(samplePaymentMethods);

      final container = ProviderContainer(
        overrides: [
          checkoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Pre-initialize checkout state
      await container.read(checkoutViewModelProvider.notifier).initCheckout(sampleCartItems);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ShippingAddressSelectionView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header, Address List, Add Button, and Apply Button
      expect(find.text('Shipping Address'), findsOneWidget);
      expect(find.text('Agung Kusaeri'), findsOneWidget);
      expect(find.text('Kantor Heritage'), findsOneWidget);
      expect(find.text('Add New Shipping Address'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Select 'Kantor Heritage' (id: 2)
      await tester.tap(find.text('Kantor Heritage'));
      await tester.pumpAndSettle();

      // Click Apply button
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // State in viewmodel is updated to selected address (id: 2)
      final state = container.read(checkoutViewModelProvider);
      expect(state.selectedAddress?.id, 2);
      expect(state.selectedAddress?.recipientName, 'Kantor Heritage');
    });

    testWidgets('ShippingTypeSelectionView displays couriers, radio selection, and updates state upon tapping Apply', (tester) async {
      final mockRepo = MockCheckoutRepository();
      mockRepo.mockAddresses = List.from(sampleAddresses);
      mockRepo.mockShippingTypes = List.from(sampleShippingTypes);
      mockRepo.mockPaymentMethods = List.from(samplePaymentMethods);

      final container = ProviderContainer(
        overrides: [
          checkoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Pre-initialize checkout state
      await container.read(checkoutViewModelProvider.notifier).initCheckout(sampleCartItems);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ShippingTypeSelectionView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header, Courier List, and Apply Button
      expect(find.text('Choose Shipping Type'), findsOneWidget);
      expect(find.text('JNE Regular'), findsOneWidget);
      expect(find.text('J&T Express'), findsOneWidget);
      expect(find.text('Rp 25.000'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Select 'J&T Express' (id: 2)
      await tester.tap(find.text('J&T Express'));
      await tester.pumpAndSettle();

      // Click Apply button
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // State in viewmodel is updated to selected shipping type (id: 2)
      final state = container.read(checkoutViewModelProvider);
      expect(state.selectedShippingType?.id, 2);
      expect(state.selectedShippingType?.name, 'J&T Express');
      expect(state.shippingFee, 25000.0);
      expect(state.totalAmount, 425000.0);
    });

    testWidgets('PaymentSuccessView displays check icon, Payment Successful title, confirmation message, actual transaction details, and 2 bottom buttons without receipt', (tester) async {
      final mockRepo = MockCheckoutRepository();
      const sampleOrder = CheckoutResultModel(
        orderId: 101,
        orderNumber: 'ORD-20261025-000101',
        status: 'pending',
        totalAmount: 420000.0,
        subtotal: 400000.0,
        shippingFee: 20000.0,
        paymentMethodName: 'Bank Central Asia (BCA)',
        paymentAccountNumber: '8830192841',
        paymentAccountName: 'PT Batik Nusantara',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: PaymentSuccessView(
              order: sampleOrder,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Success check icon and Title
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Payment Successful!'), findsOneWidget);

      // 2. Purchase confirmation text
      expect(find.textContaining('Pesanan Anda berhasil dibuat', findRichText: true), findsOneWidget);

      // 3. Actual transaction details
      expect(find.text('Total Payment'), findsOneWidget);
      expect(find.text('Rp 420.000'), findsOneWidget);
      expect(find.text('ORD-20261025-000101'), findsOneWidget);
      expect(find.text('Bank Central Asia (BCA)'), findsOneWidget);
      expect(find.text('8830192841'), findsOneWidget);

      // 4. Fixed bottom action area buttons
      expect(find.text('Upload Payment Proof'), findsOneWidget);
      expect(find.text('View Order Details'), findsOneWidget);

      // 5. Ensure "View E-Receipt" does NOT exist
      expect(find.text('View E-Receipt'), findsNothing);
      expect(find.textContaining('Receipt', findRichText: true), findsNothing);
    });
  });
}
