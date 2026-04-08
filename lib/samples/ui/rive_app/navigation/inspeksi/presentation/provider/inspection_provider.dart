import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../../entities/inspection_report.dart' as ent;

class InspectionState {
  final bool isLoading;
  final int? reportId; // Untuk menyimpan PK dari tb_report_inspection
  final int? locId; // Untuk menyimpan loc_id dari check_location
  final String? objectDetected;
  final String? category;
  final String? severity;
  final String? description;
  final String? recommendation;
  final String? locationName;
  final double? lat;
  final double? long;
  final String? error;
  final bool isFinalSubmitted;

  InspectionState({
    this.isLoading = false,
    this.reportId,
    this.locId,
    this.objectDetected,
    this.category,
    this.severity,
    this.description,
    this.recommendation,
    this.locationName,
    this.lat,
    this.long,
    this.error,
    this.isFinalSubmitted = false,
  });

  InspectionState copyWith({
    bool? isLoading,
    int? reportId,
    int? locId,
    String? objectDetected,
    String? category,
    String? severity,
    String? description,
    String? recommendation,
    String? locationName,
    double? lat,
    double? long,
    String? error,
    bool? isFinalSubmitted,
  }) {
    return InspectionState(
      isLoading: isLoading ?? this.isLoading,
      reportId: reportId ?? this.reportId,
      locId: locId ?? this.locId,
      objectDetected: objectDetected ?? this.objectDetected,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      recommendation: recommendation ?? this.recommendation,
      locationName: locationName ?? this.locationName,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      error: error ?? this.error,
      isFinalSubmitted: isFinalSubmitted ?? this.isFinalSubmitted,
    );
  }
}

final manualCategoryProvider = StateProvider.autoDispose<ent.Category?>(
  (ref) => null,
);

// Pastikan baris ini ada di LUAR class InspectionNotifier
// PERUBAHAN: Menambahkan .autoDispose agar state otomatis reset ke kosong saat user keluar dari layar inspeksi
final inspectionStateProvider =
    StateNotifierProvider.autoDispose<InspectionNotifier, InspectionState>((
      ref,
    ) {
      final notifier = InspectionNotifier();

      ref.onDispose(() {
        final currentState = notifier.state;

        if (currentState.reportId != null && !currentState.isFinalSubmitted) {
          // Log ini akan muncul sekali di Logcat kamu
          debugPrint(
            "🧹 Auto-Cleaning: Menghapus sampah ID ${currentState.reportId}",
          );

          // Panggil secara silent agar tidak memicu error "Bad State"
          notifier.deleteReport(currentState.reportId!, isSilent: true);
        }
      });

      return notifier;
    });

enum LastActionType { none, processInspection, submitFinal }

class InspectionNotifier extends StateNotifier<InspectionState> {
  InspectionNotifier() : super(InspectionState());
  LastActionType _lastAction = LastActionType.none;

  String? _lastImagePath;
  int? _lastUserId;

  Map<String, dynamic>? _lastFinalPayload;

  void _logDioException(
    DioException e, {
    String tag = "DIO",
    StackTrace? stackTrace,
  }) {
    final req = e.requestOptions;
    final res = e.response;

    debugPrint("[$tag] DioException ------------------------------");
    debugPrint("[$tag] type: ${e.type}");
    debugPrint("[$tag] message: ${e.message}");
    debugPrint("[$tag] method: ${req.method}");
    debugPrint("[$tag] uri: ${req.uri}");
    debugPrint("[$tag] connectTimeout: ${req.connectTimeout}");
    debugPrint("[$tag] sendTimeout: ${req.sendTimeout}");
    debugPrint("[$tag] receiveTimeout: ${req.receiveTimeout}");
    debugPrint("[$tag] request headers: ${req.headers}");
    debugPrint("[$tag] query: ${req.queryParameters}");

    if (req.data != null) {
      if (req.data is FormData) {
        final data = req.data as FormData;
        final fields = data.fields.map((f) => "${f.key}=${f.value}").toList();
        final files = data.files
            .map((f) => "${f.key}=${f.value.filename ?? 'unknown'}")
            .toList();
        debugPrint("[$tag] request form fields: $fields");
        debugPrint("[$tag] request form files: $files");
      } else {
        debugPrint("[$tag] request data: ${req.data}");
      }
    }

    if (res != null) {
      debugPrint("[$tag] response status: ${res.statusCode}");
      debugPrint("[$tag] response headers: ${res.headers.map}");
      debugPrint("[$tag] response data: ${res.data}");
    } else {
      debugPrint("[$tag] response: <null>");
    }

    if (e.error != null) {
      debugPrint("[$tag] underlying error: ${e.error}");
    }
    if (stackTrace != null) {
      debugPrint("[$tag] stackTrace: $stackTrace");
    }
    debugPrint("[$tag] ------------------------------------------");
  }

