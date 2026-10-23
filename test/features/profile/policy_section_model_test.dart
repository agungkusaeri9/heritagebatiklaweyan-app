import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/profile/data/models/policy_section_model.dart';
import 'package:heritage_batik/features/store/data/models/store_setting_model.dart';

void main() {
  group('PolicySectionModel Test', () {
    test('Parses Cancellation Policy, Terms & Conditions, and Privacy Policy correctly', () {
      const policyString = '''
1. KETENTUAN PEMESANAN & PEMBAYARAN
- Pesanan diproses setelah pembayaran terkonfirmasi.

3. KETENTUAN PEMBATALAN PESANAN (CANCELLATION POLICY)
- Pembatalan hanya dapat diajukan sebelum pesanan dikirim.

4. KEBIJAKAN PENGEMBALIAN & PENUKARAN (RETURN & REFUND)
- Wajib sertakan video unboxing.
''';

      const privacyString = '''
1. PENGUMPULAN INFORMASI PRIBADI
Kami mengumpulkan nama dan alamat untuk pengiriman pesanan.
''';

      const setting = StoreSettingModel(
        name: 'Heritage Batik Laweyan',
        policy: policyString,
        privacyPolicy: privacyString,
        updatedAt: '2026-10-12T14:54:45.000000Z',
      );

      final sections = PolicySectionModel.fromStoreSetting(setting);

      expect(sections.length, 3);

      // Section 1: Cancellation Policy
      expect(sections[0].id, 'cancellation_policy');
      expect(sections[0].title, 'Cancellation Policy');
      expect(sections[0].content, contains('Pembatalan hanya dapat diajukan'));

      // Section 2: Terms & Conditions
      expect(sections[1].id, 'terms_conditions');
      expect(sections[1].title, 'Terms & Conditions');
      expect(sections[1].content, contains('KETENTUAN PEMESANAN'));
      expect(sections[1].content, contains('KEBIJAKAN PENGEMBALIAN'));

      // Section 3: Privacy Policy
      expect(sections[2].id, 'privacy_policy');
      expect(sections[2].title, 'Privacy Policy');
      expect(sections[2].content, contains('PENGUMPULAN INFORMASI PRIBADI'));
    });

    test('Uses explicit cancellationPolicy column when present', () {
      const setting = StoreSettingModel(
        name: 'Heritage Batik Laweyan',
        cancellationPolicy: 'Ketentuan pembatalan dari kolom khusus.',
        policy: 'Ketentuan umum toko.',
        privacyPolicy: 'Ketentuan privasi toko.',
      );

      final sections = PolicySectionModel.fromStoreSetting(setting);
      expect(sections.length, 3);
      expect(sections[0].id, 'cancellation_policy');
      expect(sections[0].title, 'Cancellation Policy');
      expect(sections[0].content, 'Ketentuan pembatalan dari kolom khusus.');
      expect(sections[1].id, 'terms_conditions');
      expect(sections[1].content, 'Ketentuan umum toko.');
      expect(sections[2].id, 'privacy_policy');
      expect(sections[2].content, 'Ketentuan privasi toko.');
    });

    test('Returns empty list when policies are empty', () {
      const setting = StoreSettingModel(
        name: 'Heritage Batik Laweyan',
        policy: '',
        privacyPolicy: '',
      );

      final sections = PolicySectionModel.fromStoreSetting(setting);
      expect(sections.isEmpty, isTrue);
    });
  });
}
