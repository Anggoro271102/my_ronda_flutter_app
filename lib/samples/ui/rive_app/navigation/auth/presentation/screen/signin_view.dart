import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Tambahkan ini
import 'package:flutter_samples/samples/ui/rive_app/navigation/auth/presentation/screen/register_view.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;

import '../../../../assets.dart' as app_assets;
import '../../../../home.dart';
import '../../domain/services/auth_service.dart';
import '../provider/user_provider.dart'; // Pastikan path provider benar

// 1. Ubah ke ConsumerStatefulWidget agar bisa akses 'ref'
class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

// 2. Ubah ke ConsumerState
class _SignInViewState extends ConsumerState<SignInView> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  late SMITrigger _successAnim;
  late SMITrigger _errorAnim;
  late SMITrigger _confettiAnim;

  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _accentYellow = Color(0xFFFBBF24);

  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _showSessionExpiredNoticeIfAny();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSessionExpiredNoticeIfAny() async {
    final shouldShow = await _authService.consumeSessionExpiredNotice();
    if (!mounted || !shouldShow) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSnackBar("Sesi login sudah habis (10 jam). Silakan login ulang.");
    });
  }

  // --- RIVE LOGIC ---
  void _onCheckRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine 1",
    );
    if (controller != null) {
      artboard.addController(controller);
      _successAnim = controller.findInput<bool>("Check") as SMITrigger;
      _errorAnim = controller.findInput<bool>("Error") as SMITrigger;
    }
  }

  void _onConfettiRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine 1",
    );
    if (controller != null) {
      artboard.addController(controller);
      _confettiAnim =
          controller.findInput<bool>("Trigger explosion") as SMITrigger;
    }
  }

  // --- LOGIN LOGIC ---
  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _errorAnim.fire();
      _showSnackBar("Email dan Password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(email, password);

      if (response.status == "success" && response.data != null) {
        // --- FIX UTAMA: SIMPAN DATA USER KE RIVERPOD ---
        // Baris ini yang akan memberitahu MyReportListScreen siapa user yang login
        ref.read(userProvider.notifier).state = response.data;
        await _authService.saveUserLocal(response.data!);
        // Feedback Visual
        _successAnim.fire();
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _isLoading = false);

        _confettiAnim.fire();
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Navigasi ke Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RiveAppHome(user: response.data!),
          ),
        );
      } else {
        throw Exception("Data user tidak ditemukan");
      }
    } catch (e) {
      _errorAnim.fire();
      _showSnackBar("Login Gagal: ${e.toString()}");
      setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const RegisterView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          _buildDynamicBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Sign In",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 32,
                              color: _textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Input Username dan Password Anda Untuk Memasuki Aplikasi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildLabel("Email Address"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: authInputStyle(
                              Icons.mail_outline_rounded,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel("Password"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passController,
                            obscureText: true,
                            decoration: authInputStyle(
                              Icons.lock_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildLoginButton(),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _goToRegister,
                            child: RichText(
                              text: const TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Buat akun',
                                    style: TextStyle(
                                      color: _accentYellow,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _accentYellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildAnimationOverlay(),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildDynamicBackground() {
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
          opacity: 0.4,
          child: RiveAnimation.asset(app_assets.shapesRiv),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: _textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _accentYellow.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(18),
        color: _accentYellow,
        borderRadius: BorderRadius.circular(16),
        onPressed: () => _isLoading ? null : login(),
        child:
            _isLoading
                ? const CupertinoActivityIndicator(color: Colors.black)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.login_rounded, color: Colors.black, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "SIGN IN",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildAnimationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 120,
                height: 120,
                child: RiveAnimation.asset(
                  app_assets.checkRiv,
                  onInit: _onCheckRiveInit,
                ),
              ),
            Positioned.fill(
              child: Transform.scale(
                scale: 3,
                child: RiveAnimation.asset(
                  app_assets.confettiRiv,
                  onInit: _onConfettiRiveInit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Global Reusable Style for Auth Inputs
InputDecoration authInputStyle(IconData icon) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
  );
}
