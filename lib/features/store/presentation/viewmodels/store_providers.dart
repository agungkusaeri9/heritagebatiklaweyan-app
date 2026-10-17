import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/store_remote_data_source.dart';
import '../../data/models/faq_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/store_setting_model.dart';
import 'store_state.dart';
import 'store_viewmodel.dart';

// === REMOTE DATA SOURCE ===
final storeRemoteDataSourceProvider = Provider<StoreRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final dioClient = ref.watch(dioClientProvider);
  return StoreRemoteDataSourceImpl(dio: dio, dioClient: dioClient);
});

// === STORE VIEW MODEL (STATE RIVERPOD) ===
final storeViewModelProvider = NotifierProvider<StoreViewModel, StoreState>(() {
  return StoreViewModel();
});

// === CONVENIENCE SELECTORS (Bisa digunakan langsung di View/Widget) ===
final currentStoreSettingProvider = Provider<StoreSettingModel?>((ref) {
  return ref.watch(storeViewModelProvider.select((state) => state.storeSetting));
});

final activePaymentMethodsProvider = Provider<List<PaymentMethodModel>>((ref) {
  return ref.watch(storeViewModelProvider.select((state) => state.paymentMethods));
});

final activeFaqsProvider = Provider<List<FaqModel>>((ref) {
  return ref.watch(storeViewModelProvider.select((state) => state.faqs));
});
