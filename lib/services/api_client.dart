import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'secure_storage_service.dart';

/// API client for making HTTP requests to the backend
/// Includes authentication, retry logic, and error handling
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  ApiClient({
    required SecureStorageService secureStorage,
    Dio? dio,
  }) : _secureStorage = secureStorage {
    _dio = dio ?? Dio();
    _configureDio();
  }

  /// Configure Dio with base URL, timeouts, and interceptors
  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Accept all status codes to handle them in interceptors
        return status != null && status < 500;
      },
    );

    // Add request interceptor to inject auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        maxRetries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
      ),
    );
  }

  /// Request interceptor - inject auth token
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Enforce HTTPS
    if (!options.uri.scheme.startsWith('https')) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Only HTTPS requests are allowed',
          type: DioExceptionType.badResponse,
        ),
      );
    }

    // Inject auth token if available
    final token = await _secureStorage.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// Error interceptor - handle 401 errors
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Token expired or invalid - trigger logout
      await _secureStorage.clearAuthData();
      // TODO: Navigate to login screen or emit auth state change
    }

    handler.next(error);
  }

  // HTTP Methods

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to ApiException
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: null,
          type: ApiExceptionType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _getErrorMessage(error.response);

        if (statusCode == 401) {
          return ApiException(
            message: 'Unauthorized. Please login again.',
            statusCode: statusCode,
            type: ApiExceptionType.unauthorized,
          );
        } else if (statusCode == 403) {
          return ApiException(
            message: 'Access denied. You don\'t have permission.',
            statusCode: statusCode,
            type: ApiExceptionType.forbidden,
          );
        } else if (statusCode == 404) {
          return ApiException(
            message: 'Resource not found.',
            statusCode: statusCode,
            type: ApiExceptionType.notFound,
          );
        } else if (statusCode == 429) {
          return ApiException(
            message: 'Too many requests. Please try again later.',
            statusCode: statusCode,
            type: ApiExceptionType.rateLimited,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ApiException(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
            type: ApiExceptionType.serverError,
          );
        } else {
          return ApiException(
            message: message,
            statusCode: statusCode,
            type: ApiExceptionType.badRequest,
          );
        }

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled.',
          statusCode: null,
          type: ApiExceptionType.cancelled,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
          statusCode: null,
          type: ApiExceptionType.networkError,
        );

      default:
        return ApiException(
          message: 'An unexpected error occurred: ${error.message}',
          statusCode: null,
          type: ApiExceptionType.unknown,
        );
    }
  }

  /// Extract error message from response
  String _getErrorMessage(Response? response) {
    if (response?.data is Map) {
      final data = response!.data as Map<String, dynamic>;
      return data['message'] ?? data['error'] ?? 'An error occurred';
    }
    return 'An error occurred';
  }
}

/// Retry interceptor with exponential backoff
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry on network errors or 5xx server errors
    final shouldRetry = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);

    if (!shouldRetry) {
      return handler.next(err);
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    // Wait before retrying
    final delayIndex = retryCount < retryDelays.length ? retryCount : retryDelays.length - 1;
    await Future.delayed(retryDelays[delayIndex]);

    // Retry the request
    err.requestOptions.extra['retryCount'] = retryCount + 1;

    try {
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}

/// API exception with detailed error information
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  ApiException({
    required this.message,
    this.statusCode,
    required this.type,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode, Type: $type)';
}

/// Types of API exceptions
enum ApiExceptionType {
  timeout,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  serverError,
  badRequest,
  cancelled,
  networkError,
  unknown,
}
