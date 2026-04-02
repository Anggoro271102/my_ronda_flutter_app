import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../inspeksi/entities/inspection_report.dart';
import '../screen/report_list_screen.dart';

// --- 1. STATE PROVIDERS (Untuk menampung input User dari UI) ---
// --- STATE FILTERS (Input UI) ---
final searchQueryProvider = StateProvider<String>((ref) => "");
final selectedStatusFilterProvider = StateProvider<bool?>((ref) => null);
final selectedSeverityFilterProvider = StateProvider<Severity?>((ref) => null);
final plantFilterProvider = StateProvider<String>((ref) => "All Plants");
final isFilterExpandedProvider = StateProvider<bool>((ref) => false);
final categoryFilterProvider = StateProvider<String>((ref) => "All Categories");
// Masukkan ke filter_provider.dart
final navIndexProvider = StateProvider<int>((ref) => 0);

final categoriesMasterProvider = FutureProvider<List<String>>((ref) async {
  final dio = Dio(BaseOptions(baseUrl: "https://track.cpipga.com"));
  try {
    final response = await dio.get('/api/master/categories');
    if (response.statusCode == 200) {
      return List<String>.from(response.data['data']);
    }
    return ["All Categories"];
  } catch (e) {
    return ["All Categories"];
  }
});

final plantsMasterProvider = FutureProvider<List<String>>((ref) async {
  final dio = Dio(BaseOptions(baseUrl: "https://track.cpipga.com"));
  try {
    final response = await dio.get('/api/inspection/master/plants');
    if (response.statusCode == 200) {
      return List<String>.from(response.data['data']);
    }
    return ["All Plants"];
  } catch (e) {
    return ["All Plants"]; // Fallback jika koneksi bermasalah
  }
});

// --- 1. DATA PROVIDER (API) ---
// Tambahkan .family agar bisa menerima userId (int?)
final reportsRawProvider = FutureProvider.family<List<InspectionReport>, int?>((
  ref,
  userId,
) async {
  debugPrint("📡 API CALL: Fetching reports for userId: $userId");
  final dio = Dio(
    BaseOptions(
      baseUrl: "https://track.cpipga.com",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  try {
    final response = await dio.get(
      '/api/inspection/reports',
      queryParameters: {if (userId != null) 'user_id': userId},
    );

    if (response.statusCode == 200) {
      final List data = response.data['data'];
      // Pastikan InspectionReport.fromJson sudah kamu definisikan di file entitas
      debugPrint("📦 RAW JSON DATA: ${response.data}");
      return data.map((json) => InspectionReport.fromJson(json)).toList();
    } else {
      throw Exception("Gagal mengambil data dari server");
    }
  } catch (e) {
    throw Exception("Kesalahan Jaringan: $e");
  }
});

// --- 2. FILTERED PROVIDER (UI LOGIC) ---
// Tambahkan .family di sini juga agar sinkron dengan UI
// Filter berdasarkan Search Type (ID vs Area)

final filteredReportsProvider = FutureProvider.family<
  List<InspectionReport>,
  int?
>((ref, userId) async {
  // Ambil data report terbaru dari API
  final allReports = await ref.watch(reportsRawProvider(userId).future);

  // --- Ambil state filter dari UI ---
  final rawQuery = ref.watch(searchQueryProvider);
  final query = rawQuery.trim().toLowerCase();

  final searchType = ref.watch(searchTypeProvider);
  final selectedCategory = ref.watch(categoryFilterProvider);
  final selectedPlant = ref.watch(plantFilterProvider);
  final statusFilter = ref.watch(selectedStatusFilterProvider);
  final severityFilter = ref.watch(selectedSeverityFilterProvider);

  // --- Jika tidak ada filter sama sekali, kembalikan semua ---
  if (query.isEmpty &&
      statusFilter == null &&
      severityFilter == null &&
      selectedPlant == "All Plants" &&
      selectedCategory == "All Categories") {
    return allReports;
  }

  // --- Proses Filtering ---
  final filteredList =
      allReports.where((report) {
        // ===== SEARCH LOGIC =====
        bool matchesSearch = true;

        if (query.isNotEmpty) {
          if (searchType == SearchType.content) {
            final inDesc = report.description.toLowerCase().contains(query);
            final inRec =
                report.recommendation?.toLowerCase().contains(query) ?? false;
            final objectDetect = report.objectDetected.toLowerCase().contains(
              query,
            );
            matchesSearch = inDesc || inRec || objectDetect;
          } else if (searchType == SearchType.object) {
            final inDesc = report.description.toLowerCase().contains(query);
            final inRec =
                report.recommendation?.toLowerCase().contains(query) ?? false;
            final objectDetect = report.objectDetected.toLowerCase().contains(
              query,
            );
            matchesSearch = inDesc || inRec || objectDetect;
          }
        }

        // ===== FILTER LOGIC =====
        final matchesCategory =
            selectedCategory == "All Categories" ||
            report.category.displayName == selectedCategory;

        final matchesStatus =
            statusFilter == null || report.isComplete == statusFilter;

        final matchesSeverity =
            severityFilter == null || report.finalSeverity == severityFilter;

        final matchesPlant =
            selectedPlant == "All Plants" || report.areaName == selectedPlant;

        // ===== HASIL AKHIR (AND) =====
        return matchesSearch &&
            matchesCategory &&
            matchesStatus &&
            matchesSeverity &&
            matchesPlant;
      }).toList();

  return filteredList;
});
