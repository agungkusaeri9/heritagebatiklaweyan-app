import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../store/data/models/payment_method_model.dart';
import '../models/checkout_result_model.dart';
import '../models/customer_address_model.dart';
import '../models/order_pagination_model.dart';
import '../models/order_review_model.dart';
import '../models/region_model.dart';
import '../models/shipping_type_model.dart';

abstract class CheckoutRemoteDataSource {
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

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;
  final Map<String, CheckoutResultModel> _orderDetailCache = {};
  final Map<String, CheckoutResultModel> _reviewedOrderOverlay = {};

  CheckoutRemoteDataSourceImpl({required this.dio, required this.dioClient});

  @override
  Future<List<CustomerAddressModel>> getAddresses() async {
    try {
      AppLogger.d('Mengambil daftar alamat dari ${ApiConstants.addresses}');
      final response = await dio.get(ApiConstants.addresses);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final listData = responseData['data'];
        if (listData is List) {
          return listData
              .map(
                (item) =>
                    CustomerAddressModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      }
      return [];
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil alamat',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil alamat', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal memuat daftar alamat.');
    }
  }

  @override
  Future<CustomerAddressModel> addAddress(Map<String, dynamic> data) async {
    try {
      AppLogger.d(
        'Menambahkan alamat baru ke ${ApiConstants.addresses}: $data',
      );
      final response = await dio.post(ApiConstants.addresses, data: data);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        return CustomerAddressModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }
      throw const ServerException(
        message: 'Format respon tambah alamat tidak valid.',
      );
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat menambah alamat',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Gagal menambah alamat', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal menambahkan alamat baru.');
    }
  }

  @override
  Future<bool> setPrimaryAddress(int addressId) async {
    try {
      AppLogger.d('Mengubah alamat utama ke ID $addressId');
      final response = await dio.patch(ApiConstants.addressPrimary(addressId));
      return response.statusCode == 200;
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat set alamat utama',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Gagal set alamat utama', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal mengubah alamat utama.');
    }
  }

  @override
  Future<List<ShippingTypeModel>> getShippingTypes() async {
    try {
      AppLogger.d('Mengambil daftar kurir dari ${ApiConstants.couriers}');
      Response response;
      try {
        response = await dio.get(ApiConstants.couriers);
      } catch (_) {
        response = await dio.get(ApiConstants.shippingTypes);
      }

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final listData = responseData['data'];
        if (listData is List) {
          final list = listData
              .map(
                (item) =>
                    ShippingTypeModel.fromJson(item as Map<String, dynamic>),
              )
              .where((c) => c.isActive)
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
      return _fallbackShippingTypes();
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil kurir',
        error: e,
        stackTrace: stack,
      );
      return _fallbackShippingTypes();
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil kurir', error: e, stackTrace: stack);
      return _fallbackShippingTypes();
    }
  }

