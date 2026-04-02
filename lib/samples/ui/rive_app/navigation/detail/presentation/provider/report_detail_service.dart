import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/dio_client.dart';
import '../../../inspeksi/entities/inspection_report.dart';

// ===============================
// COMPLETION ENTITY (inline minimal)
// Kalau kamu sudah punya file entity terpisah, pindahkan ke file sendiri.
// ===============================
class CompletionInfo {
  final int idRecom;
  final int reportId;
  final String? resolverName;
  final DateTime? createdAt;

  // ✅ TAMBAHKAN DUA BARIS INI
  final String? remediationImage;
  final String? remediationNote;
  final String? remediationNoteAi;

  CompletionInfo({
    required this.idRecom,
    required this.reportId,
    this.resolverName,
    this.createdAt,
    // ✅ TAMBAHKAN DI CONSTRUCTOR
    this.remediationImage,
    this.remediationNote,
    this.remediationNoteAi,
  });

  factory CompletionInfo.fromJson(Map<String, dynamic> json) {
    // Helper untuk parsing ID agar aman dari error string/int
    int toInt(dynamic v) => v is int ? v : int.tryParse("$v") ?? 0;

    return CompletionInfo(
      idRecom: toInt(json['id_recom']),
      reportId: toInt(json['report_id']),
      resolverName: json['resolver_name']?.toString(),
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      // ✅ MAPPING DARI JSON API TERBARU KAMU
      remediationImage: json['remediation_image']?.toString(),
      remediationNote: json['remediation_note']?.toString(),
      remediationNoteAi: json['remediation_note_ai']?.toString(),
    );
  }
}

// ===============================
// PROVIDERS
// ===============================
// State untuk menyimpan hasil analisis AI sementara
final aiCompletionAnalysisProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
// State untuk loading AI khusus di bagian completion
final isAiCompletionLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final detailServiceProvider = Provider<ReportDetailService>(
  (ref) => ReportDetailService(ref.read(dioClientProvider)),
);

final reportDetailProvider = FutureProvider.family<InspectionReport, int>((
  ref,
  id,
) async {
  final service = ref.read(detailServiceProvider);
  return service.getDetail(id);
});

final reportCompletionProvider = FutureProvider.family<CompletionInfo, int>((
  ref,
  id,
) async {
  final service = ref.read(detailServiceProvider);
  return service.getCompletion(id);
});

