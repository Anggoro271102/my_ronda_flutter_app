// lib/features/inspection/presentation/widgets/ai_result_card.dart

import 'package:flutter/material.dart';

import '../../../inspeksi/entities/inspection_report.dart';

Widget buildAIResult(InspectionReport dummy) {
  return Card(
    color: const Color(0xFF333333),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "ANALISIS AI (VLM)",
            style: TextStyle(
              color: Color(0xFFFDD835),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSeverityInfo("AI Predict", dummy.aiSeverity),
              const Icon(Icons.arrow_forward, color: Colors.white),
              _buildSeverityInfo("User Final", dummy.finalSeverity),
            ],
          ),
          const SizedBox(height: 16),
          Text(dummy.description, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}

Widget _buildSeverityInfo(String label, Severity sev) {
  Color color = sev == Severity.major ? Colors.red : Colors.green;
  return Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          sev.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}
