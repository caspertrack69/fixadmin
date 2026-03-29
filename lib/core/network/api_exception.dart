import 'package:dio/dio.dart';

enum ApiErrorType {
  unauthorized,
  forbidden,
  notFound,
  validation,
  throttled,
  server,
  network,
  unknown,
}

class FieldErrors {
  const FieldErrors(this.values);

  final Map<String, List<String>> values;

  String? first(String field) {
    final messages = values[field];
    if (messages == null || messages.isEmpty) {
      return null;
    }
    return messages.first;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final FieldErrors? fieldErrors;

  bool get isUnauthorized => type == ApiErrorType.unauthorized;

  factory ApiException.fromDio(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final payload = response?.data;
    final message = _extractMessage(payload) ?? _fallbackMessage(exception);
    final fieldErrors = _extractFieldErrors(payload);

    final type = switch (statusCode) {
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      422 => ApiErrorType.validation,
      429 => ApiErrorType.throttled,
      500 || 502 || 503 || 504 => ApiErrorType.server,
      null when exception.type == DioExceptionType.connectionTimeout ||
          exception.type == DioExceptionType.receiveTimeout ||
          exception.type == DioExceptionType.sendTimeout ||
          exception.type == DioExceptionType.connectionError =>
        ApiErrorType.network,
      _ => ApiErrorType.unknown,
    };

    return ApiException(
      type: type,
      message: message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  @override
  String toString() => message;

  static String? _extractMessage(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final value = payload['message'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    if (payload is Map) {
      final value = payload['message'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static FieldErrors? _extractFieldErrors(Object? payload) {
    if (payload is! Map) {
      return null;
    }

    final rawErrors = payload['errors'];
    if (rawErrors is! Map) {
      return null;
    }

    final values = <String, List<String>>{};
    for (final entry in rawErrors.entries) {
      final rawList = entry.value;
      if (rawList is List) {
        values['${entry.key}'] = rawList.map((item) => '$item').toList();
      } else if (rawList != null) {
        values['${entry.key}'] = ['$rawList'];
      }
    }

    return FieldErrors(values);
  }

  static String _fallbackMessage(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        'Koneksi ke server bermasalah.',
      _ => 'Terjadi kesalahan pada permintaan.',
    };
  }
}
