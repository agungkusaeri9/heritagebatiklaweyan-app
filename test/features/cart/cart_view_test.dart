import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:heritage_batik/features/cart/data/models/cart_item_model.dart';
import 'package:heritage_batik/features/cart/data/models/cart_summary_model.dart';
import 'package:heritage_batik/features/cart/data/repositories/cart_repository.dart';
import 'package:heritage_batik/features/cart/presentation/viewmodels/cart_providers.dart';
import 'package:heritage_batik/features/cart/presentation/viewmodels/cart_state.dart';
import 'package:heritage_batik/features/cart/presentation/views/cart_view.dart';
import 'package:heritage_batik/features/cart/presentation/widgets/cart_skeleton.dart';

class MockCartRepository implements CartRepository {
  List<CartItemModel> mockItems = [];
  bool shouldThrow = false;
  int? updatedCartId;
  int? updatedQuantity;
  int? deletedCartId;

  @override
  Future<CartResult> getCart() async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    final totalPrice = mockItems.fold(0.0, (sum, i) => sum + (i.productPrice * i.qty));
    final totalWeight = mockItems.fold(0, (sum, i) => sum + (i.weight * i.qty));

    return CartResult(
      items: mockItems,
      summary: CartSummaryModel(
        totalItems: mockItems.length,
        totalWeight: totalWeight,
        subtotal: totalPrice,
        deliveryFee: 15000.0,
        discount: 25000.0,
        totalCost: (totalPrice + 15000.0 - 25000.0).clamp(0.0, double.infinity),
      ),
    );
  }

  @override
  Future<CartItemModel> updateQuantity(int cartId, int quantity) async {
    updatedCartId = cartId;
    updatedQuantity = quantity;
    final item = mockItems.firstWhere((i) => i.id == cartId);
    return item.copyWith(
      qty: quantity,
      total: item.productPrice * quantity,
    );
  }

  @override
  Future<bool> deleteItem(int cartId) async {
    deletedCartId = cartId;
    mockItems.removeWhere((i) => i.id == cartId);
    return true;
  }

  @override
  Future<CartItemModel> addToCart(int productId, int quantity, {String? variantInfo}) async {
    return CartItemModel(
      id: 999,
      productId: productId,
      productName: 'New Product',
      productPrice: 100000.0,
      qty: quantity,
      total: 100000.0 * quantity,
    );
  }
}

