import 'package:dio/dio.dart';

import '../pane/handset.dart';

class Courier {
  Courier() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler next) {
          options.headers['User-Agent'] = Handset.userAgent;
          next.next(options);
        },
      ),
    );
  }

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      sendTimeout: const Duration(seconds: 6),
      validateStatus: (int? code) => code != null,
    ),
  );

  Future<Response<String>> postJson(Uri uri, String body) {
    return _dio.post<String>(
      uri.toString(),
      data: body,
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<List<int>?> getBytes(String url) async {
    try {
      final Response<List<int>> res = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (res.statusCode == 200) return res.data;
    } catch (_) {}
    return null;
  }
}

final Courier courier = Courier();
