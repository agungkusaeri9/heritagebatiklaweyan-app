import '../../../store/data/models/payment_method_model.dart';
import '../datasources/checkout_remote_data_source.dart';
import '../models/checkout_result_model.dart';
import '../models/customer_address_model.dart';
import '../models/order_pagination_model.dart';
import '../models/order_review_model.dart';
import '../models/region_model.dart';
import '../models/shipping_type_model.dart';

abstract class CheckoutRepository {
  Future<List<CustomerAddressModel>> getAddresses();
  Future<CustomerAddressModel> addAddress(Map<String, dynamic> data);
  Future<bool> setPrimaryAddress(int addressId);
  Future<List<ShippingTypeModel>> getShippingTypes();
  Future<List<ShippingTypeModel>> checkShippingCost({
    required dynamic destination,
    required int weight,
    String? courier,
    dynamic origin,
  });
  Future<List<PaymentMethodModel>> getPaymentMethods();
  Future<CheckoutResultModel> processCheckout(Map<String, dynamic> payload);
  Future<PaginatedOrdersResult> getOrders({
    String? status,
    String? search,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  });
  Future<CheckoutResultModel> getOrderDetail(dynamic idOrOrderNumber);
  Future<CheckoutResultModel> uploadPaymentProof({
    required dynamic idOrOrderNumber,
    required String filePath,
  });
  Future<CheckoutResultModel> submitOrderReviews({
    required CheckoutResultModel order,
    required int transactionRating,
    String? transactionComment,
    required List<OrderItemReviewModel> productReviews,
  });
  Future<List<ProvinceModel>> getProvinces();
  Future<List<CityModel>> getCities(int provinceId);
  Future<List<SubdistrictModel>> getSubdistricts(int cityId);
}

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource remoteDataSource;

  CheckoutRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CustomerAddressModel>> getAddresses() {
    return remoteDataSource.getAddresses();
  }

  @override
  Future<CustomerAddressModel> addAddress(Map<String, dynamic> data) {
    return remoteDataSource.addAddress(data);
  }

  @override
  Future<bool> setPrimaryAddress(int addressId) {
    return remoteDataSource.setPrimaryAddress(addressId);
  }

  @override
  Future<List<ShippingTypeModel>> getShippingTypes() {
    return remoteDataSource.getShippingTypes();
  }

  @override
  Future<List<ShippingTypeModel>> checkShippingCost({
    required dynamic destination,
    required int weight,
    String? courier,
    dynamic origin,
  }) {
    return remoteDataSource.checkShippingCost(
      destination: destination,
      weight: weight,
      courier: courier,
      origin: origin,
    );
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() {
    return remoteDataSource.getPaymentMethods();
  }

  @override
  Future<CheckoutResultModel> processCheckout(Map<String, dynamic> payload) {
    return remoteDataSource.processCheckout(payload);
  }

  @override
  Future<PaginatedOrdersResult> getOrders({
    String? status,
    String? search,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) {
    return remoteDataSource.getOrders(
      status: status,
      search: search,
      page: page,
      perPage: perPage,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<CheckoutResultModel> getOrderDetail(dynamic idOrOrderNumber) {
    return remoteDataSource.getOrderDetail(idOrOrderNumber);
  }

  @override
  Future<CheckoutResultModel> uploadPaymentProof({
    required dynamic idOrOrderNumber,
    required String filePath,
  }) {
    return remoteDataSource.uploadPaymentProof(
      idOrOrderNumber: idOrOrderNumber,
      filePath: filePath,
    );
  }

  @override
  Future<CheckoutResultModel> submitOrderReviews({
    required CheckoutResultModel order,
    required int transactionRating,
    String? transactionComment,
    required List<OrderItemReviewModel> productReviews,
  }) {
    return remoteDataSource.submitOrderReviews(
      order: order,
      transactionRating: transactionRating,
      transactionComment: transactionComment,
      productReviews: productReviews,
    );
  }

  @override
  Future<List<ProvinceModel>> getProvinces() {
    return remoteDataSource.getProvinces();
  }

  @override
  Future<List<CityModel>> getCities(int provinceId) {
    return remoteDataSource.getCities(provinceId);
  }

  @override
  Future<List<SubdistrictModel>> getSubdistricts(int cityId) {
    return remoteDataSource.getSubdistricts(cityId);
  }
}
