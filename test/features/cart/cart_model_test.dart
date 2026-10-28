import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/cart/data/models/cart_item_model.dart';
import 'package:heritage_batik/features/cart/data/models/cart_summary_model.dart';

void main() {
  group('CartItemModel Tests', () {
    test('CartItemModel parses JSON correctly', () {
      final json = {
        'id': 1,
        'product_id': 12,
        'product_name': 'Kemeja Batik Sogan Klasik',
        'product_slug': 'kemeja-batik-sogan-klasik',
        'primary_image': 'https://example.com/batik1.jpg',
        'product_price': 250000.0,
        'qty': 2,
        'total': 500000.0,
        'variant_info': 'XL',
        'weight': 300,
        'total_weight': 600,
        'stock': 15,
        'is_in_stock': true,
        'is_product_active': true,
      };

      final item = CartItemModel.fromJson(json);

      expect(item.id, 1);
      expect(item.productId, 12);
      expect(item.productName, 'Kemeja Batik Sogan Klasik');
      expect(item.productPrice, 250000.0);
      expect(item.qty, 2);
      expect(item.total, 500000.0);
      expect(item.displayVariant, 'Size: XL');
      expect(item.weight, 300);
      expect(item.totalWeight, 600);
      expect(item.stock, 15);
      expect(item.isInStock, isTrue);
      expect(item.formattedPrice, 'Rp 250.000');
      expect(item.formattedTotal, 'Rp 500.000');
    });

    test('CartItemModel copyWith updates fields properly', () {
      const item = CartItemModel(
        id: 1,
        productId: 10,
        productName: 'Kain Jarik',
        productPrice: 180000.0,
        qty: 1,
        total: 180000.0,
      );

      final updated = item.copyWith(qty: 3, total: 540000.0);

      expect(updated.id, 1);
      expect(updated.qty, 3);
      expect(updated.total, 540000.0);
      expect(updated.formattedTotal, 'Rp 540.000');
    });

    test('formatRupiah formats currency properly', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(15000), 'Rp 15.000');
      expect(formatRupiah(250000), 'Rp 250.000');
      expect(formatRupiah(1500000), 'Rp 1.500.000');
    });
  });

  group('CartSummaryModel Tests', () {
    test('CartSummaryModel parses summary JSON and calculates totalCost correctly', () {
      final json = {
        'total_items': 3,
        'total_weight': 900,
        'total_price': 450000.0,
      };

      final summary = CartSummaryModel.fromJson(
        json,
        deliveryFee: 15000.0,
        discount: 25000.0,
      );

      expect(summary.totalItems, 3);
      expect(summary.totalWeight, 900);
      expect(summary.subtotal, 450000.0);
      expect(summary.deliveryFee, 15000.0);
      expect(summary.discount, 25000.0);
      expect(summary.totalCost, 440000.0);
      expect(summary.formattedSubtotal, 'Rp 450.000');
      expect(summary.formattedDeliveryFee, 'Rp 15.000');
      expect(summary.formattedDiscount, '-Rp 25.000');
      expect(summary.formattedTotalCost, 'Rp 440.000');
    });

    test('CartSummaryModel formattedDeliveryFee returns Free when 0', () {
      const summary = CartSummaryModel(
        totalItems: 1,
        totalWeight: 200,
        subtotal: 100000.0,
        deliveryFee: 0.0,
        discount: 0.0,
        totalCost: 100000.0,
      );

      expect(summary.formattedDeliveryFee, 'Free');
      expect(summary.formattedDiscount, 'Rp 0');
    });
  });
}
