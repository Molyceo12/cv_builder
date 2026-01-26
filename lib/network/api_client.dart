import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(ApiLogInterceptor());
  }

  Dio get dio => _dio;
}

class ApiLogInterceptor extends Interceptor {
  static const String _blue = '\x1B[34m';
  static const String _reset = '\x1B[0m';
  static const String _divider = '--------------------------------------------------------------------';
  static const String _bdyDivider = '--------------------------------------------------------------------|:::::::::::bdy';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('${_blue}$_divider$_reset');
      debugPrint('${_blue}🌐 MAGIC REQUEST [${options.method}] => PATH: ${options.path}$_reset');
      debugPrint('${_blue}Headers: ${options.headers}$_reset');
      if (options.data != null) {
        debugPrint('${_blue}Body: ${options.data}$_reset');
      }
      debugPrint('${_blue}$_divider$_reset');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('${_blue}$_divider$_reset');
      debugPrint('${_blue}✨ MAGIC RESPONSE [${response.statusCode}] => PATH: ${response.requestOptions.path}$_reset');
      debugPrint('${_blue}$_bdyDivider$_reset');
      debugPrint('${_blue}${response.data}$_reset');
      debugPrint('${_blue}$_divider$_reset');
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('${_blue}$_divider$_reset');
      debugPrint('${_blue}❌ MAGIC ERROR [${err.response?.statusCode}] => PATH: ${err.requestOptions.path}$_reset');
      debugPrint('${_blue}Message: ${err.message}$_reset');
      if (err.response?.data != null) {
        debugPrint('${_blue}$_bdyDivider$_reset');
        debugPrint('${_blue}${err.response?.data}$_reset');
      }
      debugPrint('${_blue}$_divider$_reset');
    }
    return super.onError(err, handler);
  }
}
