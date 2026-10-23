import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/store/data/models/faq_model.dart';
import 'package:heritage_batik/features/store/data/models/payment_method_model.dart';
import 'package:heritage_batik/features/store/data/models/store_setting_model.dart';

void main() {
  group('Store Models Test', () {
    test('StoreSettingModel serialization and SQLite mapping', () {
      final json = {
        'name': 'Heritage Batik Laweyan',
        'logo_url': 'https://example.com/logo.png',
        'description': 'Toko Batik Terbaik di Solo',
        'contact': {
          'phone': '0271-714000',
          'whatsapp': '6281234567890',
          'email': 'cs@heritagebatik.com',
          'website': 'https://heritagebatiklaweyan.com',
        },
        'social_media': {
          'facebook_url': 'https://facebook.com/heritagebatik',
          'twitter_url': 'https://x.com/heritagebatik',
          'instagram_url': 'https://instagram.com/heritagebatik',
        },
        'address': 'Kampung Batik Laweyan, Surakarta',
        'policies': {
          'privacy_policy': 'Kebijakan privasi',
          'policy': 'Ketentuan toko',
          'cancellation_policy': 'Kebijakan pembatalan pesanan',
        },
        'updated_at': '2026-03-01T12:00:00Z',
      };

      final model = StoreSettingModel.fromJson(json);
      expect(model.name, 'Heritage Batik Laweyan');
      expect(model.phone, '0271-714000');
      expect(model.whatsapp, '6281234567890');
      expect(model.privacyPolicy, 'Kebijakan privasi');
      expect(model.cancellationPolicy, 'Kebijakan pembatalan pesanan');

      final map = model.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Heritage Batik Laweyan');
      expect(map['whatsapp'], '6281234567890');
      expect(map['cancellation_policy'], 'Kebijakan pembatalan pesanan');

      final fromDb = StoreSettingModel.fromMap(map);
      expect(fromDb.name, model.name);
      expect(fromDb.phone, model.phone);
      expect(fromDb.whatsapp, model.whatsapp);
      expect(fromDb.address, model.address);
      expect(fromDb.cancellationPolicy, model.cancellationPolicy);
    });

    test('PaymentMethodModel serialization and SQLite mapping', () {
      final json = {
        'id': 1,
        'name': 'Bank Central Asia (BCA)',
        'account_name': 'PT Heritage Batik Laweyan',
        'account_number': '8830192841',
        'logo_url': 'https://example.com/bca.png',
        'is_active': true,
      };

      final model = PaymentMethodModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name, 'Bank Central Asia (BCA)');
      expect(model.accountNumber, '8830192841');
      expect(model.isActive, isTrue);

      final map = model.toMap();
      expect(map['is_active'], 1);

      final fromDb = PaymentMethodModel.fromMap(map);
      expect(fromDb.id, 1);
      expect(fromDb.name, model.name);
      expect(fromDb.accountNumber, model.accountNumber);
      expect(fromDb.isActive, isTrue);
    });

    test('FaqModel serialization', () {
      final json = {
        'id': 1,
        'title': 'Bagaimana cara memesan?',
        'description': 'Pilih produk dan checkout.',
        'category': 'Pemesanan',
        'order': 1,
        'is_active': true,
      };

      final model = FaqModel.fromJson(json);
      expect(model.id, 1);
      expect(model.title, 'Bagaimana cara memesan?');
      expect(model.category, 'Pemesanan');
      expect(model.order, 1);
      expect(model.isActive, isTrue);
    });
  });
}
