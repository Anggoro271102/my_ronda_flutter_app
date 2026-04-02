import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/my_list_inspeksi/presentation/provider/filter_provider.dart';
import 'package:intl/intl.dart';
import '../../../../theme.dart';

import '../../../auth/presentation/provider/user_provider.dart';
import '../../../detail/presentation/screen/report_detail_screen.dart';
import '../../../inspeksi/entities/inspection_report.dart';

enum SearchType { id, area }

final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.area);
final isFilterExpandedProvider = StateProvider<bool>((ref) => false);

class MyReportListScreen extends ConsumerWidget {
  const MyReportListScreen({super.key});

  static const Color _scaffoldBg = Color(0xFFF5F7FA);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF212121);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _accentYellow = Color(0xFFFDD835);

  void _resetAllFilters(WidgetRef ref) {
    // 1. Reset Status Filter
    ref.read(selectedStatusFilterProvider.notifier).state = null;

    // 2. PERBAIKAN DI SINI: Pastikan namanya 'selectedSeverityFilterProvider'
    // (Tambahkan kata 'Filter' jika tadi terlewat)
    ref.read(selectedSeverityFilterProvider.notifier).state = null;

    // 3. Reset Search jika ada
    ref.read(searchQueryProvider.notifier).state = "";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);
    // Cegah eksekusi jika user belum terdeteksi (masih null)
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final reportsAsync = ref.watch(filteredReportsProvider(currentUser.userId));
    final isExpanded = ref.watch(isFilterExpandedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: RiveAppTheme.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Center(child: _buildHeader()),

              // --- 1. SEARCH BAR SECTION ---
              _buildSearchBar(ref),

              const SizedBox(height: 12),

              // --- 2. EXPANDABLE FILTER SECTION ---
              _buildFilterTrigger(ref, isExpanded),

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child:
                    isExpanded
                        ? _buildExpandedFilters(ref)
                        : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // LAZY LIST VIEW
              Expanded(
                child: RefreshIndicator(
                  // PERBAIKAN: Gunakan sintaksis fungsi anonim yang benar
                  onRefresh: () async {
                    // Refresh provider mentah berdasarkan userId yang sedang login
                    // ignore: unused_result
                    await ref.refresh(
                      reportsRawProvider(currentUser.userId).future,
                    );
                  },
                  color: _accentYellow,
                  child: reportsAsync.when(
                    loading:
                        () => const Center(
                          child: CircularProgressIndicator(
                            color: _accentYellow,
                          ),
                        ),
                    error:
                        (err, stack) => _buildErrorState(err.toString(), ref),
                    data:
                        (reports) =>
                            reports.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                  // Physics ditambahkan agar RefreshIndicator selalu bisa ditarik
                                  // meskipun list-nya sedikit/kosong.
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: reports.length,
                                  itemBuilder: (context, index) {
                                    return _buildReportCard(
                                      context,
                                      reports[index],
                                    );
                                  },
                                ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Gagal Memuat Data",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(reportsRawProvider(null)),
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET SEARCH BAR DENGAN TOGGLE ID/AREA ---
  Widget _buildSearchBar(WidgetRef ref) {
    final searchType = ref.watch(searchTypeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                onChanged:
                    (v) => ref.read(searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText:
                      searchType == SearchType.id
                          ? "Search by ID..."
                          : "Search by Area...",
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildToggleBtn(
                  ref,
                  "ID",
                  searchType == SearchType.id,
                  SearchType.id,
                ),
                _buildToggleBtn(
                  ref,
                  "Area",
                  searchType == SearchType.area,
                  SearchType.area,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
    WidgetRef ref,
    String label,
    bool isActive,
    SearchType type,
  ) {
    return GestureDetector(
      onTap: () => ref.read(searchTypeProvider.notifier).state = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _accentYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- WIDGET FILTER TRIGGER ---
  Widget _buildFilterTrigger(WidgetRef ref, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap:
            () =>
                ref.read(isFilterExpandedProvider.notifier).state = !isExpanded,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isExpanded ? _accentYellow : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: isExpanded ? Colors.black : Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text(
                "Advanced Filters",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET FILTER YANG DI-EXPAND ---
  Widget _buildExpandedFilters(WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER FILTER (Judul & Reset Button) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter Options",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                onPressed: () => _resetAllFilters(ref),
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  "Reset",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _filterLabel("Status"),
          Row(
            children: [
              _statusFilterBtn(ref, "Incomplete", false),
              const SizedBox(width: 8),
              _statusFilterBtn(ref, "Completed", true),
            ],
          ),
          const Divider(height: 32),
          _filterLabel("Plant Location"),
          _buildPlantSelector(),
          const Divider(height: 32),
          _filterLabel("Severity Level"),

          _buildSeveritySelector(ref),

          const SizedBox(height: 24),

          // --- BUTTON APPLY FILTER ---
          _buildApplyButton(ref),
        ],
      ),
    );
  }

  Widget _buildApplyButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // 1. Jalankan logika filtering (jika ada provider khusus)
          // 2. Tutup panel filter
          ref.read(isFilterExpandedProvider.notifier).state = false;
        },
        child: const Text(
          "APPLY FILTERS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _statusFilterBtn(WidgetRef ref, String label, bool statusValue) {
    final currentStatus = ref.watch(selectedStatusFilterProvider);
    final isActive = currentStatus == statusValue;
    final color = statusValue ? Colors.green : Colors.orange;

    return Expanded(
      child: InkWell(
        onTap: () {
          // Jika diklik lagi saat sudah aktif, maka reset ke null (All)
          ref.read(selectedStatusFilterProvider.notifier).state =
              isActive ? null : statusValue;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? color : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? color : _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
  );

  Widget _buildPlantSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: "All Plants",
          isExpanded: true,
          items:
              ["All Plants", "Plant A - Medan", "Plant B - Jakarta"]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
          onChanged: (v) {},
        ),
      ),
    );
  }

  Widget _buildSeveritySelector(WidgetRef ref) {
    final selectedSeverity = ref.watch(selectedSeverityFilterProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniSeverityBtn(
          ref,
          "Good",
          Colors.blue,
          Severity.good,
          selectedSeverity == Severity.good,
        ),
        _miniSeverityBtn(
          ref,
          "Warn",
          Colors.amber[700]!,
          Severity.minor,
          selectedSeverity == Severity.minor,
        ),
        _miniSeverityBtn(
          ref,
          "Crit",
          Colors.red,
          Severity.major,
          selectedSeverity == Severity.major,
        ),
      ],
    );
  }

  Widget _miniSeverityBtn(
    WidgetRef ref,
    String label,
    Color color,
    Severity value,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        ref.read(selectedSeverityFilterProvider.notifier).state =
            isActive ? null : value;
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // --- KODE ASLI TETAP DIBAWAH ---

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        "My Reports",
        style: TextStyle(
          color: _textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- SECTION: REPORT CARD (Lazy Item) ---
  Widget _buildReportCard(BuildContext context, InspectionReport report) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ReportDetailScreen(report: report, canEdit: true),
            ),
          ),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: report.severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: report.severityColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.areaName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd MMM yyyy • HH:mm',
                            ).format(report.timestamp),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Color(0xFFF5F7FA)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniInfo("ID", "#${report.id}"),
                    _buildMiniInfo(
                      "FINAL SEVERITY",
                      report.finalSeverity.name.toUpperCase(),
                      isBold: true,
                      color: report.severityColor,
                    ),
                    _buildMiniInfo(
                      "CATEGORY",
                      report.category.name.toUpperCase(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // POJOK KANAN ATAS: Status & Override Indicator
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                _buildStatusBadge(report.isComplete),
                const SizedBox(width: 8),
                _buildOverrideIndicator(report.override),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper baru untuk indikator Override/AI agar kode lebih bersih
  Widget _buildOverrideIndicator(bool isOverride) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isOverride
                ? Colors.amber.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isOverride ? Icons.person_2_rounded : Icons.auto_awesome_rounded,
        size: 16,
        color: isOverride ? Colors.amber[800] : Colors.blue[600],
      ),
    );
  }
  // Widget _buildReportCard(BuildContext context, InspectionReport report) {
  //   return GestureDetector(
  //     onTap: () {
  //       // Navigasi ke halaman detail saat kartu di-klik
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ReportDetailScreen(report: report),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 16),
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: _cardBg,
  //         borderRadius: BorderRadius.circular(24),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.04),
  //             blurRadius: 10,
  //             offset: const Offset(0, 4),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         children: [
  //           Row(
  //             children: [
  //               Container(
  //                 width: 50,
  //                 height: 50,
  //                 decoration: BoxDecoration(
  //                   color: report.severityColor.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Icon(
  //                   Icons.inventory_2_outlined,
  //                   color: report.severityColor,
  //                 ),
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       report.areaName,
  //                       style: const TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 16,
  //                       ),
  //                     ),
  //                     Text(
  //                       DateFormat(
  //                         'dd MMM yyyy • HH:mm',
  //                       ).format(report.timestamp),
  //                       style: const TextStyle(
  //                         color: Colors.grey,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               _buildStatusBadge(report.description.isNotEmpty),
  //             ],
  //           ),
  //           const Divider(height: 32, color: Color(0xFFF5F7FA)),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               _buildMiniInfo("ID", report.id),
  //               _buildMiniInfo(
  //                 "AI Severity",
  //                 report.aiSeverity.name.toUpperCase(),
  //               ),
  //               _buildMiniInfo(
  //                 "Final",
  //                 report.finalSeverity.name.toUpperCase(),
  //                 isBold: true,
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatusBadge(bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isComplete
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isComplete ? "COMPLETE" : "INCOMPLETE",
        style: TextStyle(
          color: isComplete ? Colors.green[700] : Colors.orange[800],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMiniInfo(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text("No reports found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
