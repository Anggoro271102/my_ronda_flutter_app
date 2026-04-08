// File: lib/features/auth/data/services/auth_service.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../entities/user_model.dart';

class AuthService {
  final Dio _dio = DioClient().instance;
  static const String _sessionUserKey = 'user_session';
  static const String _sessionLoginAtKey = 'user_session_login_at_ms';
  static const String _sessionExpiredNoticeKey = 'user_session_expired_notice';
  static const Duration _sessionDuration = Duration(hours: 10);

  Future<void> saveUserLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserKey, jsonEncode(user.toJson()));
    await prefs.setInt(
      _sessionLoginAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.remove(_sessionExpiredNoticeKey);
  }

  Future<UserModel?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString(_sessionUserKey);
    final int? loginAtMs = prefs.getInt(_sessionLoginAtKey);

    if (userStr == null) {
      return null;
    }

    // Backward-compatible: session lama tanpa timestamp dianggap expired.
    if (loginAtMs == null) {
      await prefs.setBool(_sessionExpiredNoticeKey, true);
      await _clearSessionOnly();
      return null;
    }

    final loginAt = DateTime.fromMillisecondsSinceEpoch(loginAtMs);
    final isExpired = DateTime.now().difference(loginAt) > _sessionDuration;
    if (isExpired) {
      await prefs.setBool(_sessionExpiredNoticeKey, true);
      await _clearSessionOnly();
      return null;
    }

    return UserModel.fromJson(jsonDecode(userStr));
  }

  Future<void> logout() async {
    await _clearSessionOnly();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionExpiredNoticeKey);
  }

  Future<void> _clearSessionOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserKey);
    await prefs.remove(_sessionLoginAtKey);
  }

  Future<bool> consumeSessionExpiredNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool(_sessionExpiredNoticeKey) ?? false;
    if (shouldShow) {
      await prefs.remove(_sessionExpiredNoticeKey);
    }
    return shouldShow;
  }

  Future<ApiResponse<UserModel>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "/api/auth/login_inspection",
        data: {"email": email, "password": password},
      );

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      // Melempar pesan error dari Flask jika ada
      throw e.response?.data['message'] ?? "Terjadi kesalahan jaringan";
    }
  }
}
