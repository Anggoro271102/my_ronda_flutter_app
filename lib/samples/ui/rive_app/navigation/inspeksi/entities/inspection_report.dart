import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

/// Definisi tingkat keparahan temuan di lapangan.
enum Severity {
  good, // Kondisi Aman/Bersih
  minor, // Temuan Minor
  major, // Kondisi Bahaya/Sangat Kotor
}

enum Category { cleaning, maintenance, safety, order, equipment, other }

extension CategoryExtension on Category {
  String get displayName {
    switch (this) {
      case Category.cleaning:
        return "Kebersihan";
      case Category.maintenance:
        return "Maintenance";
      case Category.safety:
        return "Keamanan";
      case Category.order:
        return "Ketertiban";
      case Category.equipment:
        return "Peralatan";
      case Category.other:
        return "Lainnya";
    }
  }

  static Category fromString(String value) {
    switch (value) {
      case "Kebersihan":
        return Category.cleaning;
      case "Keamanan":
        return Category.safety;
      case "Ketertiban":
        return Category.order;
      case "Maintenance":
        return Category.maintenance;
      case "Peralatan":
        return Category.equipment;
      default:
        return Category.other;
    }
  }
}

/// Entity utama untuk laporan inspeksi.
class InspectionReport {
  final String id;
  final int userId;
  final bool override;
  final String areaName;
  final DateTime timestamp;
  final Severity aiSeverity; // Hasil prediksi model VLM
  final Severity finalSeverity; // Hasil validasi manusia
  final String description; // Detail temuan
  final String? recommendation;
  final String? imagePath; // Path foto di storage lokal/container
  final double? latitude; // Koordinat GPS untuk mapping
  final double? longitude;
  final Category category;
  final bool isComplete;
  final String objectDetected;
  final String? remediationNote;
  final String? remediationImage;
  final DateTime? resolvedAt;
  final String? pelaporName;
  final String? resolverName;

  InspectionReport({
    required this.override,
    required this.userId,
    required this.id,
    required this.areaName,
    required this.timestamp,
    required this.aiSeverity,
    required this.finalSeverity,
    required this.description,
    required this.category,
    required this.objectDetected,
    required this.isComplete, // ✅ NEW (required)
    this.recommendation, // ✅ NEW
    this.imagePath,
    this.latitude,
    this.longitude,
    this.remediationNote,
    this.remediationImage,
    this.resolvedAt,
    this.pelaporName,
    this.resolverName,
  });

  // --- TAMBAHKAN FACTORY CONSTRUCTOR DI SINI ---
  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is int) return val == 1; // PostgreSQL often sends 1 for true
      if (val is String) return val.toLowerCase() == 'true' || val == '1';
      return false;
    }

    return InspectionReport(
      id: (json['report_id'] ?? json['id'])?.toString() ?? '',
      userId:
          json['user_id'] is int
              ? json['user_id']
              : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      override: json['is_override'] ?? false,
      areaName: json['area_name']?.toString() ?? 'Unknown Area',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'].toString())
              : DateTime.now(),
      objectDetected: json['object_detected']?.toString() ?? '',
      aiSeverity: _parseSeverity(
        (json['ai_severity'] ?? json['final_severity'])?.toString(),
      ),
      finalSeverity: _parseSeverity(json['final_severity']?.toString()),

      description: json['description']?.toString() ?? '',
      recommendation: json['recommendation']?.toString(), // nullable OK
      category: CategoryExtension.fromString(json['category'] ?? "Lainnya"),
      imagePath:
          (json['image_url'] ?? json['image_path'] ?? json['image'])
              ?.toString(),

      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,

      // Gunakan parser yang lebih toleran (Robust Parsing)
      isComplete: parseBool(json['is_complete']),
      remediationNote: json['remediation_note']?.toString(),
      remediationImage: json['remediation_image']?.toString(),
      resolvedAt:
          json['resolved_at'] != null
              ? DateTime.parse(json['resolved_at'].toString())
              : null,
      pelaporName: json['pelapor_name']?.toString(),
      resolverName: json['resolver_name']?.toString(),
    );
  }

  // --- HELPER PARSER (Sangat penting untuk rig i7 kamu agar pemrosesan data akurat) ---
  static Severity _parseSeverity(String? val) {
    if (val == null) return Severity.good;
    final v = val.toLowerCase();
    // Mendukung bahasa Indonesia sesuai kebutuhan AI kamu sebelumnya
    if (v.contains('crit') ||
        v.contains('kritis') ||
        v.contains("major") ||
        v.contains("Critical") ||
        v.contains("critical")) {
      return Severity.major;
    }
    if (v.contains('warn') ||
        v.contains('peringatan') ||
        v.contains("minor") ||
        v.contains("Minor")) {
      return Severity.minor;
    }
    if (v.contains('baik') ||
        v.contains('good') ||
        v.contains("bagus") ||
        v.contains("Bagus") ||
        v.contains("Good")) {
      return Severity.good;
    }

    return Severity.good;
  }


  bool get isResolved => isComplete == true || resolvedAt != null;

  // Letakkan di dalam class model laporan kamu
  IconData get severityIcon {
    switch (finalSeverity) {
      case Severity.good:
        return UniconsLine.check_circle; // Ikon centang dari IconScout
      case Severity.minor:
        return UniconsLine.exclamation_triangle; // Ikon segitiga warning
      case Severity.major:
        return UniconsLine.times_circle;
    }
  }

  Color get severityColor {
    switch (finalSeverity) {
      case Severity.good:
        return Colors.blue;
      case Severity.minor:
        return Colors
            .amber[700]!; // Amber biasanya lebih jelas dibanding Yellow untuk UI
      case Severity.major:
        return Colors.red;
    }
  }
}
