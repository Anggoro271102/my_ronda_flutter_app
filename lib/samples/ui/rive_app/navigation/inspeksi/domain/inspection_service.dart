import 'dart:async';
import 'package:dio/dio.dart';

class InspectionService {
  final _dio = Dio(BaseOptions(baseUrl: "http://10.13.10.189:8000"));

  Future<Map<String, dynamic>> uploadAndPoll(String imagePath) async {
    // 1. Upload ke analyze-detailed
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(imagePath),
    });

    final response = await _dio.post("/analyze-detailed", data: formData);
    String taskId = response.data['task_id'];

    // 2. Polling /status/{task_id} setiap 5 detik
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      final statusResponse = await _dio.get("/status/$taskId");

      if (statusResponse.data['status'] == 'SUCCESS') {
        return statusResponse.data['result'];
      } else if (statusResponse.data['status'] == 'FAILURE') {
        throw Exception("AI Processing Failed");
      }
      // Jika masih PROCESSING, loop berlanjut
    }
  }
}
