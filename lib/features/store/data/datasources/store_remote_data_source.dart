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
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil pengaturan toko', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
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
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil metode pembayaran', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
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
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil daftar FAQ', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil daftar FAQ: $e');
    }
  }
}