  String _friendlyDioMessage(DioException e) {
    final status = e.response?.statusCode;

    // Kasus umum jaringan
    if (e.type == DioExceptionType.connectionError) {
      return "Koneksi bermasalah / server menutup koneksi. Silakan cek internet lalu coba kirim ulang.";
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return "Request timeout. Silakan coba kirim ulang.";
    }

    // HTTP status error
    if (status != null) {
      if (status >= 500)
        return "Server sedang bermasalah ($status). Coba lagi beberapa saat.";
      if (status == 401 || status == 403)
        return "Sesi login tidak valid. Silakan login ulang.";
      if (status == 413)
        return "File terlalu besar. Coba foto ulang / kompres lebih kecil.";
      return "Gagal mengirim data ($status). Silakan coba lagi.";
    }

    // Fallback
    return "Terjadi kesalahan jaringan. Silakan coba kirim ulang.";
  }

  final Dio _dioAI = Dio(
    BaseOptions(baseUrl: "https://inspector-api.cp.co.id"),
  );
  final Dio _dioTrack = Dio(BaseOptions(baseUrl: "https://track.cpipga.com"));

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> retryLastAction() async {
    clearError();

    switch (_lastAction) {
      case LastActionType.processInspection:
        if (_lastImagePath != null && _lastUserId != null) {
          await processInspection(_lastImagePath!, _lastUserId!);
        }
        break;

      case LastActionType.submitFinal:
        if (_lastFinalPayload != null) {
          final p = _lastFinalPayload!;
          await submitFinalReport(
            userId: p["userId"],
            isOverride: p["isOverride"],
            manualObject: p["manualObject"],
            manualCategory: p["manualCategory"],
            manualNotes: p["manualNotes"],
            manualSeverity: p["manualSeverity"],
            manualRecommendation: p["manualRecommendation"],
          );
        }
        break;

      case LastActionType.none:
        // tidak ada aksi terakhir
        break;
    }
  }

