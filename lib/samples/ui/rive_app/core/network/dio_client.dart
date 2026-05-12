// File: lib/core/network/dio_client.dart
import 'dart:convert';
import 'package:dio/dio.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: "https://track.cpipga.com",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 60),
        contentType: Headers.jsonContentType,
      ),
    );

    // ✅ Custom Logger Interceptor -> logcat mirip contoh kamu
    _dio.interceptors.add(
      _DioLogInterceptor(
        logRequestHeaders: true,
        logRequestBody: true,
        logResponseHeaders: true,
        logResponseBody: true,
        logErrors: true,
        maxBodyChars: 8000,
      ),
    );
  }

  Dio get instance => _dio;
}

/// Logger khusus agar mudah debug request/response di Logcat
class _DioLogInterceptor extends Interceptor {
  _DioLogInterceptor({
    required this.logRequestHeaders,
    required this.logRequestBody,
    required this.logResponseHeaders,
    required this.logResponseBody,
    required this.logErrors,
    required this.maxBodyChars,
  });

  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponseHeaders;
  final bool logResponseBody;
  final bool logErrors;
  final int maxBodyChars;

  // ignore: avoid_print
  void _p(String msg) => print(msg);

  String _clip(String s) {
    if (s.length <= maxBodyChars) return s;
    return "${s.substring(0, maxBodyChars)}... (clipped ${s.length - maxBodyChars} chars)";
  }

  String _pretty(dynamic data) {
    if (data == null) return "null";

    // FormData: tampilkan fields + file names (bukan binary)
    if (data is FormData) {
      final fields = data.fields.map((e) => "${e.key}: ${e.value}").toList();
      final files =
          data.files
              .map((e) => "${e.key}: ${e.value.filename ?? 'file'}")
              .toList();

      return {"fields": fields, "files": files}.toString();
    }

    // Map/List: pretty json
    if (data is Map || data is List) {
      try {
        return const JsonEncoder.withIndent("  ").convert(data);
      } catch (_) {
        return data.toString();
      }
    }

    // String JSON: coba pretty
    if (data is String) {
      final s = data.trim();
      final looksJson =
          (s.startsWith("{") && s.endsWith("}")) ||
          (s.startsWith("[") && s.endsWith("]"));
      if (looksJson) {
        try {
          return const JsonEncoder.withIndent("  ").convert(jsonDecode(s));
        } catch (_) {
          return data;
        }
      }
      return data;
    }

    return data.toString();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _p("");
    _p("*** Request ***");
    _p("uri: ${options.uri}");
    _p("method: ${options.method}");

    if (logRequestHeaders) {
      _p("headers:");
      options.headers.forEach((k, v) => _p("  $k: $v"));
    }

    if (logRequestBody) {
      _p("data:");
      _p(_clip(_pretty(options.data)));
    }

    _p("");
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _p("");
    _p("*** Response ***");
    _p("uri: ${response.requestOptions.uri}");
    _p("statusCode: ${response.statusCode}");
    _p("statusMessage: ${response.statusMessage}");

    if (logResponseHeaders) {
      _p("headers:");
      response.headers.map.forEach((k, v) => _p("  $k: ${v.join(", ")}"));
    }

    if (logResponseBody) {
      _p("Response Text:");
      _p(_clip(_pretty(response.data)));
    }

    _p("");
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!logErrors) {
      handler.next(err);
      return;
    }

    _p("");
    _p("*** Dio Error ***");
    _p("uri: ${err.requestOptions.uri}");
    _p("type: ${err.type}");
    _p("message: ${err.message}");
    _p("statusCode: ${err.response?.statusCode}");

    final data = err.response?.data;
    if (data != null) {
      _p("Error Response:");
      _p(_clip(_pretty(data)));
    }

    _p("");
    handler.next(err);
  }
}