void main() {
  group('CartViewModel Tests', () {
    late MockCartRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockCartRepository();
      mockRepo.mockItems = [
        const CartItemModel(
          id: 1,
          productId: 10,
          productName: 'Kemeja Batik Katun',
          productPrice: 200000.0,
          qty: 2,
          total: 400000.0,
          variantInfo: 'Size: L',
          stock: 10,
        ),
        const CartItemModel(
          id: 2,
          productId: 11,
          productName: 'Sarung Batik Tulis',
          productPrice: 150000.0,
          qty: 1,
          total: 150000.0,
          variantInfo: 'Size: All Size',
          stock: 5,
        ),
      ];
      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial load updates state with cart items and summary', () async {
      final notifier = container.read(cartViewModelProvider.notifier);
      await notifier.loadCart();

      final state = container.read(cartViewModelProvider);
      expect(state.status, CartStatus.success);
      expect(state.items.length, 2);
      expect(state.totalItemCount, 3);
      expect(state.calculatedSubtotal, 550000.0);
    });

    test('incrementQuantity updates quantity optimistically and calls repository', () async {
      final notifier = container.read(cartViewModelProvider.notifier);
      await notifier.loadCart();

      await notifier.incrementQuantity(1);

      final state = container.read(cartViewModelProvider);
      final item1 = state.items.firstWhere((i) => i.id == 1);
      expect(item1.qty, 3);
      expect(mockRepo.updatedCartId, 1);
      expect(mockRepo.updatedQuantity, 3);
    });

    test('decrementQuantity decrements when qty > 1', () async {
      final notifier = container.read(cartViewModelProvider.notifier);
      await notifier.loadCart();

      bool deleteTriggered = false;
      await notifier.decrementQuantity(
        1,
        onDeleteConfirm: () {
          deleteTriggered = true;
        },
      );

      final state = container.read(cartViewModelProvider);
      final item1 = state.items.firstWhere((i) => i.id == 1);
      expect(item1.qty, 1);
      expect(deleteTriggered, isFalse);
      expect(mockRepo.updatedCartId, 1);
      expect(mockRepo.updatedQuantity, 1);
    });

    test('decrementQuantity triggers onDeleteConfirm when qty is 1', () async {
      final notifier = container.read(cartViewModelProvider.notifier);
      await notifier.loadCart();

      bool deleteTriggered = false;
      await notifier.decrementQuantity(
        2, // item 2 has qty == 1
        onDeleteConfirm: () {
          deleteTriggered = true;
        },
      );

      expect(deleteTriggered, isTrue);
    });

    test('deleteItem removes item from state and calls repository', () async {
      final notifier = container.read(cartViewModelProvider.notifier);
      await notifier.loadCart();

      await notifier.deleteItem(2);

      final state = container.read(cartViewModelProvider);
      expect(state.items.length, 1);
      expect(state.items.any((i) => i.id == 2), isFalse);
      expect(mockRepo.deletedCartId, 2);
    });

    test('loadCart handles error properly', () async {
      mockRepo.shouldThrow = true;
      final notifier = container.read(cartViewModelProvider.notifier);
      await notifier.loadCart();

      final state = container.read(cartViewModelProvider);
      expect(state.status, CartStatus.error);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('CartView Widget Tests', () {
    testWidgets('Renders app bar, product list, promo section, summary, and checkout button', (tester) async {
      final mockRepo = MockCartRepository();
      mockRepo.mockItems = [
        const CartItemModel(
          id: 1,
          productId: 10,
          productName: 'Kemeja Batik Sogan Modern',
          productPrice: 200000.0,
          qty: 2,
          total: 400000.0,
          variantInfo: 'Size: XL',
          stock: 10,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CartView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. App Bar Title
      expect(find.text('My Cart'), findsOneWidget);

      // 2. Product Name & Variant & Price
      expect(find.text('Kemeja Batik Sogan Modern'), findsOneWidget);
      expect(find.text('Size: XL'), findsOneWidget);
      expect(find.text('Rp 200.000'), findsOneWidget);

      // 3. Quantity Stepper
      expect(find.text('2'), findsOneWidget);

      // 4. Order Summary
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total Cost'), findsOneWidget);

      // 5. Checkout Button
      expect(find.text('Proceed to Checkout'), findsOneWidget);
    });


    testWidgets('Renders Empty Cart State when no items exist', (tester) async {
      final mockRepo = MockCartRepository();
      mockRepo.mockItems = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CartView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
    });

    testWidgets('Renders Error State when API fails', (tester) async {
      final mockRepo = MockCartRepository();
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CartView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to Load Cart'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Renders CartSkeleton while loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CartSkeleton(),
          ),
        ),
      );

      expect(find.byType(CartSkeleton), findsOneWidget);
    });

    testWidgets('Cart item shows edit icon and sliding delete button on tap', (tester) async {
      final mockRepo = MockCartRepository();
      mockRepo.mockItems = [
        const CartItemModel(
          id: 1,
          productId: 10,
          productName: 'Kemeja Batik Sogan Modern',
          productPrice: 200000.0,
          qty: 2,
          total: 400000.0,
          variantInfo: 'Size: XL',
          stock: 10,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CartView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Initially, edit icon is present
      final editBtnFinder = find.byKey(const Key('cart_item_edit_button_1'));
      expect(editBtnFinder, findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // 2. Click edit icon -> animates and reveals sliding delete button
      await tester.tap(editBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final deleteBtnFinder = find.byKey(const Key('cart_item_delete_button_1'));
      expect(deleteBtnFinder, findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // 3. Click sliding delete button -> opens CartDeleteBottomSheet
      await tester.tap(deleteBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Bottom sheet is displayed with item name, size, price, and action buttons
      expect(find.text('Remove from Cart'), findsOneWidget);
      expect(find.text('Are you sure you want to remove this item from your cart?'), findsOneWidget);
      expect(find.text('Kemeja Batik Sogan Modern'), findsWidgets);
      expect(find.text('Size: XL'), findsWidgets);
      expect(find.text('Rp 200.000'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Yes, Remove'), findsOneWidget);

      // 4. Tap Cancel -> closes bottom sheet without removing item
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Remove from Cart'), findsNothing);
      expect(find.text('Kemeja Batik Sogan Modern'), findsOneWidget);

      // 5. Tap sliding delete again and confirm with 'Yes, Remove'
      await tester.tap(deleteBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Yes, Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Item is removed from the cart
      expect(mockRepo.deletedCartId, 1);
    });
  });
}

