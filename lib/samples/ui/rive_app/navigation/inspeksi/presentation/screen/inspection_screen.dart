import 'dart:io';
// Ganti baris import material/cupertino kamu menjadi seperti ini:
import 'package:flutter/material.dart' hide Category;
import 'package:flutter/cupertino.dart' hide Category;
import 'package:flutter/foundation.dart'
    hide Category; // Tambahkan jika ada// Tambahkan juga di sini

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:image_picker/image_picker.dart';

import '../../../../core/localizations/app_localizations.dart';
import '../../../../theme.dart';
import '../../../auth/presentation/provider/user_provider.dart';
// import '../../../detail/presentation/screen/report_detail_screen.dart';
import '../../../list_inspeksi/presentation/provider/filter_provider.dart';
import '../../entities/inspection_report.dart' as ent;
import '../provider/inspection_provider.dart';

// Provider UI tetap dipertahankan
// Ini mencegah data "nyangkut" yang bisa bikin UI blank saat dibuka kembali
final isOverrideProvider = StateProvider.autoDispose<bool>((ref) => false);
final manualSeverityProvider = StateProvider.autoDispose<ent.Severity?>(
  (ref) => null,
);
final selectedImageProvider = StateProvider.autoDispose<String?>((ref) => null);

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key});

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  // Controller untuk menangkap input manual saat Override ON
  final TextEditingController _manualObjController = TextEditingController();
  final TextEditingController _manualCatController = TextEditingController();
  final TextEditingController _manualNoteController = TextEditingController();
  final TextEditingController _manualRecController = TextEditingController();
  late final ProviderSubscription<InspectionState> _errorSub;
  @override
  void initState() {
    super.initState();

    _errorSub = ref.listenManual<InspectionState>(inspectionStateProvider, (
      prev,
      next,
    ) {
      // Tampilkan dialog hanya kalau error baru muncul
      if (next.error != null && prev?.error != next.error) {
        // kalau error bukan DioException, bisa juga kamu handle di sini
        _showNetworkErrorDialog(context, ref, next.error!);
      }
    });
  }

  @override
  void dispose() {
    _errorSub.close();
    _manualObjController.dispose();
    _manualCatController.dispose();
    _manualNoteController.dispose();
    _manualRecController.dispose();
    // Provider otomatis ter-reset karena menggunakan .autoDispose
    super.dispose();
  }

  void _showNetworkErrorDialog(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text("Gagal Mengirim"),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                  // optional: bersihkan error biar gak muncul lagi
                  ref.read(inspectionStateProvider.notifier).clearError();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text("Kirim Ulang"),
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(inspectionStateProvider.notifier)
                      .retryLastAction();
                },
              ),
            ],
          ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    InspectionState inspection,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text("Mode Edit"),
            content: const Text("Ubah detail laporan secara manual?"),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text("Lanjutkan"),
                onPressed: () {
                  // 1. Aktifkan Mode Override
                  ref.read(isOverrideProvider.notifier).state = true;

                  // 2. Ambil kategori asli hasil deteksi AI (misal: "Kebersihan")
                  final String? aiCategoryRaw = inspection.category;

                  // 3. Konversi String tersebut menjadi Enum ent.Category
                  // Jika aiCategoryRaw null, barulah kita berikan fallback ke ent.Category.other
                  final ent.Category aiEnum = ent.CategoryExtension.fromString(
                    aiCategoryRaw ?? "Lainnya",
                  );

                  // 4. Update Provider (Agar kartu kategori yang berwarna orange sinkron dengan AI)
                  ref.read(manualCategoryProvider.notifier).state =
                      aiEnum as ent.Category?;

                  // 5. Update Controller (Agar teks di baris Kategori sinkron dengan AI)
                  _manualCatController.text = aiEnum.displayName;

                  Navigator.pop(context);
                  debugPrint(
                    "Override Aktif. Default awal diset ke: ${aiEnum.displayName}",
                  );
                },
              ),
            ],
          ),
    );
  }

  void _resetForm() {
    // 1. Kosongkan semua Controller teks
    _manualObjController.clear();
    _manualCatController.clear();
    _manualNoteController.clear();
    _manualRecController.clear();

    // 2. Reset UI Providers menggunakan invalidate
    // Ini akan mengembalikan provider ke nilai defaultnya
    ref.invalidate(isOverrideProvider);
    ref.invalidate(manualSeverityProvider);
    ref.invalidate(selectedImageProvider);

    // 3. Reset State Utama (Logika AI)
    ref.invalidate(inspectionStateProvider);
  }
  // Di dalam _InspectionScreenState

  Future<File?> _compressFile(File file) async {
    final filePath = file.absolute.path;

    // Membuat output path di folder temporary
    final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70, // Kompresi ke 70% sudah cukup untuk Qwen-VL 7B
      minWidth: 1024, // Resize ke 1024px agar tidak terlalu berat
      minHeight: 1024,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _handleUpdate(BuildContext context) async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await ref
        .read(inspectionStateProvider.notifier)
        .submitFinalReport(
          userId: currentUser.userId,
          isOverride: ref.read(isOverrideProvider),
          manualObject: _manualObjController.text,
          manualCategory: _manualCatController.text,
          manualNotes: _manualNoteController.text,
          manualRecommendation: _manualRecController.text,
          manualSeverity: ref.read(manualSeverityProvider)?.name ?? "Good",
        );

    if (!context.mounted) return;

    debugPrint("AFTER SUBMIT -> canPop=${Navigator.of(context).canPop()}");

    if (success) {
      ref.invalidate(reportsRawProvider);
      ref.invalidate(filteredReportsProvider);
      _resetForm();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Laporan Berhasil Disimpan"),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ FIX UTAMA: jangan pop kalau ini root
      if (navigator.canPop()) {
        navigator.pop(true); // optional: kirim hasil ke screen sebelumnya
      } else {
        // fallback: arahkan ke route yang pasti ada
        navigator.pushReplacementNamed(
          '/home',
        ); // sesuaikan dengan route app kamu
        // atau: navigator.pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal: ${ref.read(inspectionStateProvider).error}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Alur 1: Ambil Gambar -> Proses AI -> Submit AI (Otomatis)
  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80, // Step 1: Kompresi dasar dari picker
    );

    if (pickedFile != null) {
      File fileToProcess = File(pickedFile.path);

      // Step 2: Kompresi lanjutan untuk menghindari Error 413
      final compressedFile = await _compressFile(fileToProcess);

      if (compressedFile != null) {
        ref.read(selectedImageProvider.notifier).state = compressedFile.path;

        // Kirim path gambar yang sudah DIKOMPRES ke provider
        ref
            .read(inspectionStateProvider.notifier)
            .processInspection(compressedFile.path, currentUser.userId);
      }
    }
  }

  void _showPickerOptions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(l10n.camera),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ref, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(l10n.gallery),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ref, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // Palette Warna Original Mario
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF212121);
  static const Color _accentYellow = Color(0xFFFDD835);

  @override
  Widget build(BuildContext context) {
    final inspection = ref.watch(inspectionStateProvider);
    final isOverride = ref.watch(isOverrideProvider);
    final selectedSeverity = ref.watch(manualSeverityProvider);
    final l10n = AppLocalizations.of(context)!;
    // Helper warna yang aman dari null

    final backgroundColor = RiveAppTheme.background;
    Color severityColor = Colors.grey;

    ref.listen<InspectionState>(inspectionStateProvider, (previous, next) {
      // Jika reportId kosong (reset/auto-dispose) dan tidak sedang loading
      if (next.reportId == null && !next.isLoading) {
        _manualObjController.clear();
        _manualCatController.clear();
        _manualNoteController.clear();
        _manualRecController.clear();
        debugPrint("🔄 Tampilan Kembali ke Default");
      }
      // Jika data AI baru dari RTX 4070 masuk, isi otomatis
      else if (next.reportId != null && !next.isLoading) {
        _manualObjController.text = next.objectDetected ?? "...";
        _manualCatController.text = next.category ?? "...";
        _manualNoteController.text = next.description ?? "...";
        _manualRecController.text = next.recommendation ?? "...";

        final aiSev = next.severity?.toLowerCase() ?? "";
        if (aiSev.contains("critical") || aiSev.contains("kritis")) {
          ref.read(manualSeverityProvider.notifier).state = ent.Severity.major;
        } else if (aiSev.contains("minor") || aiSev.contains("peringatan")) {
          ref.read(manualSeverityProvider.notifier).state = ent.Severity.minor;
        } else if (aiSev.contains("good") || aiSev.contains("baik")) {
          ref.read(manualSeverityProvider.notifier).state = ent.Severity.good;
        }
      }
    });

    String displaySeverityText = "...";
    if (isOverride) {
      displaySeverityText =
          selectedSeverity?.name.toUpperCase() ?? "Pilih Severity";
    } else {
      displaySeverityText = inspection.severity ?? "...";
      if (displaySeverityText.contains("Kritis") ||
          displaySeverityText.contains("critical") ||
          displaySeverityText.contains("Critical")) {
        displaySeverityText = "MAJOR";
        severityColor = Colors.red;
      } else if (displaySeverityText.contains("Peringatan") ||
          displaySeverityText.contains("warning") ||
          displaySeverityText.contains("Minor")) {
        displaySeverityText = "MINOR";
        severityColor = Colors.amber[700]!;
      } else if (displaySeverityText.contains("Baik") ||
          displaySeverityText.contains("good") ||
          displaySeverityText.contains("Bagus") ||
          displaySeverityText.contains("Good")) {
        displaySeverityText = "GOOD";
        severityColor = Colors.blue;
      }
    }

    // Default saat loading/null

    if (displaySeverityText.contains("Kritis") ||
        displaySeverityText.contains("critical") ||
        displaySeverityText.contains("Critical")) {
      severityColor = Colors.red;
    } else if (displaySeverityText.contains("Peringatan") ||
        displaySeverityText.contains("warning") ||
        displaySeverityText.contains("Minor")) {
      severityColor = Colors.amber[700]!;
    } else if (displaySeverityText.contains("Baik") ||
        displaySeverityText.contains("good") ||
        displaySeverityText.contains("Good")) {
      severityColor = Colors.blue;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: RiveAppTheme.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    Center(
                      child: Text(
                        l10n.inspection,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildCameraPreview(context, ref),

                    const SizedBox(height: 32),
                    Text(
                      l10n.analysisResult,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AREA HASIL DINAMIS (Data dari State Provider)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // _buildResultRow(
                          //   "Objek Terdeteksi",
                          //   inspection.objectDetected ?? "...",
                          //   Icons.grain,
                          // ),

                          // TextFormField(
                          //   controller: objectController,
                          //   style: TextStyle(
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 16,
                          //   ),
                          //   decoration: InputDecoration(
                          //     labelText: "Objek Terdeteksi",
                          //     prefixIcon: Icon(Icons.grain),
                          //     border: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(12),
                          //     ),
                          //     contentPadding: EdgeInsets.symmetric(
                          //       horizontal: 12,
                          //       vertical: 8,
                          //     ),
                          //   ),
                          //   onChanged: (value) {
                          //     // Update state/provider Anda di sini saat teks berubah
                          //     // Contoh: ref.read(manualObjectProvider.notifier).state = value;
                          //   },
                          // ),
                          _buildEditableRow(
                            ref,
                            l10n.objectDetected,
                            Icons.grain,
                            _manualObjController,
                            isOverride,
                          ),
                          const Divider(height: 24),
                          _buildEditableRow(
                            ref,
                            l10n.category,
                            Icons.category,
                            _manualCatController,
                            isOverride,
                            color: Colors.orange,
                            readOnly: true,
                          ),

                          // --- PANEL KARTU KATEGORI (GRID) ---
                          // --- PANEL KARTU KATEGORI (GRID 3-KOLOM) ---
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child:
                                isOverride
                                    ? Container(
                                      padding: const EdgeInsets.only(
                                        top: 16,
                                        bottom: 0,
                                      ), // Kurangi padding bawah ke 0
                                      child: GridView.count(
                                        padding:
                                            EdgeInsets
                                                .zero, // WAJIB: Hilangkan default padding internal GridView
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio:
                                            2.1, // Sedikit disesuaikan agar lebih proporsional
                                        children:
                                            ent.Category.values.map((cat) {
                                              final isSelected =
                                                  ref.watch(
                                                    manualCategoryProvider,
                                                  ) ==
                                                  cat;
                                              return _buildCategorySelectionCard(
                                                ref,
                                                cat,
                                                isSelected,
                                              );
                                            }).toList(),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            l10n.gpsLocation,
                            inspection.locationName ?? "...",
                            Icons.location_on,
                            valueColor: Colors.blue,
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            l10n.severity, // Kita ubah labelnya agar lebih umum
                            displaySeverityText,
                            Icons.warning_amber_rounded,
                            valueColor: severityColor,
                          ),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAISeverityCard(
                                label: "Good",
                                color: Colors.blue,
                                isSelected:
                                    selectedSeverity == ent.Severity.good,
                                // HANYA BISA DIKLIK JIKA OVERRIDE ON
                                onTap:
                                    isOverride
                                        ? () =>
                                            ref
                                                .read(
                                                  manualSeverityProvider
                                                      .notifier,
                                                )
                                                .state = ent.Severity.good
                                        : null,
                              ),
                              _buildAISeverityCard(
                                label: "Minor",
                                color: Colors.amber[700]!,
                                isSelected:
                                    selectedSeverity == ent.Severity.minor,
                                onTap:
                                    isOverride
                                        ? () =>
                                            ref
                                                .read(
                                                  manualSeverityProvider
                                                      .notifier,
                                                )
                                                .state = ent.Severity.minor
                                        : null,
                              ),
                              _buildAISeverityCard(
                                label: "Major",
                                color: Colors.red,
                                isSelected:
                                    selectedSeverity == ent.Severity.major,
                                onTap:
                                    isOverride
                                        ? () =>
                                            ref
                                                .read(
                                                  manualSeverityProvider
                                                      .notifier,
                                                )
                                                .state = ent.Severity.major
                                        : null,
                              ),
                            ],
                          ),

                          const Divider(height: 24),
                          _buildEditableDescriptionRow(
                            l10n.description,
                            _manualNoteController,
                            isOverride,
                            Icons.auto_awesome_outlined,
                            Icons.description_outlined,
                          ),
                          const Divider(height: 24),
                          _buildEditableDescriptionRow(
                            l10n.recommendation,
                            _manualRecController,
                            isOverride,
                            Icons.tips_and_updates,
                            Icons.auto_awesome_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    _buildValidationInput(ref, context),
                    const SizedBox(height: 40),

                    // Alur 2: Submit Final (Gunakan data Manual jika Override ON)
                    _buildSubmitButton(
                      isEnabled:
                          !inspection.isLoading && inspection.reportId != null,
                      onPressed:
                          () => _handleUpdate(
                            context,
                          ), // Panggil fungsi yang sudah diperbaiki
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            // LOADING OVERLAY (Dijalankan saat GPU RTX 4070 sedang proses)
            if (inspection.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _accentYellow),
                        const SizedBox(height: 16),
                        Text(
                          l10n.uploadToServer,
                          style: const TextStyle(
                            color: Colors.white,
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
    );
  }

  // --- WIDGET HELPERS (DIPERTAHANKAN SESUAI TAMPILAN ORIGINAL) ---
  Widget _buildCategorySelectionCard(
    WidgetRef ref,
    ent.Category cat,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(manualCategoryProvider.notifier).state = cat as ent.Category?;
        _manualCatController.text = cat.displayName;
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Padding kecil agar teks tidak menempel ke border
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.black,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: FittedBox(
            // <--- KUNCI ANTI OVERFLOW
            fit: BoxFit.scaleDown,
            child: Text(
              cat.displayName,
              style: TextStyle(
                fontSize: 12, // Font dasar
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableDescriptionRow(
    String label,
    TextEditingController controller,
    bool isOverride,
    IconData icon,
    IconData iconTitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconTitle, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border:
                isOverride
                    ? Border.all(color: _accentYellow.withOpacity(0.5))
                    : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: _accentYellow),
              const SizedBox(width: 10),
              Expanded(
                child:
                    isOverride
                        ? TextField(
                          controller: controller,
                          maxLines: null, // Membuatnya auto-expand ke bawah
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: "Masukkan detail manual...",
                          ),
                        )
                        : Text(
                          controller.text.isEmpty
                              ? ".........."
                              : controller.text,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(
    WidgetRef ref,
    String label,
    IconData icon,
    TextEditingController controller,
    bool isEditMode, {
    Color? color,
    bool readOnly = false, // Parameter kunci untuk mengontrol input
  }) {
    // Logika: Tampilkan TextField hanya jika Mode Edit AKTIF dan BUKAN Read-Only
    final bool showTextField = isEditMode && !readOnly;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon dan Label di sisi kiri
        Icon(icon, size: 20, color: const Color.fromARGB(255, 5, 4, 4)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),

        const SizedBox(width: 16),

        // Area Nilai di sisi kanan
        Expanded(
          child:
              showTextField
                  ? TextField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color ?? const Color(0xFF212121),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: "...",
                    ),
                    maxLines: null, // Auto-expand jika teks panjang
                  )
                  : Text(
                    // Jika kosong, tampilkan titik-titik agar UI tidak kopong
                    controller.text.isEmpty ? "..." : controller.text,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: color ?? const Color(0xFF212121),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(BuildContext context, WidgetRef ref) {
    final imagePath = ref.watch(selectedImageProvider);
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        image:
            imagePath != null
                ? DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imagePath == null)
            const Icon(
              Icons.camera_enhance_rounded,
              size: 48,
              color: Colors.grey,
            ),
          Positioned(
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showPickerOptions(context, ref),
              backgroundColor: _accentYellow,
              mini: true,
              child: Icon(
                imagePath == null ? Icons.add_a_photo : Icons.edit,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    IconData icon, {
    Color valueColor = _textPrimary,
  }) {
    return Row(
      // Menggunakan CrossAxisAlignment.start agar jika teks value wrap,
      // label dan icon tetap berada di baris pertama (sejajar atas).
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        // Memberikan jarak minimal antara label dan value
        const SizedBox(width: 16),
        // Expanded memaksa Text untuk mengambil sisa ruang yang tersedia
        // dan melakukan wrapping jika teks melebihi ruang tersebut.
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAISeverityCard({
    required String label,
    required Color color,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationInput(WidgetRef ref, BuildContext context) {
    final isOverride = ref.watch(isOverrideProvider);
    final inspection = ref.watch(inspectionStateProvider);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.manualOverride,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: isOverride,
                  onChanged: (v) {
                    if (v == true) {
                      // INTERCEPT: Tampilkan dialog konfirmasi dulu
                      _showEditDialog(context, ref, inspection);
                    } else {
                      // 1. Matikan toggle langsung
                      ref.read(isOverrideProvider.notifier).state = false;

                      // 2. LOGIKA PERBAIKAN: Kembalikan ke hasil AI (Logic tetap seperti sebelumnya)
                      final aiResult = inspection.severity;
                      if (aiResult != null) {
                        if (aiResult.contains("Kritis")) {
                          ref.read(manualSeverityProvider.notifier).state =
                              ent.Severity.major;
                        } else if (aiResult.contains("Peringatan")) {
                          ref.read(manualSeverityProvider.notifier).state =
                              ent.Severity.minor;
                        } else if (aiResult.contains("Baik")) {
                          ref.read(manualSeverityProvider.notifier).state =
                              ent.Severity.good;
                        }
                      }
                    }
                    // 1. Update status toggle
                    // ref.read(isOverrideProvider.notifier).state = v;

                    // 2. LOGIKA PERBAIKAN: Jika toggle dimatikan (OFF)
                    // if (v == false) {
                    //   final aiResult = inspection.severity;
                    //   if (aiResult != null) {
                    //     // Kembalikan pilihan kartu ke hasil AI
                    //     if (aiResult.contains("Kritis")) {
                    //       ref.read(manualSeverityProvider.notifier).state =
                    //           Severity.major;
                    //     } else if (aiResult.contains("Peringatan")) {
                    //       ref.read(manualSeverityProvider.notifier).state =
                    //           Severity.minor;
                    //     } else if (aiResult.contains("Baik")) {
                    //       ref.read(manualSeverityProvider.notifier).state =
                    //           Severity.good;
                    //     }
                    //   }
                    // }
                  },
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
            // if (isOverride) ...[
            //   const Divider(height: 32),
            //   _buildManualField(
            //     "Manual Object Detected",
            //     "e.g. Grain Spill",
            //     Icons.edit_note,
            //     _manualObjController,
            //   ),
            //   const SizedBox(height: 16),
            //   _buildManualField(
            //     "Manual Category",
            //     "e.g. CLEAN",
            //     Icons.cleaning_services,
            //     _manualCatController,
            //   ),
            //   const SizedBox(height: 24),
            //   const Text(
            //     "Field Manual Description",
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Colors.grey,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //   const SizedBox(height: 8),
            //   TextField(
            //     controller: _manualNoteController,
            //     maxLines: 2,
            //     decoration: InputDecoration(
            //       hintText: "Add details...",
            //       filled: true,
            //       fillColor: const Color(0xFFF9FAFB),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //   ),
            //   const SizedBox(height: 24),
            //   const Text(
            //     "Field Manual Recommendation",
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Colors.grey,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //   const SizedBox(height: 8),
            //   TextField(
            //     controller: _manualRecController,
            //     maxLines: 2,
            //     decoration: InputDecoration(
            //       hintText: "Add details...",
            //       filled: true,
            //       fillColor: const Color(0xFFF9FAFB),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  // Widget _buildManualField(
  //   String label,
  //   String hint,
  //   IconData icon,
  //   TextEditingController controller,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 12,
  //           fontWeight: FontWeight.bold,
  //           color: _textSecondary,
  //         ),
  //       ),
  //       const SizedBox(height: 6),
  //       TextField(
  //         controller: controller,
  //         decoration: InputDecoration(
  //           prefixIcon: Icon(icon, size: 20, color: _accentYellow),
  //           hintText: hint,
  //           filled: true,
  //           fillColor: const Color(0xFFF3F4F6),
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: BorderSide.none,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSubmitButton({
    required bool isEnabled,
    required VoidCallback? onPressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? _accentYellow : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          l10n.submit,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// saya ingin bisa mengedit Objek Terdeteksi, Kategori, Lokasi GPS, Deskripsi, Rekomendasi, dan Severity jika toggle switch on, namun ketika klik on pada switch berikan editDialog :
