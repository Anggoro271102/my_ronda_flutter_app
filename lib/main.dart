import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/domain/services/auth_service.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/entities/user_model.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/presentation/provider/user_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
// Pastikan path import ini sesuai dengan lokasi file SignInView kamu
import 'samples/ui/rive_app/core/localizations/app_localizations.dart';
import 'samples/ui/rive_app/core/localizations/locale_provider.dart';
import 'samples/ui/rive_app/home.dart';
import 'samples/ui/rive_app/navigation/auth/presentation/screen/signin_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _handleLocationPermission();

  // Cek Session sebelum App jalan
  final authService = AuthService();
  final UserModel? loggedInUser = await authService.getLocalUser();
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    ProviderScope(
      overrides: [
        // Jika ada user, masukkan ke provider sejak awal
        if (loggedInUser != null)
          userProvider.overrideWith((ref) => loggedInUser),
      ],
      child: MyApp(initialUser: loggedInUser),
    ),
  );
}

Future<void> _handleLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Cek apakah layanan GPS aktif di HP Redmi Note 8 Pro
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Jika GPS mati, minta user menyalakan (biasanya membuka settings)
    await Geolocator.openLocationSettings();
    return Future.error('Location services are disabled.');
  }

  // Cek status izin saat ini
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // Minta izin ke user
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Jika user menolak permanen, arahkan ke App Settings
    return Future.error('Location permissions are permanently denied.');
  }
}

// 1. Ubah dari StatelessWidget menjadi ConsumerWidget
class MyApp extends ConsumerWidget {
  final UserModel? initialUser;

  const MyApp({super.key, this.initialUser});

  // 2. Tambahkan parameter 'WidgetRef ref' di dalam build
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // Konfigurasi Lokalisasi yang sudah Anda buat
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Sekarang 'ref' sudah terdefinisi dan bisa digunakan
      locale: ref.watch(localeProvider),

      title: 'Feedmill Guard AI',
      debugShowCheckedModeBanner: false,

      // KONFIGURASI TEMA
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

      home:
          initialUser != null
              ? RiveAppHome(user: initialUser!)
              : const SignInView(),

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

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