  @override
  Future<List<ShippingTypeModel>> checkShippingCost({
    required dynamic destination,
    required int weight,
    String? courier,
    dynamic origin,
  }) async {
    try {
      final payload = {
        'destination': destination,
        'weight': weight > 0 ? weight : 1000,
        if (courier != null && courier.isNotEmpty) 'courier': courier,
        ...?origin == null ? null : {'origin': origin},
      };

      AppLogger.d(
        'Mengecek ongkos kirim ke ${ApiConstants.checkShippingCost}: $payload',
      );
      final response = await dio.post(
        ApiConstants.checkShippingCost,
        data: payload,
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final listData = responseData['data'];
        if (listData is List) {
          final List<ShippingTypeModel> shippingList = [];
          int optionIndex = 1;

          for (final item in listData) {
            if (item is Map<String, dynamic>) {
              final courierCode =
                  item['code']?.toString().toLowerCase() ?? 'std';
              final serviceName = item['service']?.toString() ?? 'REG';
              final courierName =
                  item['name']?.toString() ?? courierCode.toUpperCase();
              final desc =
                  item['description']?.toString() ?? 'Layanan Pengiriman';
              final costVal = (item['cost'] as num?)?.toDouble() ?? 0.0;
              final etdVal =
                  item['estimated_delivery']?.toString() ??
                  (item['etd'] != null ? '${item['etd']} hari' : '2-3 hari');

              // Map courierCode to ID in couriers table (1: JNE, 2: POS, 3: TIKI)
              int courierId = 1;
              if (courierCode.contains('pos')) {
                courierId = 2;
              } else if (courierCode.contains('tiki')) {
                courierId = 3;
              }

              // ID unik per opsi agar layanan dari kurir yang sama tidak bentrok (misal JNE Trucking vs Regular)
              final uniqueOptionId = (courierId * 1000) + (optionIndex++);

              shippingList.add(
                ShippingTypeModel(
                  id: uniqueOptionId,
                  courierId: courierId,
                  name: '$courierName - $serviceName',
                  code: '${courierCode}_$serviceName'.toLowerCase(),
                  description: desc,
                  fee: costVal,
                  estimatedDays: 'Estimasi Tiba $etdVal',
                  isActive: true,
                ),
              );
            }
          }

          if (shippingList.isNotEmpty) {
            return shippingList;
          }
        }
      }
      return [];
    } on DioException catch (e, stack) {
      AppLogger.e('DioException saat cek ongkir', error: e, stackTrace: stack);
      return [];
    } catch (e, stack) {
      AppLogger.e('Gagal cek ongkir', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      AppLogger.d(
        'Mengambil daftar metode pembayaran dari ${ApiConstants.paymentMethods}',
      );
      final response = await dio.get(ApiConstants.paymentMethods);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final listData = responseData['data'];
        if (listData is List) {
          final list = listData
              .map(
                (item) =>
                    PaymentMethodModel.fromJson(item as Map<String, dynamic>),
              )
              .where((m) => m.isActive)
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
      return _fallbackPaymentMethods();
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil metode pembayaran',
        error: e,
        stackTrace: stack,
      );
      return _fallbackPaymentMethods();
    } catch (e, stack) {
      AppLogger.e(
        'Gagal mengambil metode pembayaran',
        error: e,
        stackTrace: stack,
      );
      return _fallbackPaymentMethods();
    }
  }

  List<PaymentMethodModel> _fallbackPaymentMethods() {
    return const [
      PaymentMethodModel(
        id: 1,
        name: 'Bank Central Asia (BCA)',
        accountName: 'PT Batik Nusantara',
        accountNumber: '8830192841',
        isActive: true,
      ),
      PaymentMethodModel(
        id: 2,
        name: 'Bank Mandiri',
        accountName: 'PT Batik Nusantara',
        accountNumber: '1370019284712',
        isActive: true,
      ),
      PaymentMethodModel(
        id: 3,
        name: 'Bank Rakyat Indonesia (BRI)',
        accountName: 'PT Batik Nusantara',
        accountNumber: '034101000789562',
        isActive: true,
      ),
      PaymentMethodModel(
        id: 4,
        name: 'QRIS Instant Payment',
        accountName: 'Batik Nusantara Official',
        accountNumber: 'NMID-9382109283',
        isActive: true,
      ),
    ];
  }

  @override
  Future<CheckoutResultModel> processCheckout(
    Map<String, dynamic> payload,
  ) async {
    try {
      AppLogger.d('Memproses checkout ke ${ApiConstants.checkout}: $payload');
      final response = await dio.post(ApiConstants.checkout, data: payload);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final result = CheckoutResultModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        if (result.orderNumber.isNotEmpty) {
          _orderDetailCache[result.orderNumber] = result;
        }
        return result;
      }
      throw const ServerException(
        message: 'Format respon checkout tidak valid.',
      );
    } on DioException catch (e, stack) {
      AppLogger.e('DioException saat checkout', error: e, stackTrace: stack);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Gagal memproses checkout', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal memproses pesanan Anda.');
    }
  }

  List<ShippingTypeModel> _fallbackShippingTypes() {
    return const [
      ShippingTypeModel(
        id: 1,
        name: 'Jalur Nugraha Ekakurir (JNE)',
        code: 'jne',
        description: 'Layanan pengiriman JNE Reguler (Est. 2 - 3 Hari)',
        fee: 15000.0,
        estimatedDays: 'Estimated Arrival 2 - 3 Days',
      ),
      ShippingTypeModel(
        id: 2,
        name: 'POS Indonesia',
        code: 'pos',
        description: 'Layanan pengiriman Pos Kilat Khusus (Est. 3 - 5 Hari)',
        fee: 12000.0,
        estimatedDays: 'Estimated Arrival 3 - 5 Days',
      ),
      ShippingTypeModel(
        id: 3,
        name: 'Citra Van Titipan Kilat (TIKI)',
        code: 'tiki',
        description: 'Layanan pengiriman TIKI Reguler (Est. 1 - 2 Hari)',
        fee: 18000.0,
        estimatedDays: 'Estimated Arrival 1 - 2 Days',
      ),
    ];
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    try {
      final response = await dio.get(ApiConstants.provinces);
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final list = responseData['data'];
        if (list is List) {
          return list
              .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil provinsi',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CityModel>> getCities(int provinceId) async {
    try {
      final response = await dio.get(
        ApiConstants.cities(provinceId: provinceId),
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final list = responseData['data'];
        if (list is List) {
          return list
              .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil kota',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SubdistrictModel>> getSubdistricts(int cityId) async {
    try {
      final response = await dio.get(ApiConstants.subdistricts(cityId: cityId));
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final list = responseData['data'];
        if (list is List) {
          return list
              .map((e) => SubdistrictModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil kecamatan',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PaginatedOrdersResult> getOrders({
    String? status,
    String? search,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        _orderDetailCache.clear();
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      AppLogger.d(
        'Mengambil daftar pesanan dari ${ApiConstants.orders} dengan query: $queryParams',
      );
      final response = await dio.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final paginated = PaginatedOrdersResult.fromJson(responseData);

        // Jika OrderListResource dari backend belum menyertakan array `items`,
        // perkaya secara paralel menggunakan endpoint detail pesanan (dengan cache memori)
        final enrichedOrders = await Future.wait(
          paginated.orders.map((order) async {
            if (order.items.isNotEmpty) {
              if (order.orderNumber.isNotEmpty) {
                _orderDetailCache[order.orderNumber] = order;
              }
              return order;
            }

            final cacheKey = order.orderNumber.isNotEmpty
                ? order.orderNumber
                : order.id.toString();

            if (!forceRefresh && _orderDetailCache.containsKey(cacheKey)) {
              return order.mergeWithDetail(_orderDetailCache[cacheKey]!);
            }

            try {
              final identifier = order.orderNumber.isNotEmpty
                  ? order.orderNumber
                  : order.id;
              final detail = await getOrderDetail(identifier);
              final merged = order.mergeWithDetail(detail);
              _orderDetailCache[cacheKey] = merged;
              return merged;
            } catch (_) {
              return order;
            }
          }),
        );

        return paginated.copyWith(orders: enrichedOrders);
      }

      throw const ServerException(
        message: 'Format respon daftar pesanan tidak valid.',
      );
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil daftar pesanan',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e(
        'Gagal mengambil daftar pesanan',
        error: e,
        stackTrace: stack,
      );
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal memuat daftar pesanan.');
    }
  }

  @override
  Future<CheckoutResultModel> getOrderDetail(dynamic idOrOrderNumber) async {
    try {
      AppLogger.d(
        'Mengambil detail pesanan dari ${ApiConstants.orderDetail(idOrOrderNumber)}',
      );
      final response = await dio.get(ApiConstants.orderDetail(idOrOrderNumber));
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        var result = CheckoutResultModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        final key = result.orderNumber.isNotEmpty
            ? result.orderNumber
            : result.id.toString();
        if (_reviewedOrderOverlay.containsKey(key)) {
          result = _applyReviewOverlay(result, _reviewedOrderOverlay[key]!);
        }
        if (result.orderNumber.isNotEmpty) {
          _orderDetailCache[result.orderNumber] = result;
        }
        return result;
      }
      throw const ServerException(
        message: 'Format respon detail pesanan tidak valid.',
      );
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengambil detail pesanan',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e(
        'Gagal mengambil detail pesanan',
        error: e,
        stackTrace: stack,
      );
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal memuat detail pesanan.');
    }
  }

  CheckoutResultModel _applyReviewOverlay(
    CheckoutResultModel base,
    CheckoutResultModel overlay,
  ) {
    final mergedReviewsMap = <int, OrderItemReviewModel>{};
    for (final rev in base.reviews) {
      mergedReviewsMap[rev.productId] = rev;
    }
    for (final rev in overlay.reviews) {
      final existing = mergedReviewsMap[rev.productId];
      mergedReviewsMap[rev.productId] = existing != null
          ? existing.copyWith(
              photoPaths: rev.photoPaths.isNotEmpty
                  ? rev.photoPaths
                  : existing.photoPaths,
            )
          : rev;
    }

    final updatedItems = base.items.map((item) {
      final matched = mergedReviewsMap[item.productId] ?? item.review;
      if (matched != null) {
        return item.copyWith(isReviewed: true, review: matched);
      }
      return item;
    }).toList();

    return base.copyWith(
      items: updatedItems,
      isReviewedExplicit: base.isReviewedExplicit || overlay.isReviewedExplicit,
      reviewedCount: mergedReviewsMap.length > base.reviewedCount
          ? mergedReviewsMap.length
          : base.reviewedCount,
      averageRating: base.averageRating ?? overlay.averageRating,
      transactionRating: overlay.transactionRating ?? base.transactionRating,
      transactionReviewComment:
          overlay.transactionReviewComment ?? base.transactionReviewComment,
      reviews: mergedReviewsMap.values.toList(),
    );
  }

  @override
  Future<CheckoutResultModel> submitOrderReviews({
    required CheckoutResultModel order,
    required int transactionRating,
    String? transactionComment,
    required List<OrderItemReviewModel> productReviews,
  }) async {
    try {
      final submittedReviews = <OrderItemReviewModel>[];

      for (final itemReview in productReviews) {
        final alreadyReviewedOnOrder =
            order.reviewForProduct(itemReview.productId) != null;
        if (alreadyReviewedOnOrder) {
          submittedReviews.add(itemReview);
          continue;
        }

        final payload = <String, dynamic>{
          'order_id': order.id,
          'product_id': itemReview.productId,
          'rating': itemReview.rating,
          if (itemReview.comment != null &&
              itemReview.comment!.trim().isNotEmpty)
            'comment': itemReview.comment!.trim(),
        };

        try {
          AppLogger.d(
            'Mengirim ulasan produk ${itemReview.productId} pada order #${order.id} ke ${ApiConstants.reviews}',
          );
          final response = await dio.post(ApiConstants.reviews, data: payload);
          final responseData = response.data;
          if (responseData is Map<String, dynamic> &&
              responseData['data'] is Map<String, dynamic>) {
            final parsed = OrderItemReviewModel.fromJson(
              responseData['data'] as Map<String, dynamic>,
              fallbackOrderId: order.id,
              fallbackProductId: itemReview.productId,
            ).copyWith(photoPaths: itemReview.photoPaths);
            submittedReviews.add(parsed);
          } else {
            submittedReviews.add(
              itemReview.copyWith(
                orderId: order.id,
                createdAt: DateTime.now(),
              ),
            );
          }
        } on DioException catch (e) {
          // Jika produk sudah pernah diulas di server (422), tetap tandai sebagai sudah diulas
          final statusCode = e.response?.statusCode ?? 0;
          final msg = e.response?.data?.toString().toLowerCase() ?? '';
          if (statusCode == 422 &&
              (msg.contains('sudah memberikan ulasan') ||
                  msg.contains('already'))) {
            submittedReviews.add(
              itemReview.copyWith(
                orderId: order.id,
                createdAt: DateTime.now(),
              ),
            );
          } else {
            rethrow;
          }
        }
      }

      // Gabungkan ulasan baru dengan ulasan produk yang sudah ada sebelumnya di pesanan ini
      final allReviewsMap = <int, OrderItemReviewModel>{};
      for (final existing in order.reviews) {
        allReviewsMap[existing.productId] = existing;
      }
      for (final item in order.items) {
        if (item.review != null) {
          allReviewsMap[item.productId] = item.review!;
        }
      }
      for (final submitted in submittedReviews) {
        allReviewsMap[submitted.productId] = submitted;
      }
      final allReviews = allReviewsMap.values.toList();

      final avgProductRating = allReviews.isNotEmpty
          ? double.parse(
              (allReviews.fold<int>(0, (s, r) => s + r.rating) /
                      allReviews.length)
                  .toStringAsFixed(1),
            )
          : transactionRating.toDouble();

      final updatedItems = order.items.map((item) {
        final matched = allReviewsMap[item.productId];
        if (matched != null) {
          return item.copyWith(isReviewed: true, review: matched);
        }
        return item;
      }).toList();

      final distinctProductIds = order.items.map((e) => e.productId).toSet();
      final isAllProductsReviewed = distinctProductIds.isNotEmpty &&
          distinctProductIds.every((pid) => allReviewsMap.containsKey(pid));

      final updatedOrder = order.copyWith(
        items: updatedItems,
        isReviewedExplicit: isAllProductsReviewed,
        reviewedCount: allReviews.length,
        averageRating: avgProductRating,
        transactionRating: transactionRating,
        transactionReviewComment:
            (transactionComment != null && transactionComment.trim().isNotEmpty)
                ? transactionComment.trim()
                : order.transactionReviewComment,
        reviews: allReviews,
      );

      final key = updatedOrder.orderNumber.isNotEmpty
          ? updatedOrder.orderNumber
          : updatedOrder.id.toString();
      _reviewedOrderOverlay[key] = updatedOrder;
      _orderDetailCache[key] = updatedOrder;

      return updatedOrder;
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat mengirim ulasan pesanan',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e(
        'Gagal mengirim ulasan pesanan',
        error: e,
        stackTrace: stack,
      );
      if (e is ApiException) rethrow;
      throw const ServerException(message: 'Gagal mengirim ulasan pesanan.');
    }
  }

  @override
  Future<CheckoutResultModel> uploadPaymentProof({
    required dynamic idOrOrderNumber,
    required String filePath,
  }) async {
    try {
      AppLogger.d(
        'Mengunggah bukti pembayaran ke ${ApiConstants.uploadPaymentProof(idOrOrderNumber)}: $filePath',
      );
      final fileName = filePath.replaceAll(r'\', '/').split('/').last;
      final formData = FormData.fromMap({
        'payment_proof': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        ApiConstants.uploadPaymentProof(idOrOrderNumber),
        data: formData,
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final result = CheckoutResultModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        if (result.orderNumber.isNotEmpty) {
          _orderDetailCache[result.orderNumber] = result;
        }
        return result;
      }
      throw const ServerException(
        message: 'Format respon upload bukti pembayaran tidak valid.',
      );
    } on DioException catch (e, stack) {
      AppLogger.e(
        'DioException saat upload bukti pembayaran',
        error: e,
        stackTrace: stack,
      );
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Gagal upload bukti pembayaran', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw const ServerException(
        message: 'Gagal mengunggah bukti pembayaran.',
      );
    }
  }
}
