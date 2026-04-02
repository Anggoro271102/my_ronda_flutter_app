import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/localizations/app_localizations.dart';
import '../../../../theme.dart';
// Import filter_provider kamu
import '../../../inspeksi/entities/inspection_report.dart';
import '../../../list_inspeksi/presentation/provider/filter_provider.dart';
import '../provider/report_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF212121);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _accentYellow = Color(0xFFFDD835);

  void _navigateToFilteredList({
    required WidgetRef ref,
    required BuildContext context,
    bool? status,
    Severity? severity,
  }) {
    // 1. Terapkan filter ke provider global
    // Filter Plant tidak perlu di-set lagi karena sudah otomatis sinkron dari dropdown
    ref.read(selectedStatusFilterProvider.notifier).state = status;
    ref.read(selectedSeverityFilterProvider.notifier).state = severity;

    // Pindahkan Tab (Misal List ada di index 1)
    // Ini akan memicu MainScreen untuk mengganti body tanpa menghilangkan Navbar
    ref.read(navIndexProvider.notifier).state = 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil pilihan plant dari state global (sama dengan yang dipakai di List)
    final selectedPlant = ref.watch(plantFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    // 2. Pantau data dashboard berdasarkan plant yang dipilih
    final dashboardAsync = ref.watch(dashboardStatsProvider(selectedPlant));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: RiveAppTheme.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: RefreshIndicator(
          onRefresh:
              () => ref.refresh(dashboardStatsProvider(selectedPlant).future),
          child: dashboardAsync.when(
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: _accentYellow),
                ),
            error:
                (err, stack) => Center(child: Text("Gagal memuat data: $err")),
            data:
                (data) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Center(
                        child: Text(
                          l10n.dashboard,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- SECTION NEW: PLANT FILTER ---
                      _buildPlantFilter(ref, context),

                      const SizedBox(height: 24),

                      // SECTION 1: Status Utama
                      Text(
                        l10n.inspectionProgress,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusCard(
                              context,
                              ref,
                              l10n.complete,
                              "${data.complete}",
                              Colors.green,
                              true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              context,
                              ref,
                              l10n.incomplete,
                              "${data.incomplete}",
                              Colors.orange,
                              false,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // SECTION 2: Severity Status
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSeverityCard(
                              context,
                              ref,
                              "Good",
                              "${data.good}",
                              Colors.blue,
                              Severity.good,
                            ),
                            _buildSeverityCard(
                              context,
                              ref,
                              "Minor",
                              "${data.warning}",
                              Colors.amber[700]!,
                              Severity.minor,
                            ),
                            _buildSeverityCard(
                              context,
                              ref,
                              "Major",
                              "${data.critical}",
                              Colors.red,
                              Severity.major,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // SECTION 3: Pie Chart
                      _buildChartSection(
                        l10n.completionRate,
                        _buildPieChart(data),
                      ),

                      const SizedBox(height: 32),

                      // SECTION 4: Bar Chart
                      _buildChartSection(
                        l10n.issuesBySeverity,
                        _buildBarChart(data),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET FILTER PLANT ---
  Widget _buildPlantFilter(WidgetRef ref, BuildContext context) {
    final plantsAsync = ref.watch(plantsMasterProvider);
    final selectedPlant = ref.watch(plantFilterProvider);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentYellow.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.plantLocation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          plantsAsync.when(
            data:
                (list) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF8FAFC,
                    ), // Warna background abu-abu sangat muda
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPlant,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      style: const TextStyle(
                        fontSize: 15,
                        color: _textPrimary,
                        fontWeight: FontWeight.w500,
                        fontFamily:
                            'Poppins', // Jika Anda menggunakan font kustom
                      ),
                      items:
                          list
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null)
                          ref.read(plantFilterProvider.notifier).state = val;
                      },
                    ),
                  ),
                ),
            loading:
                () => const LinearProgressIndicator(
                  backgroundColor: Color(0xFFF1F5F9),
                  color: _accentYellow,
                ),
            error:
                (_, __) => const Text(
                  "Gagal memuat lokasi", 
                  style: TextStyle(color: Colors.red),
                ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS (Method Card & Chart tetap sama seperti sebelumnya) ---
  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    Color color,
    bool statusValue,
  ) {
    return GestureDetector(
      onTap:
          () => _navigateToFilteredList(
            ref: ref,
            context: context,
            status: statusValue, // true untuk Complete, false untuk Incomplete
          ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCard(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    Color color,
    Severity severityValue,
  ) {
    return GestureDetector(
      onTap:
          () => _navigateToFilteredList(
            ref: ref,
            context: context,
            severity: severityValue,
          ),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 260,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: chart,
        ),
      ],
    );
  }

  // --- LOGIKA CHART (Pie & Bar) ---
  Widget _buildPieChart(DashboardData data) {
    double total = data.total.toDouble();
    if (total == 0) return const Center(child: Text("No Data Available"));
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: data.complete.toDouble(),
            title: '${((data.complete / total) * 100).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: data.incomplete.toDouble(),
            title: '${((data.incomplete / total) * 100).toStringAsFixed(0)}%',
            radius: 55,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(DashboardData data) {
    double maxVal =
        [
          data.good,
          data.warning,
          data.critical,
        ].reduce((a, b) => a > b ? a : b).toDouble();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 5,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                switch (value.toInt()) {
                  case 0:
                    return SideTitleWidget(
                      meta: meta,
                      child: const Text('Good', style: style),
                    );
                  case 1:
                    return SideTitleWidget(
                      meta: meta,
                      child: const Text('Minor', style: style),
                    );
                  case 2:
                    return SideTitleWidget(
                      meta: meta,
                      child: const Text('Major', style: style),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarData(0, data.good.toDouble(), Colors.blue, maxVal + 5),
          _makeBarData(
            1,
            data.warning.toDouble(),
            Colors.amber[700]!,
            maxVal + 5,
          ),
          _makeBarData(2, data.critical.toDouble(), Colors.red, maxVal + 5),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y, Color color, double backY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: backY,
            color: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}
