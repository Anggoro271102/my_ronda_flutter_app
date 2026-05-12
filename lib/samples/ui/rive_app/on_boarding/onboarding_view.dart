import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import 'package:flutter_samples/samples/ui/rive_app/assets.dart' as app_assets;

import '../core/localizations/app_localizations.dart';
import '../core/localizations/locale_provider.dart';
import '../navigation/auth/domain/services/auth_service.dart';
import '../navigation/auth/entities/user_model.dart';
import '../navigation/auth/presentation/provider/user_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  // Ubah ke ConsumerStatefulWidget
  const ProfileView({super.key, this.onClose, required this.user});

  final VoidCallback? onClose;
  final UserModel user;

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

final profileStatsProvider = FutureProvider.family<Map<String, String>, int>((
  ref,
  userId,
) async {
  final dio = Dio(BaseOptions(baseUrl: "https://track.cpipga.com"));
  final response = await dio.get('/api/user/profile_stats/$userId');

  final stats = response.data['data'];
  return {
    "total_reports": stats['total_reports'], // Laporan yang dikumpulkan user
    "total_tasks": stats['total_tasks'], // Tugas yang di-assign ke user
    "resolve_percentage": stats['resolve_percentage'], // % Penyelesaian tugas
    "completed_tasks": stats['completed_tasks'],
  };
});

class _ProfileViewState extends ConsumerState<ProfileView> {
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _accentYellow = Color(0xFFFBBF24);
  static const Color _scaffoldBg = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = widget.user;
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Stack(
        children: [
          _buildRiveBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 32),
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),

                  // STATISTICS ROW (SEKARANG DINAMIS)
                  _buildQuickStats(ref, user),

                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.accountDetails),
                  _buildInfoCard([
                    // _profileInfoRow(
                    //   Icons.badge_outlined,
                    //   "Employee ID",
                    //   user.employeeId,
                    // ),
                    _profileInfoRow(Icons.email_outlined, "Email", user.email),
                    _profileInfoRow(
                      Icons.factory_outlined,
                      l10n.department,
                      user.department,
                    ),
                    _profileInfoRow(
                      Icons.computer,
                      l10n.assignedPlant,
                      user.assignedPlant,
                    ),
                  ]),

                  // ... setelah _buildInfoCard ...
                  _buildSectionTitle(l10n.settings),
                  _buildLanguageSelector(ref),

                  // const SizedBox(height: 24),
                  // _buildSectionTitle("Development Station"),
                  // _buildInfoCard([
                  //   _profileInfoRow(
                  //     Icons.computer,
                  //     "Assigned Plant",
                  //     user.assignedPlant,
                  //   ),
                  // ]),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- WIDGET HELPERS ---

  Widget _buildRiveBackground() {
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Center(
            child: OverflowBox(
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: const Offset(200, 100),
                child: Image.asset(app_assets.spline, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const Opacity(
          opacity: 0.3,
          child: RiveAnimation.asset(app_assets.shapesRiv),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.profile,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        // TOMBOL CLOSE (X)
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => widget.onClose?.call(), // Menutup Profile View
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.close, color: Color(0xFF0F172A), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Container(
            //   padding: const EdgeInsets.all(4),
            //   decoration: const BoxDecoration(
            //     color: _accentYellow,
            //     shape: BoxShape.circle,
            //   ),
            //   child: CircleAvatar(
            //     radius: 60,
            //     // Gunakan Avatar URL jika tersedia, jika tidak pakai placeholder
            //     backgroundImage:
            //         (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
            //             ? NetworkImage(user.avatarUrl!)
            //             : const AssetImage(
            //                   "assets/samples/ui/rive_app/images/avatar.png",
            //                 )
            //                 as ImageProvider,
            //   ),
            // ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.blue, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name, // Nama Dinamis
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        Text(
          user.role, // Role Dinamis
          style: const TextStyle(
            fontSize: 14,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(WidgetRef ref, UserModel user) {
    // Memantau data dari API Profile Stats
    final statsAsync = ref.watch(profileStatsProvider(user.userId));
    final l10n = AppLocalizations.of(context)!;
    return statsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, _) => const Text("Error loading stats"),
      data:
          (stats) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // _statItem(user.shift, "Shift"), // Dari tb_users_inspection
                _statItem(stats['resolve_percentage']!, l10n.resolve),
                _statItem(
                  stats['total_reports']!,
                  l10n.reports,
                ), // Laporan yang dikumpulkan
                _statItem(
                  stats['total_tasks']!,
                  l10n.tasks,
                ), // Tugas yang diberikan
                _statItem(stats['completed_tasks']!, "Completed Tasks"),
              ],
            ),
          ),
    );
  }

  Widget _statItem(String value, String label) {
    return Container(
      width: 90, // Ukuran disesuaikan agar muat 4 item dengan scroll
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(children: children),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _accentYellow),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: Colors.redAccent, // Background Merah
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 18),
        onPressed: () {
          // KONFIRMASI LOGOUT
          _showLogoutDialog(context);
        },
        child: const Text(
          "LOGOUT SESSION",
          style: TextStyle(
            color: Colors.white, // Font Putih
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.language_rounded,
            color: Color(0xFFFBBF24),
            size: 22,
          ),
          const SizedBox(width: 16),
          Text(
            l10n.language,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: currentLocale,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF0F172A),
              ),
              borderRadius: BorderRadius.circular(16),
              items: [
                DropdownMenuItem(
                  value: const Locale('id'),
                  child: _buildLangItem("🇮🇩", "Indonesia"),
                ),
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: _buildLangItem("🇺🇸", "English"),
                ),
              ],
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  ref.read(localeProvider.notifier).state = newLocale;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangItem(String flag, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text("Logout"),
            content: const Text(
              "Apakah Anda yakin ingin keluar dari aplikasi?",
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  await AuthService().logout();
                  ref.read(userProvider.notifier).state = null;
                  if (!context.mounted) return;

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }
}
