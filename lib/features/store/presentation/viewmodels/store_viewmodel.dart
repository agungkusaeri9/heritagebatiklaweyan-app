import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/store_remote_data_source.dart';
import '../../data/models/faq_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/store_setting_model.dart';
import 'store_providers.dart';
import 'store_state.dart';

/// ViewModel untuk mengelola state pengaturan toko, metode pembayaran, dan FAQ di memory
class StoreViewModel extends Notifier<StoreState> {
  late final StoreRemoteDataSource _remoteDataSource;

  @override
  StoreState build() {
    _remoteDataSource = ref.watch(storeRemoteDataSourceProvider);
    return const StoreState();
  }

  /// Memuat data toko, metode pembayaran, dan FAQ dari backend API ke state
  Future<void> fetchInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    AppLogger.i('StoreViewModel: Mengambil data toko, metode pembayaran & FAQ ke state...');

    try {
      final results = await Future.wait([
        _remoteDataSource.getStoreSetting(),
        _remoteDataSource.getPaymentMethods(),
        _remoteDataSource.getFaqs(),
      ]);

      final setting = results[0] as StoreSettingModel;
      final methods = results[1] as List<PaymentMethodModel>;
      final faqs = results[2] as List<FaqModel>;

      state = state.copyWith(
        isLoading: false,
        storeSetting: setting,
        paymentMethods: methods,
        faqs: faqs,
        clearError: true,
      );

      AppLogger.i(
        'StoreViewModel: Berhasil menyimpan data ke state! '
        'Toko: "${setting.name}", Metode: ${methods.length}, FAQ: ${faqs.length}',
      );
    } catch (e, stack) {
      AppLogger.w('StoreViewModel: Gagal memuat data ke state', e, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
