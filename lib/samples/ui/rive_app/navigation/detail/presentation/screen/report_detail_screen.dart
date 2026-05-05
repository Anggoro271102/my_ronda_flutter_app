import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/localizations/app_localizations.dart';
import '../../../../theme.dart';
import '../../../auth/presentation/provider/user_provider.dart';
import '../../../inspeksi/entities/inspection_report.dart';
import '../../../inspeksi/presentation/provider/inspection_provider.dart';
import '../../../list_inspeksi/presentation/provider/filter_provider.dart';
import '../provider/report_detail_service.dart';
import 'full_screen_image.dart';

// ==============
// Providers lokal screen
// ==============
final completionNoteControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);

final completionImageProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final isCompletingProvider = StateProvider.autoDispose<bool>((ref) => false);

// edit mode
final isEditModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final editSeverityProvider = StateProvider.autoDispose<Severity?>(
  (ref) => null,
);
final editImageProvider = StateProvider.autoDispose<String?>((ref) => null);

final editDescControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);

final categoryControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);
final gpsControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);
final objectControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);

final editRecControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);

final areaControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);

// Provider baru khusus untuk mengontrol mode edit pada form penyelesaian
final isCompletionEditModeProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class ReportDetailScreen extends ConsumerWidget {
  final InspectionReport report;
  final bool canEdit;

  const ReportDetailScreen({
    super.key,
    required this.report,
    this.canEdit = false,
  });

  Future<void> _analyzeCompletionImage(WidgetRef ref, String imagePath) async {
    ref.read(isAiCompletionLoadingProvider.notifier).state = true;
    try {
      // Gunakan notifier dari inspectionStateProvider untuk pinjam fungsi polling AI
      // Atau buat fungsi polling serupa di sini.
      // Kita asumsikan menggunakan logic polling yang sudah ada:
      final aiData = await ref
          .read(inspectionStateProvider.notifier)
          .uploadAndPollAI(imagePath);

      final aiDescription = aiData['description'];
      ref.read(aiCompletionAnalysisProvider.notifier).state = aiDescription;

      // Default: Jika tidak edit mode, isi manual controller dengan hasil AI juga
      if (!ref.read(isEditModeProvider)) {
        ref.read(completionNoteControllerProvider).text = aiDescription ?? "";
      }
    } catch (e) {
      debugPrint("AI Completion Analysis Error: $e");
    } finally {
      ref.read(isAiCompletionLoadingProvider.notifier).state = false;
    }
  }

  static const Color _textPrimary = Color(0xFF212121);
  static const Color _accentYellow = Color(0xFFFDD835);
  static const Color _scaffoldBg = Color(0xFFF1F5F9);
  static const Color _sectionBg = Colors.white;
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(report.id) ?? 0;
    final detailAsync = ref.watch(reportDetailProvider(id));

    return detailAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (detailReport) {
        return _buildUI(context, ref, detailReport);
      },
    );
  }

  // ===========================
  // UI ROOT
  // ===========================
  Widget _buildUI(
    BuildContext context,
    WidgetRef ref,
    InspectionReport detailReport,
  ) {
    final isEditMode = ref.watch(isEditModeProvider);
    final isExpanded = ref.watch(isCompletingProvider);
    final isIncomplete = detailReport.isComplete == false;
    final activeSeverity =
        ref.watch(editSeverityProvider) ?? detailReport.finalSeverity;
    final activeImagePath =
        ref.watch(editImageProvider) ?? detailReport.imagePath;

    // controllers init (sekali)
    final catCtrl = ref.watch(categoryControllerProvider);
    final descCtrl = ref.watch(editDescControllerProvider);
    // final gpsCtrl = ref.watch(gpsControllerProvider);
    final objCtrl = ref.watch(objectControllerProvider);
    final recCtrl = ref.watch(editRecControllerProvider);
    final areaCtrl = ref.watch(areaControllerProvider);

    if (catCtrl.text.isEmpty) catCtrl.text = detailReport.category.displayName;
    if (descCtrl.text.isEmpty) descCtrl.text = detailReport.description;
    if (objCtrl.text.isEmpty) {
      objCtrl.text = detailReport.objectDetected; // contoh
    }
    if (recCtrl.text.isEmpty) {
      recCtrl.text = detailReport.recommendation ?? '';
    }
    if (areaCtrl.text.isEmpty) areaCtrl.text = detailReport.areaName;

    Color severityDisplayColor;
    switch (activeSeverity) {
      case Severity.good:
        severityDisplayColor = Colors.blue;
        break;
      case Severity.minor:
        severityDisplayColor = Colors.amber[700]!;
        break;
      case Severity.major:
        severityDisplayColor = Colors.red;
        break;
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: RiveAppTheme.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(
                context,
                ref,
                isEditMode,
                isIncomplete,
                detailReport,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(
                        context,
                        ref,
                        isEditMode,
                        activeImagePath,
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _sectionBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildEditableRow(
                              ref,
                              l10n.objectDetected,
                              Icons.grain,
                              objCtrl,
                              isEditMode,
                            ),
                            const Divider(height: 24),

                            _buildEditableRow(
                              ref,
                              l10n.category,
                              Icons.cleaning_services,
                              catCtrl,
                              isEditMode,
                              color: Colors.red,
                            ),
                            const Divider(height: 24),

                            _buildEditableRow(
                              ref,
                              l10n.gpsLocation,
                              Icons.location_on,
                              areaCtrl,
                              isEditMode,
                              color: Colors.blue,
                            ),
                            const Divider(height: 24),

                            _buildResultRow(
                              l10n.severity,
                              activeSeverity.name.toUpperCase(),
                              Icons.warning_amber_rounded,
                              valueColor: severityDisplayColor,
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildAISeverityCard(
                                  label: "Good",
                                  color: Colors.blue,
                                  isSelected: activeSeverity == Severity.good,
                                  onTap:
                                      isEditMode
                                          ? () =>
                                              ref
                                                  .read(
                                                    editSeverityProvider
                                                        .notifier,
                                                  )
                                                  .state = Severity.good
                                          : null,
                                ),
                                _buildAISeverityCard(
                                  label: "Minor",
                                  color: Colors.amber[700]!,
                                  isSelected: activeSeverity == Severity.minor,
                                  onTap:
                                      isEditMode
                                          ? () =>
                                              ref
                                                  .read(
                                                    editSeverityProvider
                                                        .notifier,
                                                  )
                                                  .state = Severity.minor
                                          : null,
                                ),
                                _buildAISeverityCard(
                                  label: "Major",
                                  color: Colors.red,
                                  isSelected: activeSeverity == Severity.major,
                                  onTap:
                                      isEditMode
                                          ? () =>
                                              ref
                                                  .read(
                                                    editSeverityProvider
                                                        .notifier,
                                                  )
                                                  .state = Severity.major
                                          : null,
                                ),
                              ],
                            ),

                            const Divider(height: 32),

                            _buildDescriptionEditSection(
                              isEditMode,
                              descCtrl,
                              context,
                            ),
                            const Divider(height: 32),

                            _buildRecommendationEditSection(
                              isEditMode,
                              recCtrl,
                              context,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (isIncomplete) ...[
                        _buildMainActionButton(
                          context,
                          ref,
                          isEditMode,
                          isExpanded,
                          detailReport,
                        ),

                        const SizedBox(height: 16),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child:
                              (!isEditMode && isExpanded)
                                  ? _buildCompletionForm(
                                    context,
                                    ref,
                                    detailReport,
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ] else ...[
                        _buildCompletionSummary(ref, detailReport, context),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================
  // APP BAR
  // ===========================
  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    bool isEditMode,
    bool isIncomplete,
    InspectionReport detailReport,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: _textPrimary,
              size: 20,
            ),
          ),
          const Text(
            "Detail Laporan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          // edit icon hanya muncul jika:
          // - canEdit true (MyReportListScreen)
          // - report belum complete
          // - belum masuk edit mode
          if (canEdit && isIncomplete && !isEditMode)
            IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: _accentYellow,
                size: 28,
              ),
              onPressed: () => _showEditDialog(context, ref),
            ),

          if (!isEditMode) _buildStatusBadge(detailReport.isResolved, context),
        ],
      ),
    );
  }

  // ===========================
  // IMAGE SECTION
  // ===========================
  Widget _buildImageSection(
    BuildContext context,
    WidgetRef ref,
    bool isEditMode,
    String? path,
  ) {
    const String baseUrl = "https://track.cpipga.com";
    ImageProvider imageProvider;

    if (path == null || path.isEmpty) {
      imageProvider = const AssetImage("assets/images/placeholder.png");
    } else if (path.startsWith('http')) {
      imageProvider = NetworkImage(path);
    } else if (path.startsWith('/static')) {
      imageProvider = NetworkImage("$baseUrl$path");
    } else if (path.contains('.') && !path.startsWith('/')) {
      imageProvider = NetworkImage("$baseUrl/static/$path");
    } else {
      imageProvider = FileImage(File(path));
    }

    final heroTag = 'report_image_zoom_${report.id}';

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (path == null || path.isEmpty) return;

            String finalPath = path;

            // resolve url untuk viewer
            if (path.startsWith('/static')) {
              finalPath = "$baseUrl$path";
            } else if (path.contains('.') &&
                !path.startsWith('/') &&
                !path.startsWith('http')) {
              finalPath = "$baseUrl/static/$path";
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => FullScreenImageViewer(
                      imagePath: finalPath,
                      heroTag: heroTag, // ✅ tag sama
                    ),
              ),
            );
          },
          child: Hero(
            tag: heroTag, // ✅ tag sama
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
          ),
        ),

        if (isEditMode)
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              backgroundColor: _accentYellow,
              onPressed: () => _pickEditImage(ref),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================
  // MAIN ACTION BUTTON
  // ===========================
  Widget _buildRecommendationEditSection(
    bool isEditMode,
    TextEditingController controller,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              l10n.recommendation,
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
          padding: isEditMode ? EdgeInsets.zero : const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              isEditMode
                  ? TextField(
                    controller: controller,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(14),
                      hintText: l10n.editRecommendation,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentYellow),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _accentYellow,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                  : Text(
                    controller.text.isEmpty ? "-" : controller.text,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(
    BuildContext context,
    WidgetRef ref,
    bool isEditMode,
    bool isExpanded,
    InspectionReport detailReport,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (isEditMode) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _submitEditChanges(context, ref, detailReport),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(l10n.submitChanges),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      );
    }

    // non-edit mode -> tombol complete trigger
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            () => ref.read(isCompletingProvider.notifier).state = !isExpanded,
        icon: Icon(isExpanded ? Icons.close : Icons.task_alt),
        label: Text(isExpanded ? l10n.cancel : l10n.completeReport),
        style: ElevatedButton.styleFrom(
          backgroundColor: isExpanded ? Colors.grey[200] : _accentYellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ===========================
  // EDIT / COMPLETE HANDLERS
  // ===========================
  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text("Mode Edit"),
            content: const Text(
              "Anda akan mengubah detail laporan ini. Lanjutkan?",
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text("Lanjutkan"),
                onPressed: () {
                  ref.read(isEditModeProvider.notifier).state = true;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _pickEditImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (image != null) {
      ref.read(editImageProvider.notifier).state = image.path;
    }
  }

  Future<void> _pickCompletionImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (image != null) {
      ref.read(completionImageProvider.notifier).state = image.path;

      // WAJIB: Panggil fungsi analisis agar aiCompletionAnalysisProvider terisi
      await _analyzeCompletionImage(ref, image.path);
    }
  }

  Future<void> _submitEditChanges(
    BuildContext context,
    WidgetRef ref,
    InspectionReport detailReport,
  ) async {
    final service = ref.read(detailServiceProvider);
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    final selectedSeverity = ref.read(editSeverityProvider);
    final severityToSend =
        (selectedSeverity ?? detailReport.finalSeverity).name;

    final categoryToSend =
        ref.read(categoryControllerProvider).text.trim().toLowerCase();
    final descToSend = ref.read(editDescControllerProvider).text.trim();

    final newImagePath = ref.read(editImageProvider);
    final safeNewImagePath =
        (newImagePath != null && newImagePath.isNotEmpty) ? newImagePath : null;
    final recToSend = ref.read(editRecControllerProvider).text.trim();

    try {
      await service.editReport(
        reportId: int.parse(detailReport.id),
        userId: currentUser.userId,
        severity: severityToSend,
        category: categoryToSend,
        description: descToSend,
        newImagePath: safeNewImagePath,
        recommendation: recToSend,
      );

      ref.read(isEditModeProvider.notifier).state = false;

      // refresh detail setelah edit
      ref.invalidate(reportDetailProvider(int.parse(detailReport.id)));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil diperbarui")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Edit: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitCompletion(
    BuildContext context,
    WidgetRef ref,
    InspectionReport detailReport,
  ) async {
    final aiNote = ref.read(aiCompletionAnalysisProvider);
    final isEditModeCompletion = ref.read(isCompletionEditModeProvider);
    final manualNote = ref.read(completionNoteControllerProvider).text.trim();
    final service = ref.read(detailServiceProvider);
    final currentUser = ref.read(userProvider);
    final imagePath = ref.read(completionImageProvider);

    if (currentUser == null || imagePath == null) return;

    // Tentukan apa yang dikirim ke API berdasarkan logika yang Anda minta
    String noteToSend;
    String? noteAiToSend;

    if (isEditModeCompletion) {
      noteToSend = manualNote; // Note manual dari user
      noteAiToSend = aiNote; // Hasil AI disimpan di note_ai
    } else {
      noteToSend = aiNote ?? ""; // Duplikat: AI masuk ke note
      noteAiToSend = aiNote; // Duplikat: AI masuk ke note_ai
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await service.completeReport(
        reportId: int.parse(detailReport.id),
        userId: currentUser.userId,
        note: noteToSend, // Gunakan variabel hasil logika di atas
        noteAi: noteAiToSend, // Gunakan variabel hasil logika di atas
        imagePath: imagePath,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // 1. Tutup dialog loading segera

      // 2. KUNCI UTAMA: Invalidate provider dengan parameter yang TEPAT.
      // Karena di ReportListScreen Anda menggunakan null, maka di sini harus null.
      ref.invalidate(reportsRawProvider(null));

      // 3. Tambahkan sedikit delay atau paksa refresh filtered provider
      // Ini memastikan filtered provider 'sadar' bahwa Raw data-nya sudah mati (invalid).
      await ref.read(filteredReportsProvider(null).future);

      // 4. Update detail screen agar jika user masuk lagi, datanya sudah complete
      final idInt = int.parse(detailReport.id);
      ref.invalidate(reportDetailProvider(idInt));
      ref.invalidate(reportCompletionProvider(idInt));

      // 5. Beri feedback ke user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Laporan berhasil diselesaikan!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 6. Kembali ke list screen
      Navigator.pop(context);
      debugPrint("SAMPAI DISINI");
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal Menyelesaikan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===========================
  // COMPLETION FORM
  // ===========================
  Widget _buildCompletionForm(
    BuildContext context,
    WidgetRef ref,
    InspectionReport detailReport,
  ) {
    final isAiLoading = ref.watch(isAiCompletionLoadingProvider);
    final isEditModeComp = ref.watch(isCompletionEditModeProvider);
    final aiNote = ref.watch(aiCompletionAnalysisProvider);
    final noteCtrl = ref.watch(completionNoteControllerProvider);
    final proofPath = ref.watch(completionImageProvider);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFDD835).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Evidence Upload",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // --- 1. PICKER AREA ---
          GestureDetector(
            onTap: () => _pickCompletionImage(ref),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      proofPath == null
                          ? Icons.add_a_photo_outlined
                          : Icons.check_circle,
                      color: proofPath == null ? Colors.grey : Colors.green,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      proofPath == null
                          ? "Upload Proof of Fix"
                          : "Photo selected",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (proofPath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(proofPath),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          // --- 2. AI LOADING STATE ---
          if (isAiLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.aiAnalysisResultHint,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- 3. DESCRIPTION AREA (Muncul setelah foto dipilih / AI selesai) ---
          if (proofPath != null && !isAiLoading) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.actionDescription,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // SWITCH HANYA MUNCUL JIKA AI SUDAH MEMBERIKAN HASIL
                if (aiNote != null)
                  Row(
                    children: [
                      Text(
                        l10n.editManual,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Switch(
                        value: isEditModeComp,
                        activeColor: Colors.green,
                        onChanged: (v) {
                          if (v) {
                            _showEditCompletionDialog(context, ref);
                          } else {
                            ref
                                .read(isCompletionEditModeProvider.notifier)
                                .state = false;
                            noteCtrl.text = aiNote;
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              readOnly: !isEditModeComp && aiNote != null,
              decoration: InputDecoration(
                hintText:
                    isEditModeComp
                        ? l10n.typeManualHint
                        : l10n.aiAnalysisResultHint,
                fillColor:
                    (isEditModeComp || aiNote == null)
                        ? Colors.white
                        : Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isEditModeComp ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // --- 4. SUBMIT BUTTON ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (proofPath != null && !isAiLoading)
                      ? () => _submitCompletion(context, ref, detailReport)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.submitCompletion,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  } // ===========================

  // COMPLETION SUMMARY (fetch via API)
  // ===========================
  void _showEditCompletionDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text(l10n.editAiDescriptionTitle),
            content: Text(l10n.editAiDescriptionDialog),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(l10n.yesEdit),
                onPressed: () {
                  ref.read(isCompletionEditModeProvider.notifier).state = true;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  Widget _buildCompletionSummary(
    WidgetRef ref,
    InspectionReport detailReport,
    BuildContext context,
  ) {
    final id = int.tryParse(detailReport.id) ?? 0;
    final completionAsync = ref.watch(reportCompletionProvider(id));
    final l10n = AppLocalizations.of(context)!;
    return completionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _completionErrorBox("${l10n.errorLoadCompletion}: $e"),
      data: (c) {
        final timeText =
            (c.createdAt != null)
                ? DateFormat(
                  "dd MMM yyyy, HH:mm",
                ).format(c.createdAt!.toLocal())
                : "-";

        // jika actionImageUrl tidak dikirim, fallback placeholder
        final imageWidget =
            (c.remediationImage != null && c.remediationImage!.isNotEmpty)
                ? _netImageBox(c.remediationImage!)
                : _placeholderImageBox();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.completionSummary,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.green,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // proof image
              imageWidget,
              const SizedBox(height: 16),

              Text(
                l10n.actionNote,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                // ✅ FIX NOTE: Gunakan field remediationNote dari API
                (c.remediationNote != null && c.remediationNote!.isNotEmpty)
                    ? c.remediationNote!
                    : "-",
                style: const TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const Divider(height: 32),

              _infoRow(
                l10n.resolvedBy,
                (c.resolverName?.isNotEmpty ?? false) ? c.resolverName! : "-",
                Icons.person_pin_circle_outlined,
              ),
              const SizedBox(height: 8),
              _infoRow(l10n.resolutionTime, timeText, Icons.access_time),
            ],
          ),
        );
      },
    );
  }

  Widget _completionErrorBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _netImageBox(String path) {
    // 1. Tentukan Base URL server kamu
    const String baseUrl = "https://track.cpipga.com";
    String finalUrl = "";

    // DEBUG: Cek apa yang diterima dari API (imageUrl asli)
    debugPrint("🔍 [NET IMAGE DEBUG] Input Path dari API: '$path'");

    // 2. Logika penyusunan URL yang cerdas
    if (path.startsWith('http')) {
      debugPrint(
        "🚀 [NET IMAGE LOGIC] Terdeteksi sebagai URL Lengkap (starts with http)",
      );
      finalUrl = path;
    } else if (path.startsWith('/')) {
      debugPrint(
        "🛠️ [NET IMAGE LOGIC] Terdeteksi sebagai Path Absolut (starts with /)",
      );
      // Kita langsung gabungkan: https://track.cpipga.com + /static/uploads/...
      finalUrl = "$baseUrl$path";
    } else {
      debugPrint(
        "📦 [NET IMAGE LOGIC] Terdeteksi sebagai Path Relatif (filename only)",
      );
      // Jika path hanya nama file saja (misal: gambar.jpg)
      finalUrl = "$baseUrl/static/$path";
    }

    // DEBUG: Hasil akhir setelah digabung dengan BaseUrl
    debugPrint("🔗 [NET IMAGE DEBUG] URL Akhir yang diakses: $finalUrl");

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        finalUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        // Handler jika gambar gagal dimuat
        errorBuilder: (context, error, stackTrace) {
          debugPrint("❌ [NET IMAGE ERROR] Gagal memuat gambar di: $finalUrl");
          debugPrint("Detail Error: $error");
          return _placeholderImageBox();
        },
        // Loading indicator
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: Colors.grey[100],
            child: const Center(child: CupertinoActivityIndicator()),
          );
        },
      ),
    );
  }

  Widget _placeholderImageBox() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage("assets/images/placeholder_complete.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ===========================
  // HELPERS UI
  // ===========================
  Widget _buildEditableRow(
    WidgetRef ref,
    String label,
    IconData icon,
    TextEditingController controller,
    bool isEditMode, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Menjaga agar label dan icon di atas
      children: [
        Icon(icon, size: 20, color: const Color.fromARGB(255, 5, 4, 4)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(
          width: 16,
        ), // Memberikan jarak antara label dan input field
        isEditMode
            ? Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color ?? _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "...",
                ),
                maxLines: null, // Memungkinkan TextField membungkus teks
              ),
            )
            : Expanded(
              child: Text(
                controller.text,
                textAlign: TextAlign.end, // Menjaga teks rata kanan
                style: TextStyle(
                  color: color ?? _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                softWrap: true, // Membuat teks terbungkus jika panjang
                overflow:
                    TextOverflow.visible, // Teks tetap tampil meskipun panjang
              ),
            ),
      ],
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    IconData icon, {
    Color valueColor = _textPrimary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionEditSection(
    bool isEditMode,
    TextEditingController controller,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.descriptionTitle,
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
          padding: isEditMode ? EdgeInsets.zero : const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              isEditMode
                  ? TextField(
                    controller: controller,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(14),
                      hintText: l10n.editDescriptionHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentYellow),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _accentYellow,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                  : Text(
                    controller.text,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : Colors.grey[300],
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF212121),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool complete, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            complete
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        complete ? l10n.complete : l10n.incomplete,
        style: TextStyle(
          color: complete ? Colors.green : Colors.orange[800],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
