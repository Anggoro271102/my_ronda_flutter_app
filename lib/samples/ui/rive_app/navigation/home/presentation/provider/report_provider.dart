import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardData {
  final int complete;
  final int incomplete;
  final int total;
  final int good;
  final int warning;
  final int critical;

  DashboardData({
    required this.complete,
    required this.incomplete,
    required this.total,
    required this.good,
    required this.warning,
    required this.critical,
  });

  factory DashboardData.fromJson(
    Map<String, dynamic> json,
    String selectedPlant,
  ) {
    final List<dynamic> progressList = json['progress_by_location'] ?? [];
    final Map<String, dynamic> severityMap = json['severity_by_location'] ?? {};

    // JIKA USER MEMILIH "All Plants" -> LAKUKAN AGREGASI (PENJUMLAHAN)
    if (selectedPlant == "All Plants") {
      int totalComplete = 0;
      int totalIncomplete = 0;
      int totalItems = 0;
      int totalGood = 0;
      int totalWarning = 0;
      int totalCritical = 0;

      // Jumlahkan semua progress
      for (var item in progressList) {
        totalComplete += (item['complete'] as num).toInt();
        totalIncomplete += (item['incomplete'] as num).toInt();
        totalItems += (item['total'] as num).toInt();
      }

      // Jumlahkan semua severity dari Map
      severityMap.forEach((key, value) {
        totalGood += (value['good'] as num).toInt();
        totalWarning += (value['warning'] as num).toInt();
        totalCritical += (value['critical'] as num).toInt();
      });

      return DashboardData(
        complete: totalComplete,
        incomplete: totalIncomplete,
        total: totalItems,
        good: totalGood,
        warning: totalWarning,
        critical: totalCritical,
      );
    }

    // JIKA USER MEMILIH PLANT SPESIFIK (Krian, dsb) -> LAKUKAN FILTER SEPERTI BIASA
    final progress = progressList.firstWhere(
      (item) => item['location_name'].toString().contains(selectedPlant),
      orElse: () => {'complete': 0, 'incomplete': 0, 'total': 0},
    );

    String targetKey = severityMap.keys.firstWhere(
      (key) => key.contains(selectedPlant),
      orElse: () => "",
    );

    final severity =
        targetKey.isNotEmpty
            ? severityMap[targetKey]
            : {'good': 0, 'warning': 0, 'critical': 0};

    return DashboardData(
      complete: (progress['complete'] as num).toInt(),
      incomplete: (progress['incomplete'] as num).toInt(),
      total: (progress['total'] as num).toInt(),
      good: (severity['good'] as num).toInt(),
      warning: (severity['warning'] as num).toInt(),
      critical: (severity['critical'] as num).toInt(),
    );
  }
}

// Di file provider/report_provider.dart atau dashboard_provider.dart

final dashboardStatsProvider = FutureProvider.family<DashboardData, String>((
  ref,
  plantName,
) async {
  final dio = Dio(BaseOptions(baseUrl: "https://track.cpipga.com"));
  final response = await dio.get('/api/dashboard/stats');

  // Kirim data mentah dan filter nama plant ke model
  return DashboardData.fromJson(response.data['data'], plantName);
});
