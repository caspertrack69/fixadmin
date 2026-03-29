import 'package:dio/dio.dart';

import '../models/paged_response.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.dio});

  final Dio dio;

  Future<T> getObject<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final response = await dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      final data = _extractMapData(response.data);
      return parser(data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<List<T>> getList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final response = await dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      final data = _extractListData(response.data);
      return data.map(parser).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<PagedResponse<T>> getPagedList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final response = await dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      final map = _asMap(response.data);
      final data = _extractListFromMap(map);
      final metaRaw = map['meta'];
      if (metaRaw is! Map) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Response pagination tidak valid.',
        );
      }

      return PagedResponse(
        data: data.map(parser).toList(),
        meta: PaginationMeta.fromJson(
          metaRaw.map((key, value) => MapEntry('$key', value)),
        ),
      );
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<T> postObject<T>(
    String path, {
    Object? body,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final response = await dio.post<Object?>(path, data: body);
      final data = _extractMapData(response.data);
      return parser(data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<void> postVoid(String path, {Object? body}) async {
    try {
      await dio.post<Object?>(path, data: body);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Map<String, dynamic> _extractMapData(Object? payload) {
    final map = _asMap(payload);
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry('$key', value));
    }
    throw const ApiException(
      type: ApiErrorType.unknown,
      message: 'Response data tidak valid.',
    );
  }

  List<Map<String, dynamic>> _extractListData(Object? payload) {
    final map = _asMap(payload);
    return _extractListFromMap(map);
  }

  List<Map<String, dynamic>> _extractListFromMap(Map<String, dynamic> map) {
    final data = map['data'];
    if (data is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Response list tidak valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  Map<String, dynamic> _asMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry('$key', value));
    }
    throw const ApiException(
      type: ApiErrorType.unknown,
      message: 'Format response tidak didukung.',
    );
  }
}

Dio buildDio({
  required String baseUrl,
  required TokenStore tokenStore,
  required SessionCoordinator coordinator,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore.clearToken();
          await coordinator.notifyUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

class SessionCoordinator {
  Future<void> Function()? _onUnauthorized;
  Future<void> Function()? _onSessionChanged;

  void register({
    Future<void> Function()? onUnauthorized,
    Future<void> Function()? onSessionChanged,
  }) {
    _onUnauthorized = onUnauthorized;
    _onSessionChanged = onSessionChanged;
  }

  Future<void> notifyUnauthorized() async {
    await _onUnauthorized?.call();
  }

  Future<void> notifySessionChanged() async {
    await _onSessionChanged?.call();
  }
}
