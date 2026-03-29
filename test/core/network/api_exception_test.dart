import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixadmin/core/network/api_exception.dart';

void main() {
  test('maps 422 response into validation error with field messages', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 422,
        data: {
          'message': 'Validasi gagal.',
          'errors': {
            'email': ['Email wajib diisi'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final mapped = ApiException.fromDio(exception);

    expect(mapped.type, ApiErrorType.validation);
    expect(mapped.message, 'Validasi gagal.');
    expect(mapped.fieldErrors?.first('email'), 'Email wajib diisi');
  });
}
