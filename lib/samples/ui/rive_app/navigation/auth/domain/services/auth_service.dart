// File: lib/features/auth/data/services/auth_service.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../entities/user_model.dart';

class AuthService {
  final Dio _dio = DioClient().instance;

  Future<void> saveUserLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toJson()));
  }

  Future<UserModel?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString('user_session');
    if (userStr != null) {
      return UserModel.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
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
