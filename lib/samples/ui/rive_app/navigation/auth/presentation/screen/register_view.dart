import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;

import '../../../../assets.dart' as app_assets;

// ──────────────────────────────────────────────────────────────────────
// CONSTANTS — mirror SignInView palette exactly
// ──────────────────────────────────────────────────────────────────────
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _accentYellow = Color(0xFFFBBF24);
const _scaffoldBg = Color(0xFFF1F5F9);
const _borderColor = Color(0xFFE2E8F0);
const _borderFocus = Color(0xFFFBBF24);
const _chipBg = Color(0xFFF8FAFC);

// ──────────────────────────────────────────────────────────────────────
// DATA — dropdowns
// ──────────────────────────────────────────────────────────────────────
const _roles = [
  'Inspector',
  'Supervisor',
  'Safety Officer',
  'Engineer',
  'Manager',
];

const _departments = [
  'Production',
  'Quality Control',
  'Safety & Health',
  'Maintenance',
  'Warehouse',
  'Administration',
];

const _plants = [
  'Plant Krian',
  'Plant Surabaya',
  'Plant Jakarta',
  'Plant Medan',
  'Plant Makassar',
];

// ──────────────────────────────────────────────────────────────────────
// REGISTER VIEW
// ──────────────────────────────────────────────────────────────────────
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // ── State ──
  String? _selectedRole;
  String? _selectedDepartment;
  String? _selectedPlant;
  String? _avatarPath;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;
  int _otpCooldown = 0;
  bool _isLoading = false;
  bool _isOtpLoading = false;

  // ── Validation errors ──
  final Map<String, String?> _errors = {};

  // ── OTP cooldown timer ──
  late final AnimationController _cooldownAnim;

  @override
  void initState() {
    super.initState();
    _cooldownAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..addListener(() {
            setState(() {
              _otpCooldown = (60 * (1 - _cooldownAnim.value)).ceil();
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                _otpCooldown = 0;
                _otpSent = false;
              });
            }
          });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    _cooldownAnim.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  bool _isValidCpiEmail(String email) {
    // Accept any @cpi.co.id or @cpipga.com domain — adjust to your actual domain
    final lower = email.toLowerCase().trim();
    return lower.contains('@') &&
        (lower.endsWith('@cpi.co.id') ||
            lower.endsWith('@cpipga.com') ||
            lower.endsWith('@gmail.com')); // loosen for dev/testing
  }

  bool _validate() {
    _errors.clear();

    if (_nameCtrl.text.trim().length < 3) {
      _errors['name'] = 'Nama minimal 3 karakter';
    }
    if (_selectedRole == null) {
      _errors['role'] = 'Pilih role terlebih dahulu';
    }
    if (!_isValidCpiEmail(_emailCtrl.text)) {
      _errors['email'] = 'Gunakan email perusahaan yang valid';
    }
    if (_selectedDepartment == null) {
      _errors['department'] = 'Pilih departemen';
    }
    if (_selectedPlant == null) {
      _errors['plant'] = 'Pilih plant/lokasi';
    }
    if (_passCtrl.text.length < 8) {
      _errors['password'] = 'Password minimal 8 karakter';
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _errors['confirm'] = 'Password tidak cocok';
    }
    if (_otpCtrl.text.trim().length != 6) {
      _errors['otp'] = 'Masukkan kode OTP 6 digit';
    }

    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _pickAvatar() async {
    final source = await _showAvatarSourceSheet();
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file != null) {
      setState(() => _avatarPath = file.path);
    }
  }

  Future<ImageSource?> _showAvatarSourceSheet() async {
    return showCupertinoModalPopup<ImageSource>(
      context: context,
      builder:
          (_) => CupertinoActionSheet(
            title: const Text('Pilih Foto Avatar'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Ambil Foto'),
              ),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Pilih dari Galeri'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ),
    );
  }

  Future<void> _sendOtp() async {
    // Validate email before sending OTP
    if (!_isValidCpiEmail(_emailCtrl.text)) {
      setState(
        () => _errors['email'] = 'Masukkan email perusahaan yang valid dulu',
      );
      return;
    }

    setState(() {
      _isOtpLoading = true;
      _errors.remove('email');
    });

    // TODO: integrate with your OTP API endpoint
    // e.g. await ref.read(authServiceProvider).sendOtp(_emailCtrl.text);
    await Future.delayed(const Duration(seconds: 1)); // simulated delay

    setState(() {
      _otpSent = true;
      _isOtpLoading = false;
      _otpCooldown = 60;
    });
    _cooldownAnim.forward(from: 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode OTP dikirim ke ${_emailCtrl.text.trim()}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _submitRegister() {
    if (!_validate()) return;

    // TODO: wire up to your register API
    // e.g. ref.read(authServiceProvider).register(...)
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Stack(
        children: [
          // ── Identical animated background from SignInView ──
          _buildBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // ── Back button ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Main card ──
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(28),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Buat Akun',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Isi data diri Anda untuk mendaftar ke sistem inspeksi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ─────────────────────────────
                        // 1. AVATAR UPLOAD
                        // ─────────────────────────────
                        Center(child: _buildAvatarPicker()),

                        const SizedBox(height: 24),

                        // ─────────────────────────────
                        // 2. FULL NAME
                        // ─────────────────────────────
                        _buildLabel('Nama Lengkap'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameCtrl,
                          hint: 'Masukkan nama lengkap Anda',
                          icon: Icons.person_outline_rounded,
                          errorKey: 'name',
                          keyboardType: TextInputType.name,
                          onChanged:
                              (_) => setState(() => _errors.remove('name')),
                        ),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 3. ROLE (chip selector)
                        // ─────────────────────────────
                        _buildLabel('Role / Jabatan'),
                        const SizedBox(height: 8),
                        _buildChipSelector(
                          items: _roles,
                          selected: _selectedRole,
                          errorKey: 'role',
                          onSelected:
                              (v) => setState(() {
                                _selectedRole = v;
                                _errors.remove('role');
                              }),
                        ),
                        if (_errors['role'] != null)
                          _buildErrorText(_errors['role']!),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 4. CPI EMAIL
                        // ─────────────────────────────
                        _buildLabel('Email Perusahaan (CPI)'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailCtrl,
                          hint: 'nama@cpi.co.id',
                          icon: Icons.email_outlined,
                          errorKey: 'email',
                          keyboardType: TextInputType.emailAddress,
                          onChanged:
                              (_) => setState(() => _errors.remove('email')),
                        ),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 5. DEPARTMENT (dropdown)
                        // ─────────────────────────────
                        _buildLabel('Departemen'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          hint: 'Pilih departemen',
                          icon: Icons.business_outlined,
                          items: _departments,
                          value: _selectedDepartment,
                          errorKey: 'department',
                          onChanged:
                              (v) => setState(() {
                                _selectedDepartment = v;
                                _errors.remove('department');
                              }),
                        ),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 6. ASSIGNED PLANT (dropdown)
                        // ─────────────────────────────
                        _buildLabel('Plant / Lokasi Tugas'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          hint: 'Pilih plant',
                          icon: Icons.factory_outlined,
                          items: _plants,
                          value: _selectedPlant,
                          errorKey: 'plant',
                          onChanged:
                              (v) => setState(() {
                                _selectedPlant = v;
                                _errors.remove('plant');
                              }),
                        ),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 7. PASSWORD
                        // ─────────────────────────────
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _passCtrl,
                          hint: 'Minimal 8 karakter',
                          obscure: _obscurePass,
                          errorKey: 'password',
                          onToggle:
                              () =>
                                  setState(() => _obscurePass = !_obscurePass),
                          onChanged:
                              (_) => setState(() => _errors.remove('password')),
                        ),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 8. CONFIRM PASSWORD
                        // ─────────────────────────────
                        _buildLabel('Konfirmasi Password'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _confirmCtrl,
                          hint: 'Ulangi password Anda',
                          obscure: _obscureConfirm,
                          errorKey: 'confirm',
                          onToggle:
                              () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                          onChanged:
                              (_) => setState(() => _errors.remove('confirm')),
                        ),

                        const SizedBox(height: 18),

                        // ─────────────────────────────
                        // 9. OTP SECTION
                        // ─────────────────────────────
                        _buildLabel('Verifikasi OTP Email'),
                        const SizedBox(height: 8),
                        _buildOtpSection(),

                        const SizedBox(height: 28),

                        // ─────────────────────────────
                        // 10. SUBMIT BUTTON
                        // ─────────────────────────────
                        _buildRegisterButton(),

                        const SizedBox(height: 20),

                        // ─────────────────────────────
                        // 11. BACK TO LOGIN
                        // ─────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Sudah punya akun? ',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Masuk di sini',
                                    style: TextStyle(
                                      color: _accentYellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ── Full-screen loading overlay ──
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ── Rive Background (identical to SignInView) ──────────────────────
  Widget _buildBackground() {
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

  // ── Avatar Picker ──────────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _chipBg,
                  border: Border.all(
                    color: _avatarPath != null ? _accentYellow : _borderColor,
                    width: _avatarPath != null ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  image:
                      _avatarPath != null
                          ? DecorationImage(
                            image: FileImage(File(_avatarPath!)),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _avatarPath == null
                        ? const Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        )
                        : null,
              ),

              // Camera badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accentYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _accentYellow.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _avatarPath != null ? 'Ganti Foto' : 'Upload Foto (Opsional)',
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────
  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: _textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );

  Widget _buildErrorText(String msg) => Padding(
    padding: const EdgeInsets.only(top: 5, left: 4),
    child: Text(
      msg,
      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
    ),
  );

  // ── Generic TextField ──────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String errorKey,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    final hasError = _errors[errorKey] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : _borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : _borderFocus,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        if (hasError) _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  // ── Password TextField ─────────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required String errorKey,
    required VoidCallback onToggle,
    void Function(String)? onChanged,
  }) {
    final hasError = _errors[errorKey] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            suffixIcon: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onToggle,
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : _borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : _borderFocus,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        if (hasError) _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  // ── Dropdown ───────────────────────────────────────────────────────
  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required String errorKey,
    required void Function(String?) onChanged,
  }) {
    final hasError = _errors[errorKey] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  hasError
                      ? Colors.redAccent
                      : value != null
                      ? _accentYellow
                      : _borderColor,
              width: value != null && !hasError ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(icon, color: const Color(0xFF64748B), size: 20),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      hint,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    items:
                        items
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  // ── Chip Selector (for Role) ───────────────────────────────────────
  Widget _buildChipSelector({
    required List<String> items,
    required String? selected,
    required String errorKey,
    required void Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            final isSelected = selected == item;
            return GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _accentYellow : _chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _accentYellow : _borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: _accentYellow.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : _textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ── OTP Section ────────────────────────────────────────────────────
  Widget _buildOtpSection() {
    final canResend = !_otpSent || _otpCooldown == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner
        if (_otpSent)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kode OTP dikirim ke ${_emailCtrl.text.trim()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // OTP input + Send button row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OTP TextField
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (_) => setState(() => _errors.remove('otp')),
                    style: const TextStyle(
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '------',
                      hintStyle: TextStyle(
                        letterSpacing: 6,
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.pin_outlined,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _errors['otp'] != null
                                  ? Colors.redAccent
                                  : _borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _errors['otp'] != null
                                  ? Colors.redAccent
                                  : _borderFocus,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (_errors['otp'] != null) _buildErrorText(_errors['otp']!),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Send OTP button
            Column(
              children: [
                SizedBox(
                  height: 52,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: canResend && !_isOtpLoading ? _sendOtp : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color:
                            canResend && !_isOtpLoading
                                ? _accentYellow
                                : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                            canResend && !_isOtpLoading
                                ? [
                                  BoxShadow(
                                    color: _accentYellow.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child:
                          _isOtpLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CupertinoActivityIndicator(
                                  color: Colors.black,
                                ),
                              )
                              : Text(
                                _otpSent && _otpCooldown > 0
                                    ? '${_otpCooldown}s'
                                    : 'Kirim OTP',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      canResend && !_isOtpLoading
                                          ? Colors.black
                                          : const Color(0xFF94A3B8),
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Register Submit Button ─────────────────────────────────────────
  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _submitRegister,
        child:
            _isLoading
                ? const CupertinoActivityIndicator(color: Colors.black)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.how_to_reg_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'DAFTAR SEKARANG',
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

  // ── Loading Overlay ────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CupertinoActivityIndicator(color: _accentYellow, radius: 16),
                SizedBox(height: 14),
                Text(
                  'Memproses pendaftaran...',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
