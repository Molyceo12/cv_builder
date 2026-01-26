import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_constants.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LoggingInterceptor());
  }

  Dio get dio => _dio;

  /// Delete a skill by its remote ID.
  ///
  /// * `skillId` – the unique identifier of the skill on the server.
  /// * `cvId`   – the currently active CV identifier (required query param).
  ///
  /// Returns the raw [Response] from the server.
  Future<Response> deleteSkill(String skillId, {required String cvId}) async {
    return await _dio.delete(
      'api/skill/$skillId/',
      queryParameters: {'cv': cvId},
    );
  }
}

class LoggingInterceptor extends Interceptor {
  final logger = Logger(
    printer: PrettyPrinter(
      printEmojis: false,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Logs the Method and Full URL
    logger.i("${options.method} REQUEST:::::::::: ${options.baseUrl + options.path}");
    
    // Logs Query Parameters (always) and Body for non-GET methods
    if (options.queryParameters.isNotEmpty) {
      logger.i("QueryParams:::::::::::::: ${options.queryParameters}");
    }
    if (options.method != "GET") {
      logger.i("Body:::::::::::: ${options.data}");
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Logs the Response Data
    logger.d(response.data);
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Logs Error details
    logger.e("${err.requestOptions.method} REQUEST:::::::::: ${err.requestOptions.baseUrl + err.requestOptions.path}");
    logger.e(err.response?.data);
    return super.onError(err, handler);
  }
}
