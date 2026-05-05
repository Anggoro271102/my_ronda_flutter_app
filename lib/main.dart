import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

// Pastikan path import ini sesuai dengan lokasi file kamu
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/domain/services/auth_service.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/entities/user_model.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/presentation/provider/user_provider.dart';
import 'samples/ui/rive_app/core/localizations/app_localizations.dart';
import 'samples/ui/rive_app/core/localizations/locale_provider.dart';
import 'samples/ui/rive_app/home.dart';
import 'samples/ui/rive_app/navigation/auth/presentation/screen/signin_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bypass SSL
  HttpOverrides.global = MyHttpOverrides();

  // 1. Cek Session sebelum App jalan (Ini AMAN karena tidak memunculkan UI)
  final authService = AuthService(session: false);
  final UserModel? loggedInUser = await authService.getLocalUser();

  runApp(
    ProviderScope(
      overrides: [
        if (loggedInUser != null)
          userProvider.overrideWith((ref) => loggedInUser),
      ],
      child: MyApp(initialUser: loggedInUser),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends ConsumerWidget {
  final UserModel? initialUser;

  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),
      title: 'Feedmill Guard AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        fontFamily: "Inter",
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFBBF24),
          primary: const Color(0xFFFBBF24),
          surface: Colors.white,
        ),
      ),
      // 2. Arahkan home ke SplashScreen terlebih dahulu!
      home: SplashScreen(initialUser: initialUser),
      onGenerateRoute: (settings) {
        if (settings.name == "/home") {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(
            builder: (context) => RiveAppHome(user: user),
          );
        }
        if (settings.name == "/login") {
          return MaterialPageRoute(builder: (context) => const SignInView());
        }
        return null;
      },
    );
  }
}

// ==========================================
// 3. SPLASH SCREEN (Gatekeeper Izin Aplikasi)
// ==========================================
class SplashScreen extends StatefulWidget {
  final UserModel? initialUser;
  const SplashScreen({super.key, this.initialUser});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// TAMBAHKAN 'with WidgetsBindingObserver' di sini
class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  String _loadingText = "Menyiapkan sistem...";
  bool _isError = false;
  bool _isChecking = false;

  // Variabel Versi Aplikasi
  String _appVersion = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isChecking) {
      _handleLocationPermission();
    }
  }

  Future<void> _initializeApp() async {
    // 1. Ambil data versi dari pubspec.yaml secara dinamis
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = "Versi ${packageInfo.version}+${packageInfo.buildNumber}";
    });

    // 2. Beri jeda visual sedikit, lalu lanjut cek lokasi
    await Future.delayed(const Duration(seconds: 1));
    await _handleLocationPermission();
  }

  Future<void> _handleLocationPermission() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _isError = false;
      _loadingText = "Mengecek akses lokasi...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _loadingText = "Mohon nyalakan GPS / Lokasi Anda.";
        _isError = true;
        _isChecking = false;
      });
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _loadingText = "S.H.I.E.L.D butuh izin lokasi untuk beroperasi.";
          _isError = true;
          _isChecking = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _loadingText = "Izin diblokir. Buka Pengaturan HP -> Izin Aplikasi.";
        _isError = true;
        _isChecking = false;
      });
      await Geolocator.openAppSettings();
      return;
    }

    setState(() {
      _loadingText = "Akses Diberikan! Membuka sistem...";
      _isChecking = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    _navigateNext();
  }

  void _navigateNext() {
    if (widget.initialUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RiveAppHome(user: widget.initialUser!),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. BACKGROUND BARU (Terang)
      backgroundColor: const Color(0xFFECEDF5),
      body: Stack(
        children: [
          // --- BAGIAN TENGAH: LOGO & NAMA APLIKASI ---
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2. ICON ASET KAMU
                Image.asset(
                  'assets/icons/last_version_icon.png',
                  width: 140,
                  height: 140,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.security_rounded,
                        size: 120,
                        color: Color(0xFFFBBF24), // Warna kuning emas
                      ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'S.H.I.E.L.D',
                  style: TextStyle(
                    // Jika warna FBBF24 terlalu terang di background abu-abu,
                    // kamu bisa ubah ke warna gelap seperti Color(0xFF1E293B)
                    color: Color(0xFFFBBF24),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'FEEDMILL GUARD AI',
                  style: TextStyle(
                    // 3. TEKS DIUBAH MENJADI GELAP AGAR TERBACA
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ),

          // --- BAGIAN BAWAH: LOADING, PESAN, & VERSI ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 32, right: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animasi Loading atau Icon Error
                  if (!_isError)
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFBBF24),
                        strokeWidth: 3.5,
                      ),
                    )
                  else
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 42,
                    ),

                  const SizedBox(height: 20),

                  // Teks Status
                  Text(
                    _loadingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      // 4. TEKS STATUS DIUBAH MENJADI GELAP
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),

                  // Tombol Penyelamat (Muncul jika error)
                  if (_isError) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _handleLocationPermission,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white, // Ikon dalam tombol jadi putih
                        size: 20,
                      ),
                      label: const Text(
                        "Coba Lagi",
                        style: TextStyle(
                          color: Colors.white, // Teks dalam tombol jadi putih
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        // Warna tombol tetap FBBF24, tapi teks putih agar kontras
                        backgroundColor: const Color(0xFFFBBF24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Teks Versi Aplikasi
                  Text(
                    _appVersion,
                    style: const TextStyle(
                      // 5. TEKS VERSI DIUBAH MENJADI ABU-ABU GELAP
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