  // PERBAIKAN: Menambahkan parameter userId
  Future<void> processInspection(String imagePath, int userId) async {
    state = state.copyWith(isLoading: true, error: null, reportId: null);
    _lastAction = LastActionType.processInspection;
    _lastImagePath = imagePath;
    _lastUserId = userId;

    try {
      // 1. Ambil GPS & Cek Lokasi
      final locData = await _checkCurrentLocation();
      state = state.copyWith(
        locId: locData['loc_id'],
        locationName: locData['location_name'],
      );

      // 2. Jalankan Proses AI (Workstation RTX 4070)
      final aiData = await uploadAndPollAI(imagePath);
      state = state.copyWith(
        objectDetected: aiData['object_detection'],
        category: aiData['category'],
        severity: aiData['severity'],
        description: aiData['description'],
        recommendation: aiData['recommendations'],
      );

      // 3. LOGIKA: SUBMIT DATA AI + UPLOAD FILE FISIK KE VPS
      // Gunakan FormData untuk Multipart Upload
      FormData formData = FormData.fromMap({
        "type_submit": "submit_ai",
        "user_id": userId,
        "capture_lat": state.lat,
        "loc_id": state.locId,
        "object_detected": state.objectDetected,
        "category": state.category,
        "severity": state.severity,
        "description": state.description,
        "recommendation": state.recommendation,
        "image_file": await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      final resSubmitAi = await _dioTrack.post(
        "/api/inspection/submit_data",
        data: formData,
      );

      // FIX: Gunakan int.tryParse untuk menjaga jika server mengirim string atau integer
      // PERUBAHAN: Penanganan ID yang lebih aman dari PostgreSQL (mencegah null/string error)
      final dynamic rawId = resSubmitAi.data['report_id'];
      final int? fetchedId =
          rawId is int ? rawId : int.tryParse(rawId.toString());

      if (fetchedId == null) {
        throw "Server tidak mengembalikan Report ID yang valid";
      }

      state = state.copyWith(
        isLoading: false,
        reportId: fetchedId,
        locId: locData['loc_id'],
        locationName: locData['location_name'],
        objectDetected: aiData['object_detection'],
        category: aiData['category'],
        severity: aiData['severity'],
        description: aiData['description'],
        recommendation: aiData['recommendations'],
        isFinalSubmitted:
            false, // Pastikan ini false agar auto-cleaning siap siaga
        error: null,
      );
    } on DioException catch (e) {
      _logDioException(e, tag: "PROCESS_INSPECTION");
      final msg = _friendlyDioMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      print("ERROR PROCESS: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // LOGIKA 2: SUBMIT DATA FINAL (Kini menggunakan FormData)
  Future<bool> submitFinalReport({
    required int userId,
    required bool isOverride,
    required String manualObject,
    required String manualCategory,
    required String manualNotes,
    required String manualSeverity,
    required String manualRecommendation,
  }) async {
    if (state.reportId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    _lastAction = LastActionType.submitFinal;
    _lastFinalPayload = {
      "userId": userId,
      "isOverride": isOverride,
      "manualObject": manualObject,
      "manualCategory": manualCategory,
      "manualNotes": manualNotes,
      "manualSeverity": manualSeverity,
      "manualRecommendation": manualRecommendation,
    };

    try {
      // Karena API Flask sekarang menggunakan request.form, kirim via FormData
      FormData finalData = FormData.fromMap({
        "type_submit": "submit_final",
        "report_id": state.reportId,
        "user_id": userId,
        "is_override":
            isOverride.toString(), // Kirim sebagai string 'true'/'false'
        "loc_id": state.locId,
        "object_detected": isOverride ? manualObject : state.objectDetected,
        "category": isOverride ? manualCategory : state.category,
        "severity": isOverride ? manualSeverity : state.severity,
        "description": isOverride ? manualNotes : state.description,
        "recommendation":
            isOverride ? manualRecommendation : state.recommendation,
      });

      await _dioTrack.post("/api/inspection/submit_data", data: finalData);
      state = state.copyWith(isLoading: false, isFinalSubmitted: true);
      return true;
    } on DioException catch (e) {
      _logDioException(e, tag: "SUBMIT_FINAL");
      final msg = _friendlyDioMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // FUNGSI CEK LOKASI (DIPERTAHANKAN)
  Future<Map<String, dynamic>> _checkCurrentLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    state = state.copyWith(lat: pos.latitude, long: pos.longitude);

    final res = await _dioTrack.post(
      "/api/auth/check_location",
      data: {"lat": pos.latitude, "long": pos.longitude},
    );
    return res.data;
  }

  Future<Map<String, dynamic>> uploadAndPollAI(String path) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(path),
      });
      final response = await _dioAI.post("/analyze-detailed", data: formData);
      final taskId = response.data['task_id'];

      while (true) {
        await Future.delayed(const Duration(seconds: 5));
        final statusRes = await _dioAI.get("/status/$taskId");

        // Log status setiap kali polling agar kamu bisa memantau pergerakan di terminal
        debugPrint(
          "🔍 Polling Status untuk Task $taskId: ${statusRes.data['status']}",
        );

        if (statusRes.data['status'] == 'SUCCESS') {
          final result = statusRes.data['result'];

          // TAMPILKAN HASIL RESPONSE SECARA LENGKAP
          debugPrint("✅ AI SUCCESS RESPONSE: $result");

          return result;
        }

        if (statusRes.data['status'] == 'FAILURE') {
          debugPrint("❌ AI FAILURE DETECTED: ${statusRes.data['message']}");
          throw Exception("AI Fail: ${statusRes.data['message']}");
        }

        // Tips: Kamu bisa menambahkan timeout manual di sini jika polling > 3 menit
      }
    } on DioException catch (e, st) {
      _logDioException(e, tag: "AI_UPLOAD_POLL", stackTrace: st);
      rethrow;
    }
  }

  // Di dalam class InspectionNotifier
  Future<bool> deleteReport(int reportId, {bool isSilent = false}) async {
    try {
      final response = await _dioTrack.delete(
        "/api/inspection/report/$reportId/delete",
      );

      if (response.statusCode == 200) {
        // FIX: Cek 'mounted' dan flag 'isSilent' sebelum menyentuh state
        if (mounted && !isSilent) {
          state = InspectionState();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error Delete: $e");
      return false;
    }
  }
}
