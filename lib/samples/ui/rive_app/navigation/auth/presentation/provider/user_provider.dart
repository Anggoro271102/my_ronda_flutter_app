// File: lib/features/auth/presentation/providers/user_provider.dart
import 'package:flutter_riverpod/legacy.dart';
import '../../entities/user_model.dart';

// Provider untuk menyimpan data user secara global
final userProvider = StateProvider<UserModel?>((ref) => null);
