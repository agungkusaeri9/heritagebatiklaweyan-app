import 'package:dio/dio.dart';
import '../../logging/app_logger.dart';

/// Interceptor khusus untuk mencatat logging HTTP Request, Response, dan Error secara terstruktur
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d(
      '🌐 [HTTP REQUEST] ------------------------------------\n'
      'METHOD : ${options.method}\n'
      'URI    : ${options.uri}\n'
      'HEADERS: ${options.headers}\n'
      'PAYLOAD: ${options.data}\n'
      '-------------------------------------------------------',
    );
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.i(
      '✅ [HTTP RESPONSE] -----------------------------------\n'
      'STATUS : ${response.statusCode} ${response.statusMessage}\n'
      'URI    : ${response.requestOptions.uri}\n'
      'DATA   : ${response.data}\n'
      '-------------------------------------------------------',
    );
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '❌ [HTTP ERROR] --------------------------------------\n'
      'TYPE   : ${err.type}\n'
      'STATUS : ${err.response?.statusCode}\n'
      'URI    : ${err.requestOptions.uri}\n'
      'MSG    : ${err.message}\n'
      'DATA   : ${err.response?.data}\n'
      '-------------------------------------------------------',
      error: err.error,
      stackTrace: err.stackTrace,
    );
    return handler.next(err);
  }
}