// ===============================
// SERVICE
// ===============================
class ReportDetailService {
  ReportDetailService(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.instance;

  // ---------------------------
  // GET DETAIL
  // ---------------------------
  Future<InspectionReport> getDetail(int id) async {
    try {
      debugPrint("=== [GET DETAIL] Request ===");
      debugPrint("uri: ${_dio.options.baseUrl}/api/inspection/report/$id");

      final res = await _dio.get('/api/inspection/report/$id');

      debugPrint("=== [GET DETAIL] Response ===");
      debugPrint("statusCode: ${res.statusCode}");
      debugPrint("statusMessage: ${res.statusMessage}");
      debugPrint("headers: ${res.headers.map}");
      debugPrint("data: ${res.data}");

      final body = res.data;
      if (body is Map<String, dynamic>) {
        debugPrint("keys: ${body.keys.toList()}");
        debugPrint("body['data']: ${body['data']}");
      }

      return InspectionReport.fromJson(res.data['data']);
    } on DioException catch (e) {
      debugPrint("=== [GET DETAIL] DioException ===");
      debugPrint("uri: ${e.requestOptions.uri}");
      debugPrint("statusCode: ${e.response?.statusCode}");
      debugPrint("response: ${e.response?.data}");
      debugPrint("message: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("=== [GET DETAIL] Unknown Error === $e");
      rethrow;
    }
  }

  // ---------------------------
  // GET COMPLETION
  // endpoint: /api/inspection/report/<id>/completion
  // SQL referensi:
  // select rem.id_recom, rem.report_id, us_rep.name, rem.created_at
  // from tb_remediations_report_inspection rem
  // join tb_users_inspection us_rep on us_rep.user_id = rem.assigned_to
  // where rem.report_id= <id>
  // ---------------------------
  Future<CompletionInfo> getCompletion(int id) async {
    try {
      debugPrint("=== [GET COMPLETION] Request ===");
      debugPrint(
        "uri: ${_dio.options.baseUrl}/api/inspection/report/$id/completion",
      );

      final res = await _dio.get('/api/inspection/report/$id/completion');

      debugPrint("=== [GET COMPLETION] Response ===");
      debugPrint("statusCode: ${res.statusCode}");
      debugPrint("statusMessage: ${res.statusMessage}");
      debugPrint("headers: ${res.headers.map}");
      debugPrint("data: ${res.data}");

      final body = res.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];

        // Support: data bisa object atau list (kalau query mengembalikan banyak history)
        if (data is Map<String, dynamic>) {
          return CompletionInfo.fromJson(data);
        } else if (data is List &&
            data.isNotEmpty &&
            data.first is Map<String, dynamic>) {
          // ambil record terbaru (atau pertama, tergantung API kamu)
          return CompletionInfo.fromJson(data.first as Map<String, dynamic>);
        }
      }

      throw Exception("Format response completion tidak sesuai");
    } on DioException catch (e) {
      debugPrint("=== [GET COMPLETION] DioException ===");
      debugPrint("uri: ${e.requestOptions.uri}");
      debugPrint("statusCode: ${e.response?.statusCode}");
      debugPrint("response: ${e.response?.data}");
      debugPrint("message: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("=== [GET COMPLETION] Unknown Error === $e");
      rethrow;
    }
  }

  // ---------------------------
  // EDIT REPORT
  // ---------------------------
  Future<Map<String, dynamic>> editReport({
    required int reportId,
    required int userId,
    required String severity,
    required String category,
    required String description,
    String? objectDetected,
    String? recommendation,
    String? newImagePath,
  }) async {
    // Create a map to hold the form data
    final map = <String, dynamic>{
      'user_id': userId,
      'severity': severity,
      'category': category,
      'description': description,
    };

    // Log the initial data being sent
    debugPrint('--- Editing Report ---');
    debugPrint('Report ID: $reportId');
    debugPrint('User ID: $userId');
    debugPrint('Severity: $severity');
    debugPrint('Category: $category');
    debugPrint('Description: $description');
    debugPrint('Object Detected: $objectDetected');
    debugPrint('Recommendation: $recommendation');
    debugPrint('Image Path: $newImagePath');

    // Optional fields, check if they are not null and not empty
    if (objectDetected != null && objectDetected.trim().isNotEmpty) {
      map['object_detected'] = objectDetected.trim();
    }

    if (recommendation != null && recommendation.trim().isNotEmpty) {
      map['recommendation'] = recommendation.trim();
    }

    if (newImagePath != null && newImagePath.isNotEmpty) {
      map['report_image'] = await MultipartFile.fromFile(
        newImagePath,
        filename: 'EDIT_$reportId.jpg',
      );
    }

    // Prepare the form data
    final formData = FormData.fromMap(map);

    try {
      debugPrint('--- Sending Request ---');
      final res = await _dio.put(
        '/api/inspection/report/$reportId/edit',
        data: formData,
      );

      debugPrint('--- Response Received ---');
      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response Data: ${res.data}');

      return (res.data is Map<String, dynamic>)
          ? (res.data as Map<String, dynamic>)
          : {};
    } on DioException catch (e) {
      // Error handling
      debugPrint('--- Error Occurred ---');
      debugPrint('Error Message: ${e.message}');
      if (e.response != null) {
        debugPrint('Response Status Code: ${e.response?.statusCode}');
        debugPrint('Response Data: ${e.response?.data}');
      }

      if (e.response?.statusCode == 413) {
        throw Exception("Ukuran foto terlalu besar (413).");
      }

      throw Exception(e.message ?? "Gagal edit laporan");
    }
  }

  // ---------------------------
  // COMPLETE REPORT (POST)
  // ---------------------------
  // ---------------------------
  // COMPLETE REPORT (POST)
  // ---------------------------
  Future<Map<String, dynamic>> completeReport({
    required int reportId,
    required int userId,
    required String note,
    required String imagePath,
    String? noteAi,
  }) async {
    debugPrint('--- [COMPLETE REPORT] Request Started ---');
    debugPrint('Report ID: $reportId');
    debugPrint('User ID  : $userId');
    debugPrint('Note     : $note');
    debugPrint('Image Path: $imagePath');

    final formData = FormData.fromMap({
      'user_id': userId,
      'remediation_note': note,
      'remediation_note_ai': noteAi,
      'remediation_image': await MultipartFile.fromFile(
        imagePath,
        filename: 'FIX_$reportId.jpg',
      ),
    });

    try {
      final String fullUri =
          '${_dio.options.baseUrl}/api/inspection/report/$reportId/complete';
      debugPrint('Sending POST to: $fullUri');

      final res = await _dio.post(
        '/api/inspection/report/$reportId/complete',
        data: formData,
      );

      debugPrint('--- [COMPLETE REPORT] Success Response ---');
      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response Data: ${res.data}');

      return (res.data is Map<String, dynamic>)
          ? (res.data as Map<String, dynamic>)
          : {};
    } on DioException catch (e) {
      debugPrint('--- [COMPLETE REPORT] DioException Occurred ---');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Error Message: ${e.message}');

      if (e.response != null) {
        debugPrint('Response Data: ${e.response?.data}');
      }

      if (e.response?.statusCode == 413) {
        debugPrint('CRITICAL: Ukuran foto terlalu besar untuk server!');
        throw Exception("Ukuran foto terlalu besar (413).");
      }

      throw Exception(e.message ?? "Gagal upload");
    } catch (e) {
      debugPrint('--- [COMPLETE REPORT] Unknown Error ---');
      debugPrint('Error detail: $e');
      rethrow;
    } finally {
      debugPrint('--- [COMPLETE REPORT] Process Finished ---');
    }
  }
}
