import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/faq_model.dart';
import '../models/payment_method_model.dart';
import '../models/store_setting_model.dart';

abstract class StoreRemoteDataSource {
  Future<StoreSettingModel> getStoreSetting();
  Future<List<PaymentMethodModel>> getPaymentMethods();
  Future<List<FaqModel>> getFaqs();
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  StoreRemoteDataSourceImpl({
    required this.dio,
    required this.dioClient,
  });

  @override
  Future<StoreSettingModel> getStoreSetting() async {
    try {
      AppLogger.d('StoreRemoteDataSource: Mengambil data toko dari ${ApiConstants.settings}');
      final response = await dio.get(ApiConstants.settings);

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'] as Map<String, dynamic>;
        return StoreSettingModel.fromJson(data);
      }
      throw const ApiException(message: 'Format respon data toko tidak sesuai');
    } on DioException catch (dioErr) {
      if (_isNetworkOrMockable(dioErr)) {
        AppLogger.w('Backend offline/unreachable. Menggunakan data toko default (seeder offline).');
        return _mockStoreSetting();
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil pengaturan toko', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil pengaturan toko: $e');
    }
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      AppLogger.d('StoreRemoteDataSource: Mengambil metode pembayaran dari ${ApiConstants.paymentMethods}');
      final response = await dio.get(ApiConstants.paymentMethods);

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final list = responseData['data'] as List<dynamic>;
        return list
            .map((item) => PaymentMethodModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (dioErr) {
      if (_isNetworkOrMockable(dioErr)) {
        AppLogger.w('Backend offline/unreachable. Menggunakan metode pembayaran default (seeder offline).');
        return _mockPaymentMethods();
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil metode pembayaran', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil metode pembayaran: $e');
    }
  }

  @override
  Future<List<FaqModel>> getFaqs() async {
    try {
      AppLogger.d('StoreRemoteDataSource: Mengambil data FAQ dari ${ApiConstants.faqs}');
      final response = await dio.get(ApiConstants.faqs);

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final list = responseData['data'] as List<dynamic>;
        return list
            .map((item) => FaqModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (dioErr) {
      if (_isNetworkOrMockable(dioErr)) {
        AppLogger.w('Backend offline/unreachable. Menggunakan FAQ default (seeder offline).');
        return _mockFaqs();
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil daftar FAQ', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil daftar FAQ: $e');
    }
  }

  bool _isNetworkOrMockable(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.message?.contains('heritagebatiklaweyan.com') == true ||
        err.message?.contains('10.0.2.2') == true ||
        err.message?.contains('127.0.0.1') == true ||
        err.message?.contains('localhost') == true ||
        err.message?.contains('Failed host lookup') == true ||
        err.message?.contains('Connection refused') == true;
  }

  StoreSettingModel _mockStoreSetting() {
    return const StoreSettingModel(
      id: 1,
      name: 'Heritage Batik Laweyan',
      logoUrl: null,
      phone: '0274-1234567',
      whatsapp: '6281234567890',
      email: 'cs@heritagebatiklaweyan.com',
      website: 'https://heritagebatiklaweyan.com',
      facebookUrl: 'https://facebook.com/heritagebatiklaweyan',
      twitterUrl: 'https://x.com/heritagebatik',
      instagramUrl: 'https://instagram.com/heritagebatiklaweyan',
      description: 'Pusat batik nusantara autentik dan modern. Menghadirkan berbagai koleksi batik tulis, cap, dan kombinasi premium dari Kampung Laweyan Solo.',
      address: 'Jl. Laweyan No. 45, Solo, Jawa Tengah',
      privacyPolicy: 'Kebijakan privasi pelanggan Heritage Batik Laweyan.',
      policy: 'Ketentuan pemesanan dan pengembalian barang Heritage Batik Laweyan.',
      updatedAt: '2026-03-01T12:00:00.000000Z',
    );
  }

  List<PaymentMethodModel> _mockPaymentMethods() {
    return const [
      PaymentMethodModel(
        id: 1,
        name: 'Bank Central Asia (BCA)',
        accountName: 'Heritage Batik Laweyan',
        accountNumber: '8830192841',
        isActive: true,
      ),
      PaymentMethodModel(
        id: 2,
        name: 'Bank Mandiri',
        accountName: 'Heritage Batik Laweyan',
        accountNumber: '1370019284712',
        isActive: true,
      ),
      PaymentMethodModel(
        id: 3,
        name: 'Bank Rakyat Indonesia (BRI)',
        accountName: 'Heritage Batik Laweyan',
        accountNumber: '034101000789562',
        isActive: true,
      ),
      PaymentMethodModel(
        id: 4,
        name: 'QRIS Instant Payment',
        accountName: 'Heritage Batik Laweyan Official',
        accountNumber: 'NMID-9382109283',
        isActive: true,
      ),
    ];
  }

  List<FaqModel> _mockFaqs() {
    return const [
      FaqModel(
        id: 1,
        title: 'Bagaimana cara memesan batik di toko ini?',
        description: 'Pilih produk batik yang Anda inginkan, tentukan varian ukuran/motif, klik tombol Tambah ke Keranjang atau Beli Sekarang, lalu lanjutkan ke checkout.',
        category: 'Pemesanan',
        order: 1,
        isActive: true,
      ),
      FaqModel(
        id: 2,
        title: 'Apakah batik yang dijual merupakan batik asli (tulis/cap)?',
        description: 'Ya, kami menyediakan berbagai jenis batik autentik meliputi Batik Tulis Asli (Handmade), Batik Cap, dan Batik Kombinasi berkualitas tinggi.',
        category: 'Produk Batik',
        order: 2,
        isActive: true,
      ),
      FaqModel(
        id: 3,
        title: 'Metode pembayaran apa saja yang didukung?',
        description: 'Kami mendukung transfer bank BCA, Mandiri, BRI, serta QRIS instant payment.',
        category: 'Pembayaran',
        order: 3,
        isActive: true,
      ),
    ];
  }
}
