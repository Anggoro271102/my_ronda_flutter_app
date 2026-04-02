import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// Provider untuk mengatur Locale aplikasi
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('id'); // Default bahasa Indonesia
});
