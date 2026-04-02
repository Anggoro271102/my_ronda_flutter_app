import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../inspeksi/entities/inspection_report.dart';
import '../screen/report_list_screen.dart';

// --- 1. STATE PROVIDERS (Input UI) ---
final searchQueryProvider = StateProvider<String>((ref) => "");
final selectedStatusFilterProvider = StateProvider<bool?>((ref) => null);
final selectedSeverityFilterProvider = StateProvider<Severity?>((ref) => null);
final plantFilterProvider = StateProvider<String>((ref) => "All Plants");
final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.area);
final isFilterExpandedProvider = StateProvider<bool>((ref) => false);

// --- 2. DATA SOURCE PROVIDER (API) ---
/// Mengambil data mentah dari server track.cpipga.com
final reportsRawProvider = FutureProvider.family<List<InspectionReport>, int?>((
  ref,
  userId,
) async {
  // Debug print untuk memantau request di terminal VS Code kamu
  print("DEBUG [RawProvider]: Request API untuk User ID: $userId");

  final dio = Dio(
    BaseOptions(
      baseUrl: "https://track.cpipga.com",
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  try {
    final response = await dio.get(
      '/api/inspection/reports',
      queryParameters: {
        // Jika userId ada, kirim ke API agar Database memfilter di awal
        if (userId != null) 'user_id': userId,
      },
    );

    if (response.statusCode == 200) {
      final List data = response.data['data'];
      return data.map((json) => InspectionReport.fromJson(json)).toList();
    } else {
      throw Exception("Server memberikan respon error: ${response.statusCode}");
    }
  } on DioException catch (e) {
    throw Exception("Masalah Jaringan/CORS: ${e.message}");
  }
});

// --- 3. FILTER LOGIC PROVIDER (Client-Side) ---
/// Melakukan penyaringan akhir sebelum data ditampilkan ke list
final filteredReportsProvider = Provider.family<
  AsyncValue<List<InspectionReport>>,
  int?
>((ref, userId) {
  // Menonton perubahan data mentah dari API
  final asyncAllReports = ref.watch(reportsRawProvider(userId));

  // Menonton semua state filter dari UI
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final searchType = ref.watch(searchTypeProvider);
  final statusFilter = ref.watch(selectedStatusFilterProvider);
  final severityFilter = ref.watch(selectedSeverityFilterProvider);
  final plantFilter = ref.watch(plantFilterProvider);

  return asyncAllReports.whenData((allReports) {
    // Proses penyaringan menggunakan CPU i7-14700
    return allReports.where((report) {
      // A. FILTER USER (KUNCI PERBAIKAN)
      // Jika kita di halaman 'My Reports' (userId != null),
      // maka data yang lolos HANYA yang punya report.userId yang sama.
      if (userId != null) {
        print("COMPARE: LoginID($userId) vs ReportOwner(${report.userId})");
        if (report.userId != userId) return false;
      }

      // B. FILTER SEARCH (ID vs Area)
      bool matchesQuery = true;
      if (query.isNotEmpty) {
        if (searchType == SearchType.id) {
          matchesQuery = report.id.toLowerCase().contains(query);
        } else {
          matchesQuery = report.areaName.toLowerCase().contains(query);
        }
      }

      // C. FILTER STATUS (Complete/Incomplete)
      final matchesStatus =
          statusFilter == null || report.isComplete == statusFilter;

      // D. FILTER SEVERITY
      final matchesSeverity =
          severityFilter == null || report.finalSeverity == severityFilter;

      // E. FILTER PLANT
      final matchesPlant =
          plantFilter == "All Plants" || report.areaName.contains(plantFilter);

      return matchesQuery && matchesStatus && matchesSeverity && matchesPlant;
    }).toList();
  });
});
