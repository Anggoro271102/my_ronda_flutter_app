// ══════════════════════════════════════════════════════════════════════
// report_list_screen.dart
// lib/samples/ui/rive_app/navigation/list_inspeksi/presentation/screen/
// ══════════════════════════════════════════════════════════════════════
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../../core/localizations/app_localizations.dart';
import '../../../detail/presentation/provider/report_detail_service.dart';
import '../../../detail/presentation/screen/report_detail_screen.dart';
import '../../../inspeksi/entities/inspection_report.dart';
import '../provider/filter_provider.dart';

// ── Providers ──────────────────────────────────────────────────────
enum SearchType { content, object }

final searchTypeProvider = StateProvider<SearchType>(
  (ref) => SearchType.content,
);
final isFilterExpandedProvider = StateProvider<bool>((ref) => false);
final reportDetailProvider = FutureProvider.family<InspectionReport, int>((
  ref,
  id,
) async {
  final service = ref.read(detailServiceProvider);
  return service.getDetail(id);
});

// ══════════════════════════════════════════════════════════════════════
// COLOR TOKENS  (shared palette)
// ══════════════════════════════════════════════════════════════════════
class _C {
  static const pageBg = Color(0xFFECEDF5);
  static const white = Color(0xFFFFFFFF);
  static const shadowDark = Color(0xFFB4B8CC);
  static const shadowLight = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7080);
  static const textMuted = Color(0xFF9CA3AF);

  static const blue = Color(0xFF2563EB);
  static const blueLight = Color(0xFFDBEAFE);
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const amber = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
  static const purple = Color(0xFF9333EA);
  static const purpleLight = Color(0xFFFAF5FF);
  static const teal = Color(0xFF0F766E);
}

List<BoxShadow> get _raised => [
  BoxShadow(
    color: _C.shadowDark.withOpacity(.42),
    offset: const Offset(4, 6),
    blurRadius: 14,
  ),
  BoxShadow(
    color: _C.shadowLight.withOpacity(.9),
    offset: const Offset(-2, -2),
    blurRadius: 6,
  ),
];

List<BoxShadow> get _card => [
  BoxShadow(
    color: _C.shadowDark.withOpacity(.22),
    offset: const Offset(4, 6),
    blurRadius: 16,
  ),
  BoxShadow(
    color: _C.shadowLight.withOpacity(.8),
    offset: const Offset(-1, -1),
    blurRadius: 4,
  ),
];

// ══════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════
class ReportListScreen extends ConsumerWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(filteredReportsProvider(null));
    final isFilterOpen = ref.watch(isFilterExpandedProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: _C.pageBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(l10n: l10n),
                _StatBar(reportsAsync: reportsAsync),
                _SearchRow(l10n: l10n),
                const _QuickTabs(),
                Expanded(
                  child: reportsAsync.when(
                    loading:
                        () => const Center(
                          child: CircularProgressIndicator(
                            color: _C.blue,
                            strokeWidth: 2,
                          ),
                        ),
                    error: (e, _) => _ErrorState(message: e.toString()),
                    data:
                        (reports) =>
                            reports.isEmpty
                                ? const _EmptyState()
                                : _ReportList(reports: reports, l10n: l10n),
                  ),
                ),
              ],
            ),
            if (isFilterOpen)
              _FilterOverlay(
                l10n: l10n,
                onClose:
                    () =>
                        ref.read(isFilterExpandedProvider.notifier).state =
                            false,
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TOP BAR
// ══════════════════════════════════════════════════════════════════════
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0, left: 45.0),
              child: Text(
                l10n.listReports.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                  letterSpacing: .6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// STAT BAR
// ══════════════════════════════════════════════════════════════════════
class _StatBar extends ConsumerWidget {
  const _StatBar({required this.reportsAsync});
  final AsyncValue<List<InspectionReport>> reportsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = reportsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const <InspectionReport>[],
    );
    final total = reports.length;
    final pending = reports.where((r) => !r.isComplete).length;
    final done = reports.where((r) => r.isComplete).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.description_outlined,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              value: '$total',
              label: 'Total',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.access_time_rounded,
              iconBg: _C.amberLight,
              iconColor: _C.amber,
              value: '$pending',
              label: 'Pending',
              valueColor: _C.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBg: _C.greenLight,
              iconColor: _C.green,
              value: '$done',
              label: 'Selesai',
              valueColor: _C.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor = _C.textPrimary,
  });
  final IconData icon;
  final Color iconBg, iconColor, valueColor;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _C.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SEARCH ROW
// ══════════════════════════════════════════════════════════════════════
class _SearchRow extends ConsumerWidget {
  const _SearchRow({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilter =
        ref.watch(selectedStatusFilterProvider) != null ||
        ref.watch(selectedSeverityFilterProvider) != null ||
        ref.watch(plantFilterProvider) != 'All Plants';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _C.pageBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _C.shadowDark.withOpacity(.38),
                    offset: const Offset(3, 3),
                    blurRadius: 7,
                    spreadRadius: -1,
                  ),
                  const BoxShadow(
                    color: _C.shadowLight,
                    offset: Offset(-2, -2),
                    blurRadius: 5,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: _C.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged:
                          (v) =>
                              ref.read(searchQueryProvider.notifier).state = v,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _C.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Cari nama area, ID laporan...',
                        hintStyle: TextStyle(fontSize: 13, color: _C.textMuted),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _NeuBtn(
                size: 44,
                radius: 14,
                onTap:
                    () =>
                        ref.read(isFilterExpandedProvider.notifier).state =
                            true,
                child: const Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: _C.textSecondary,
                ),
              ),
              if (hasFilter)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _C.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.pageBg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// QUICK TABS
// ══════════════════════════════════════════════════════════════════════
class _QuickTabs extends ConsumerWidget {
  const _QuickTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(selectedStatusFilterProvider);
    final severityFilter = ref.watch(selectedSeverityFilterProvider);

    String activeKey = 'all';
    if (statusFilter == true) activeKey = 'done';
    if (statusFilter == false) activeKey = 'pending';
    if (severityFilter == Severity.major) activeKey = 'major';
    if (severityFilter == Severity.minor) activeKey = 'minor';

    void tap(String key) {
      switch (key) {
        case 'all':
          ref.read(selectedStatusFilterProvider.notifier).state = null;
          ref.read(selectedSeverityFilterProvider.notifier).state = null;
          break;
        case 'done':
          ref.read(selectedStatusFilterProvider.notifier).state = true;
          ref.read(selectedSeverityFilterProvider.notifier).state = null;
          break;
        case 'pending':
          ref.read(selectedStatusFilterProvider.notifier).state = false;
          ref.read(selectedSeverityFilterProvider.notifier).state = null;
          break;
        case 'major':
          ref.read(selectedStatusFilterProvider.notifier).state = null;
          ref.read(selectedSeverityFilterProvider.notifier).state =
              Severity.major;
          break;
        case 'minor':
          ref.read(selectedStatusFilterProvider.notifier).state = null;
          ref.read(selectedSeverityFilterProvider.notifier).state =
              Severity.minor;
          break;
      }
    }

    const tabs = [
      ('all', 'Semua'),
      ('pending', 'Pending'),
      ('major', 'Major'),
      ('minor', 'Minor'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final key = tabs[i].$1;
          final label = tabs[i].$2;
          final isActive = activeKey == key;
          return GestureDetector(
            onTap: () => tap(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? _C.textPrimary : _C.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow:
                    isActive
                        ? [
                          BoxShadow(
                            color: _C.textPrimary.withOpacity(.28),
                            offset: const Offset(3, 4),
                            blurRadius: 10,
                          ),
                        ]
                        : _raised,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : _C.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// REPORT LIST + CARD
// ══════════════════════════════════════════════════════════════════════
class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, required this.l10n});
  final List<InspectionReport> reports;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LAPORAN TERBARU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _C.textMuted,
                    letterSpacing: .8,
                  ),
                ),
                Text(
                  '${reports.length} laporan',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _C.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportCard(
                  key: ValueKey('card_${reports[i].id}'),
                  report: reports[i],
                  l10n: l10n,
                ),
              ),
              childCount: reports.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({super.key, required this.report, required this.l10n});
  final InspectionReport report;
  final AppLocalizations l10n;

  Color get _accent {
    switch (report.finalSeverity) {
      case Severity.good:
        return _C.blue;
      case Severity.minor:
        return _C.amber;
      case Severity.major:
        return _C.red;
    }
  }

  Color get _bubbleBg {
    switch (report.finalSeverity) {
      case Severity.good:
        return _C.blueLight;
      case Severity.minor:
        return _C.amberLight;
      case Severity.major:
        return _C.redLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = report.isComplete;
    final isOverride = report.override;
    final timeStr = DateFormat(
      'dd MMM yyyy · HH:mm',
    ).format(report.timestamp.toLocal());

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ReportDetailScreen(report: report, canEdit: false),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              Container(width: 4, color: _accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _bubbleBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              report.severityIcon,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.areaName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Badge(
                                label: isComplete ? l10n.complete : 'Pending',
                                bg: isComplete ? _C.greenLight : _C.amberLight,
                                color: isComplete ? _C.green : _C.amber,
                              ),
                              const SizedBox(height: 4),
                              _Badge(
                                label: isOverride ? 'Override' : 'AI',
                                bg: isOverride ? _C.purpleLight : _C.blueLight,
                                color: isOverride ? _C.purple : _C.blue,
                                fontSize: 9,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MetaCol(label: 'ID', value: '#${report.id}'),
                          _MetaCol(
                            label: 'SEVERITY',
                            value: report.finalSeverity.name.toUpperCase(),
                            dotColor: _accent,
                          ),
                          _MetaCol(
                            label: 'KATEGORI',
                            value: report.category.displayName.toUpperCase(),
                          ),
                          const Spacer(),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _C.pageBg,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _raised,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: _C.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value, this.dotColor});
  final String label, value;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _C.textMuted,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.color,
    this.fontSize = 10.0,
  });
  final String label;
  final Color bg, color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// FILTER OVERLAY  — frosted glass bottom sheet
// ══════════════════════════════════════════════════════════════════════
class _FilterOverlay extends ConsumerWidget {
  const _FilterOverlay({required this.l10n, required this.onClose});
  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: _C.textPrimary.withOpacity(.18),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: _FilterSheet(l10n: l10n, onClose: onClose),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({required this.l10n, required this.onClose});
  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(selectedStatusFilterProvider);
    final severityFilter = ref.watch(selectedSeverityFilterProvider);

    void resetAll() {
      ref.read(selectedStatusFilterProvider.notifier).state = null;
      ref.read(selectedSeverityFilterProvider.notifier).state = null;
      ref.read(plantFilterProvider.notifier).state = 'All Plants';
      ref.read(categoryFilterProvider.notifier).state = 'All Categories';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF5F0F1FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        // <--- TAMBAHKAN INI DI SINI
        physics:
            const BouncingScrollPhysics(), // Opsional: Agar animasi scroll terasa lebih halus/memantul ala iOS
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 18),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8CADC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // header
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: _C.textPrimary),
                const SizedBox(width: 8),
                const Text(
                  'Opsi Filter',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: resetAll,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.blue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── STATUS ──
            const _FieldLabel('STATUS LAPORAN'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ToggleBtn(
                    label: 'Pending',
                    icon: Icons.access_time_rounded,
                    isOn: statusFilter == false,
                    onTap:
                        () =>
                            ref
                                .read(selectedStatusFilterProvider.notifier)
                                .state = statusFilter == false ? null : false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToggleBtn(
                    label: 'Selesai',
                    icon: Icons.check_circle_outline_rounded,
                    isOn: statusFilter == true,
                    onTap:
                        () =>
                            ref
                                .read(selectedStatusFilterProvider.notifier)
                                .state = statusFilter == true ? null : true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── LOKASI PLANT — animated expanded dropdown ──
            const _FieldLabel('LOKASI PLANT'),
            const SizedBox(height: 8),
            _ExpandedDropdown(
              icon: Icons.location_on_outlined,
              providerKey: 'plant',
              watchValue: (ref) => ref.watch(plantFilterProvider),
              watchItems: (ref) => ref.watch(plantsMasterProvider),
              onSelect:
                  (ref, v) => ref.read(plantFilterProvider.notifier).state = v,
            ),

            const SizedBox(height: 16),

            // ── KATEGORI — animated expanded dropdown ──
            const _FieldLabel('KATEGORI'),
            const SizedBox(height: 8),
            _ExpandedDropdown(
              icon: Icons.grid_view_rounded,
              providerKey: 'category',
              watchValue: (ref) => ref.watch(categoryFilterProvider),
              watchItems: (ref) => ref.watch(categoriesMasterProvider),
              onSelect:
                  (ref, v) =>
                      ref.read(categoryFilterProvider.notifier).state = v,
            ),

            const SizedBox(height: 16),

            // ── SEVERITY ──
            const _FieldLabel('TINGKAT SEVERITY'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SevChip(
                    label: 'Good',
                    activeColor: _C.blue,
                    isOn: severityFilter == Severity.good,
                    onTap:
                        () =>
                            ref
                                .read(selectedSeverityFilterProvider.notifier)
                                .state = severityFilter == Severity.good
                                    ? null
                                    : Severity.good,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SevChip(
                    label: 'Minor',
                    activeColor: _C.amber,
                    isOn: severityFilter == Severity.minor,
                    onTap:
                        () =>
                            ref
                                .read(selectedSeverityFilterProvider.notifier)
                                .state = severityFilter == Severity.minor
                                    ? null
                                    : Severity.minor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SevChip(
                    label: 'Major',
                    activeColor: _C.red,
                    isOn: severityFilter == Severity.major,
                    onTap:
                        () =>
                            ref
                                .read(selectedSeverityFilterProvider.notifier)
                                .state = severityFilter == Severity.major
                                    ? null
                                    : Severity.major,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── APPLY BUTTON ──
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _C.teal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _C.teal.withOpacity(.35),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TERAPKAN FILTER',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: .6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ANIMATED EXPANDED DROPDOWN
// (sama persis dengan pattern _PlantDropdown di dashboard)
// ══════════════════════════════════════════════════════════════════════
class _ExpandedDropdown extends ConsumerStatefulWidget {
  const _ExpandedDropdown({
    required this.icon,
    required this.providerKey,
    required this.watchValue,
    required this.watchItems,
    required this.onSelect,
  });
  final IconData icon;
  final String providerKey;
  final String Function(WidgetRef) watchValue;
  final AsyncValue<List<String>> Function(WidgetRef) watchItems;
  final void Function(WidgetRef, String) onSelect;

  @override
  ConsumerState<_ExpandedDropdown> createState() => _ExpandedDropdownState();
}

class _ExpandedDropdownState extends ConsumerState<_ExpandedDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _rotateAnim = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _ctrl.forward() : _ctrl.reverse();
  }

  void _select(String value) {
    widget.onSelect(ref, value);
    Future.delayed(const Duration(milliseconds: 140), _toggle);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.watchValue(ref);
    final itemsAsync = widget.watchItems(ref);

    return itemsAsync.when(
      loading: () => const _ShimmerBox(),
      error: (_, __) => const SizedBox.shrink(),
      data:
          (items) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isOpen ? _card : _raised,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── trigger ──
                GestureDetector(
                  onTap: _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _C.blueLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(widget.icon, size: 15, color: _C.blue),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selected,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _rotateAnim,
                          builder:
                              (_, child) => Transform.rotate(
                                angle: _rotateAnim.value * math.pi,
                                child: child,
                              ),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _C.pageBg,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.shadowDark.withOpacity(.3),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                const BoxShadow(
                                  color: _C.shadowLight,
                                  offset: Offset(-1, -1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _C.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── expandable list ──
                SizeTransition(
                  sizeFactor: _expandAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Divider(height: 1, color: _C.pageBg),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            children:
                                items
                                    .map(
                                      (item) => _ExpandedItem(
                                        label: item,
                                        isActive: item == selected,
                                        onTap: () => _select(item),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _ExpandedItem extends StatelessWidget {
  const _ExpandedItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? _C.blueLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? _C.blue : _C.textPrimary,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: isActive ? 1 : 0,
              child: const Icon(Icons.check_rounded, size: 16, color: _C.blue),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// FILTER COMPONENT WIDGETS
// ══════════════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      color: _C.textMuted,
      letterSpacing: .7,
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.isOn,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isOn ? _C.textPrimary : _C.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              isOn
                  ? [
                    BoxShadow(
                      color: _C.textPrimary.withOpacity(.28),
                      offset: const Offset(3, 4),
                      blurRadius: 10,
                    ),
                  ]
                  : _raised,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isOn ? Colors.white : _C.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isOn ? Colors.white : _C.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SevChip extends StatelessWidget {
  const _SevChip({
    required this.label,
    required this.activeColor,
    required this.isOn,
    required this.onTap,
  });
  final String label;
  final Color activeColor;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border:
              isOn
                  ? Border(bottom: BorderSide(color: activeColor, width: 2.5))
                  : null,
          boxShadow:
              isOn
                  ? [
                    BoxShadow(
                      color: _C.shadowDark.withOpacity(.35),
                      offset: const Offset(2, 2),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                    const BoxShadow(
                      color: _C.shadowLight,
                      offset: Offset(-1, -1),
                      blurRadius: 4,
                      spreadRadius: -1,
                    ),
                  ]
                  : _raised,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOn ? activeColor : _C.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox();

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: _C.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: _raised,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
// SHARED UTILITIES
// ══════════════════════════════════════════════════════════════════════
class _NeuBtn extends StatelessWidget {
  const _NeuBtn({
    required this.size,
    required this.radius,
    required this.child,
    required this.onTap,
  });
  final double size, radius;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: _raised,
        ),
        child: child,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _raised,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 26,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada laporan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(fontSize: 12, color: _C.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: _C.textMuted),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(fontSize: 13, color: _C.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
// ══════════════════════════════════════════════════════════════════════
// report_list_screen.dart
// lib/samples/ui/rive_app/navigation/list_inspeksi/presentation/screen/
// ══════════════════════════════════════════════════════════════════════
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:intl/intl.dart';

// import '../../../../core/localizations/app_localizations.dart';
// import '../../../detail/presentation/provider/report_detail_service.dart';
// import '../../../detail/presentation/screen/report_detail_screen.dart';
// import '../../../inspeksi/entities/inspection_report.dart';
// import '../provider/filter_provider.dart';

// // ── Search type enum ────────────────────────────────────────────────
// enum SearchType { content, object }

// final searchTypeProvider = StateProvider<SearchType>(
//   (ref) => SearchType.content,
// );
// final isFilterExpandedProvider = StateProvider<bool>((ref) => false);
// final reportDetailProvider = FutureProvider.family<InspectionReport, int>((
//   ref,
//   id,
// ) async {
//   final service = ref.read(detailServiceProvider);
//   return service.getDetail(id);
// });

// // ══════════════════════════════════════════════════════════════════════
// // COLOR TOKENS
// // ══════════════════════════════════════════════════════════════════════
// class _C {
//   static const pageBg = Color(0xFFECEDF5); // abu-abu lavender
//   static const white = Color(0xFFFFFFFF); // card / button / komponen

//   static const shadowDark = Color(0xFFB4B8CC);
//   static const shadowLight = Color(0xFFFFFFFF);

//   static const textPrimary = Color(0xFF1A1A2E);
//   static const textSecondary = Color(0xFF6B7080);
//   static const textMuted = Color(0xFF9CA3AF);

//   static const blue = Color(0xFF2563EB);
//   static const blueLight = Color(0xFFDBEAFE);
//   static const green = Color(0xFF16A34A);
//   static const greenLight = Color(0xFFDCFCE7);
//   static const amber = Color(0xFFD97706);
//   static const amberLight = Color(0xFFFEF3C7);
//   static const red = Color(0xFFDC2626);
//   static const redLight = Color(0xFFFEE2E2);
//   static const purple = Color(0xFF9333EA);
//   static const purpleLight = Color(0xFFFAF5FF);
//   static const teal = Color(0xFF0F766E);
// }

// // ── Shadow helpers ──────────────────────────────────────────────────
// List<BoxShadow> get _raised => [
//   BoxShadow(
//     color: _C.shadowDark.withOpacity(.42),
//     offset: const Offset(4, 6),
//     blurRadius: 14,
//   ),
//   BoxShadow(
//     color: _C.shadowLight.withOpacity(.9),
//     offset: const Offset(-2, -2),
//     blurRadius: 6,
//   ),
// ];

// List<BoxShadow> get _card => [
//   BoxShadow(
//     color: _C.shadowDark.withOpacity(.22),
//     offset: const Offset(4, 6),
//     blurRadius: 16,
//   ),
//   BoxShadow(
//     color: _C.shadowLight.withOpacity(.8),
//     offset: const Offset(-1, -1),
//     blurRadius: 4,
//   ),
// ];

// // ══════════════════════════════════════════════════════════════════════
// // MAIN SCREEN
// // ══════════════════════════════════════════════════════════════════════
// class ReportListScreen extends ConsumerWidget {
//   const ReportListScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final reportsAsync = ref.watch(filteredReportsProvider(null));
//     final isFilterOpen = ref.watch(isFilterExpandedProvider);
//     final l10n = AppLocalizations.of(context)!;

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Container(
//         clipBehavior: Clip.hardEdge,
//         decoration: BoxDecoration(
//           color: _C.pageBg,
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 _TopBar(l10n: l10n),
//                 _StatBar(reportsAsync: reportsAsync),
//                 _SearchRow(l10n: l10n),
//                 _QuickTabs(),
//                 Expanded(
//                   child: reportsAsync.when(
//                     loading:
//                         () => const Center(
//                           child: CircularProgressIndicator(
//                             color: _C.blue,
//                             strokeWidth: 2,
//                           ),
//                         ),
//                     error: (e, _) => _ErrorState(message: e.toString()),
//                     data:
//                         (reports) =>
//                             reports.isEmpty
//                                 ? const _EmptyState()
//                                 : _ReportList(reports: reports, l10n: l10n),
//                   ),
//                 ),
//               ],
//             ),
//             if (isFilterOpen)
//               _FilterOverlay(
//                 l10n: l10n,
//                 onClose:
//                     () =>
//                         ref.read(isFilterExpandedProvider.notifier).state =
//                             false,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // TOP BAR
// // ══════════════════════════════════════════════════════════════════════
// class _TopBar extends ConsumerWidget {
//   const _TopBar({required this.l10n});
//   final AppLocalizations l10n;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Padding(
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 10,
//         left: 20,
//         right: 20,
//         bottom: 14,
//       ),
//       child: Row(
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(top: 14.0, left: 45.0),
//             child: Expanded(
//               child: Text(
//                 l10n.listReports.toUpperCase(),
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                   color: _C.textPrimary,
//                   letterSpacing: .6,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // STAT BAR — Total / Pending / Selesai
// // ══════════════════════════════════════════════════════════════════════
// class _StatBar extends ConsumerWidget {
//   const _StatBar({required this.reportsAsync});
//   final AsyncValue<List<InspectionReport>> reportsAsync;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final reports = reportsAsync.maybeWhen(
//       data: (data) => data,
//       orElse: () => const <InspectionReport>[],
//     );

//     final total = reports.length;
//     final pending = reports.where((r) => !r.isComplete).length;
//     final done = reports.where((r) => r.isComplete).length;

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       child: Row(
//         children: [
//           Expanded(
//             child: _StatCard(
//               icon: Icons.description_outlined,
//               iconBg: const Color(0xFFEEF2FF),
//               iconColor: const Color(0xFF4F46E5),
//               value: '$total',
//               label: 'Total',
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.access_time_rounded,
//               iconBg: _C.amberLight,
//               iconColor: _C.amber,
//               value: '$pending',
//               label: 'Pending',
//               valueColor: _C.amber,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.check_circle_outline_rounded,
//               iconBg: _C.greenLight,
//               iconColor: _C.green,
//               value: '$done',
//               label: 'Selesai',
//               valueColor: _C.green,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   const _StatCard({
//     required this.icon,
//     required this.iconBg,
//     required this.iconColor,
//     required this.value,
//     required this.label,
//     this.valueColor = _C.textPrimary,
//   });
//   final IconData icon;
//   final Color iconBg, iconColor, valueColor;
//   final String value, label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: _C.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: _raised,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               color: iconBg,
//               borderRadius: BorderRadius.circular(9),
//             ),
//             child: Icon(icon, color: iconColor, size: 15),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//               color: valueColor,
//               height: 1,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 10,
//               color: _C.textMuted,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // SEARCH ROW
// // ══════════════════════════════════════════════════════════════════════
// class _SearchRow extends ConsumerWidget {
//   const _SearchRow({required this.l10n});
//   final AppLocalizations l10n;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final hasFilter =
//         ref.watch(selectedStatusFilterProvider) != null ||
//         ref.watch(selectedSeverityFilterProvider) != null ||
//         ref.watch(plantFilterProvider) != 'All Plants';

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               height: 44,
//               decoration: BoxDecoration(
//                 color: _C.pageBg,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _C.shadowDark.withOpacity(.38),
//                     offset: const Offset(3, 3),
//                     blurRadius: 7,
//                     spreadRadius: -1,
//                   ),
//                   const BoxShadow(
//                     color: _C.shadowLight,
//                     offset: Offset(-2, -2),
//                     blurRadius: 5,
//                     spreadRadius: -1,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const SizedBox(width: 14),
//                   const Icon(
//                     Icons.search_rounded,
//                     size: 18,
//                     color: _C.textMuted,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       onChanged:
//                           (v) =>
//                               ref.read(searchQueryProvider.notifier).state = v,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: _C.textPrimary,
//                       ),
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         hintText: 'Cari nama area, ID laporan...',
//                         hintStyle: TextStyle(fontSize: 13, color: _C.textMuted),
//                         isDense: true,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               _NeuBtn(
//                 size: 44,
//                 radius: 14,
//                 onTap:
//                     () =>
//                         ref.read(isFilterExpandedProvider.notifier).state =
//                             true,
//                 child: const Icon(
//                   Icons.filter_list_rounded,
//                   size: 18,
//                   color: _C.textSecondary,
//                 ),
//               ),
//               if (hasFilter)
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Container(
//                     width: 8,
//                     height: 8,
//                     decoration: BoxDecoration(
//                       color: _C.blue,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: _C.pageBg, width: 1.5),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // QUICK TABS
// // ══════════════════════════════════════════════════════════════════════
// class _QuickTabs extends ConsumerWidget {
//   const _QuickTabs();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final statusFilter = ref.watch(selectedStatusFilterProvider);
//     final severityFilter = ref.watch(selectedSeverityFilterProvider);

//     String activeKey = 'all';
//     if (statusFilter == true) activeKey = 'done';
//     if (statusFilter == false) activeKey = 'pending';
//     if (severityFilter == Severity.major) activeKey = 'major';
//     if (severityFilter == Severity.minor) activeKey = 'minor';

//     void tap(String key) {
//       switch (key) {
//         case 'all':
//           ref.read(selectedStatusFilterProvider.notifier).state = null;
//           ref.read(selectedSeverityFilterProvider.notifier).state = null;
//           break;
//         case 'done':
//           ref.read(selectedStatusFilterProvider.notifier).state = true;
//           ref.read(selectedSeverityFilterProvider.notifier).state = null;
//           break;
//         case 'pending':
//           ref.read(selectedStatusFilterProvider.notifier).state = false;
//           ref.read(selectedSeverityFilterProvider.notifier).state = null;
//           break;
//         case 'major':
//           ref.read(selectedStatusFilterProvider.notifier).state = null;
//           ref.read(selectedSeverityFilterProvider.notifier).state =
//               Severity.major;
//           break;
//         case 'minor':
//           ref.read(selectedStatusFilterProvider.notifier).state = null;
//           ref.read(selectedSeverityFilterProvider.notifier).state =
//               Severity.minor;
//           break;
//       }
//     }

//     const tabs = [
//       ('all', 'Semua'),
//       ('pending', 'Pending'),
//       ('major', 'Major'),
//       ('minor', 'Minor'),
//     ];

//     return SizedBox(
//       height: 40,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: tabs.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 8),
//         itemBuilder: (_, i) {
//           final key = tabs[i].$1;
//           final label = tabs[i].$2;
//           final isActive = activeKey == key;
//           return GestureDetector(
//             onTap: () => tap(key),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 180),
//               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
//               decoration: BoxDecoration(
//                 color: isActive ? _C.textPrimary : _C.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow:
//                     isActive
//                         ? [
//                           BoxShadow(
//                             color: _C.textPrimary.withOpacity(.28),
//                             offset: const Offset(3, 4),
//                             blurRadius: 10,
//                           ),
//                         ]
//                         : _raised,
//               ),
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   color: isActive ? Colors.white : _C.textSecondary,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // REPORT LIST
// // ══════════════════════════════════════════════════════════════════════
// class _ReportList extends StatelessWidget {
//   const _ReportList({required this.reports, required this.l10n});
//   final List<InspectionReport> reports;
//   final AppLocalizations l10n;

//   @override
//   Widget build(BuildContext context) {
//     return CustomScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       slivers: [
//         SliverPadding(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//           sliver: SliverToBoxAdapter(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'LAPORAN TERBARU',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w800,
//                     color: _C.textMuted,
//                     letterSpacing: .8,
//                   ),
//                 ),
//                 Text(
//                   '${reports.length} laporan',
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: _C.textMuted,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         SliverPadding(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
//           sliver: SliverList(
//             delegate: SliverChildBuilderDelegate(
//               (context, i) => Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: _ReportCard(
//                   key: ValueKey('card_${reports[i].id}'),
//                   report: reports[i],
//                   l10n: l10n,
//                 ),
//               ),
//               childCount: reports.length,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // REPORT CARD — white card on gray bg
// // ══════════════════════════════════════════════════════════════════════
// class _ReportCard extends StatelessWidget {
//   const _ReportCard({super.key, required this.report, required this.l10n});
//   final InspectionReport report;
//   final AppLocalizations l10n;

//   Color get _accent {
//     switch (report.finalSeverity) {
//       case Severity.good:
//         return _C.blue;
//       case Severity.minor:
//         return _C.amber;
//       case Severity.major:
//         return _C.red;
//     }
//   }

//   Color get _bubbleBg {
//     switch (report.finalSeverity) {
//       case Severity.good:
//         return _C.blueLight;
//       case Severity.minor:
//         return _C.amberLight;
//       case Severity.major:
//         return _C.redLight;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isComplete = report.isComplete;
//     final isOverride = report.override;
//     final timeStr = DateFormat(
//       'dd MMM yyyy · HH:mm',
//     ).format(report.timestamp.toLocal());

//     return GestureDetector(
//       onTap:
//           () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) => ReportDetailScreen(report: report, canEdit: false),
//             ),
//           ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: _C.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: _card,
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(18),
//           child: Row(
//             children: [
//               // ── severity accent bar (left edge) ──
//               Container(width: 4, color: _accent),

//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 14, 14, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // ── top row ──
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // severity bubble icon
//                           Container(
//                             width: 42,
//                             height: 42,
//                             decoration: BoxDecoration(
//                               color: _bubbleBg,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               report.severityIcon,
//                               color: _accent,
//                               size: 20,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           // title + date
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   report.areaName,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w700,
//                                     color: _C.textPrimary,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 const SizedBox(height: 3),
//                                 Text(
//                                   timeStr,
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     color: _C.textMuted,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // badge column
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               _Badge(
//                                 label: isComplete ? l10n.complete : 'Pending',
//                                 bg: isComplete ? _C.greenLight : _C.amberLight,
//                                 color: isComplete ? _C.green : _C.amber,
//                               ),
//                               const SizedBox(height: 4),
//                               _Badge(
//                                 label: isOverride ? 'Override' : 'AI',
//                                 bg: isOverride ? _C.purpleLight : _C.blueLight,
//                                 color: isOverride ? _C.purple : _C.blue,
//                                 fontSize: 9,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 10),
//                       const Divider(height: 1, color: Color(0xFFF3F4F6)),
//                       const SizedBox(height: 10),

//                       // ── footer row ──
//                       Row(
//                         children: [
//                           _MetaCol(label: 'ID', value: '#${report.id}'),
//                           _MetaCol(
//                             label: 'SEVERITY',
//                             value: report.finalSeverity.name.toUpperCase(),
//                             dotColor: _accent,
//                           ),
//                           _MetaCol(
//                             label: 'KATEGORI',
//                             value: report.category.displayName.toUpperCase(),
//                           ),
//                           const Spacer(),
//                           // arrow button — neumorphic on pageBg
//                           Container(
//                             width: 28,
//                             height: 28,
//                             decoration: BoxDecoration(
//                               color: _C.pageBg,
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: _raised,
//                             ),
//                             child: const Icon(
//                               Icons.arrow_forward_ios_rounded,
//                               size: 11,
//                               color: _C.textMuted,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MetaCol extends StatelessWidget {
//   const _MetaCol({required this.label, required this.value, this.dotColor});
//   final String label, value;
//   final Color? dotColor;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 9,
//               fontWeight: FontWeight.w700,
//               color: _C.textMuted,
//               letterSpacing: .4,
//             ),
//           ),
//           const SizedBox(height: 3),
//           Row(
//             children: [
//               if (dotColor != null) ...[
//                 Container(
//                   width: 6,
//                   height: 6,
//                   decoration: BoxDecoration(
//                     color: dotColor,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//               ],
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w700,
//                   color: _C.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Badge extends StatelessWidget {
//   const _Badge({
//     required this.label,
//     required this.bg,
//     required this.color,
//     this.fontSize = 10.0,
//   });
//   final String label;
//   final Color bg, color;
//   final double fontSize;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(7),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontSize: fontSize,
//           fontWeight: FontWeight.w700,
//           color: color,
//         ),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // FILTER OVERLAY — frosted glass bottom sheet
// // ══════════════════════════════════════════════════════════════════════
// class _FilterOverlay extends ConsumerWidget {
//   const _FilterOverlay({required this.l10n, required this.onClose});
//   final AppLocalizations l10n;
//   final VoidCallback onClose;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return GestureDetector(
//       onTap: onClose,
//       child: Container(
//         color: _C.textPrimary.withOpacity(.18),
//         child: Align(
//           alignment: Alignment.bottomCenter,
//           child: GestureDetector(
//             onTap: () {},
//             child: _FilterSheet(l10n: l10n, onClose: onClose),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FilterSheet extends ConsumerWidget {
//   const _FilterSheet({required this.l10n, required this.onClose});
//   final AppLocalizations l10n;
//   final VoidCallback onClose;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final statusFilter = ref.watch(selectedStatusFilterProvider);
//     final severityFilter = ref.watch(selectedSeverityFilterProvider);
//     final plantsAsync = ref.watch(plantsMasterProvider);
//     final selectedPlant = ref.watch(plantFilterProvider);
//     final catAsync = ref.watch(categoriesMasterProvider);
//     final selectedCat = ref.watch(categoryFilterProvider);

//     void resetAll() {
//       ref.read(selectedStatusFilterProvider.notifier).state = null;
//       ref.read(selectedSeverityFilterProvider.notifier).state = null;
//       ref.read(plantFilterProvider.notifier).state = 'All Plants';
//       ref.read(categoryFilterProvider.notifier).state = 'All Categories';
//     }

//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xF5F0F1FA), // frosted glass — semi-opaque white
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       padding: EdgeInsets.only(
//         left: 20,
//         right: 20,
//         bottom: MediaQuery.of(context).padding.bottom + 24,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // handle bar
//           Center(
//             child: Container(
//               margin: const EdgeInsets.only(top: 12, bottom: 18),
//               width: 36,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFC8CADC),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),

//           // header
//           Row(
//             children: [
//               const Icon(Icons.tune_rounded, size: 18, color: _C.textPrimary),
//               const SizedBox(width: 8),
//               const Text(
//                 'Opsi Filter',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w800,
//                   color: _C.textPrimary,
//                 ),
//               ),
//               const Spacer(),
//               GestureDetector(
//                 onTap: resetAll,
//                 child: const Text(
//                   'Reset',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: _C.blue,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 18),

//           // ── STATUS ──
//           const _FieldLabel('STATUS LAPORAN'),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Expanded(
//                 child: _ToggleBtn(
//                   label: 'Pending',
//                   icon: Icons.access_time_rounded,
//                   isOn: statusFilter == false,
//                   onTap:
//                       () =>
//                           ref
//                               .read(selectedStatusFilterProvider.notifier)
//                               .state = statusFilter == false ? null : false,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _ToggleBtn(
//                   label: 'Selesai',
//                   icon: Icons.check_circle_outline_rounded,
//                   isOn: statusFilter == true,
//                   onTap:
//                       () =>
//                           ref
//                               .read(selectedStatusFilterProvider.notifier)
//                               .state = statusFilter == true ? null : true,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // ── LOKASI PLANT ──
//           const _FieldLabel('LOKASI PLANT'),
//           const SizedBox(height: 8),
//           plantsAsync.when(
//             loading: () => const _ShimmerBox(),
//             error: (_, __) => const SizedBox.shrink(),
//             data:
//                 (plants) => _NeuDropdown(
//                   icon: Icons.location_on_outlined,
//                   value: selectedPlant,
//                   items: plants,
//                   onChanged:
//                       (v) => ref.read(plantFilterProvider.notifier).state = v,
//                 ),
//           ),

//           const SizedBox(height: 16),

//           // ── KATEGORI ──
//           const _FieldLabel('KATEGORI'),
//           const SizedBox(height: 8),
//           catAsync.when(
//             loading: () => const _ShimmerBox(),
//             error: (_, __) => const SizedBox.shrink(),
//             data:
//                 (cats) => _NeuDropdown(
//                   icon: Icons.grid_view_rounded,
//                   value: selectedCat,
//                   items: cats,
//                   onChanged:
//                       (v) =>
//                           ref.read(categoryFilterProvider.notifier).state = v,
//                 ),
//           ),

//           const SizedBox(height: 16),

//           // ── SEVERITY ──
//           const _FieldLabel('TINGKAT SEVERITY'),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Expanded(
//                 child: _SevChip(
//                   label: 'Good',
//                   activeColor: _C.blue,
//                   isOn: severityFilter == Severity.good,
//                   onTap:
//                       () =>
//                           ref
//                               .read(selectedSeverityFilterProvider.notifier)
//                               .state = severityFilter == Severity.good
//                                   ? null
//                                   : Severity.good,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _SevChip(
//                   label: 'Minor',
//                   activeColor: _C.amber,
//                   isOn: severityFilter == Severity.minor,
//                   onTap:
//                       () =>
//                           ref
//                               .read(selectedSeverityFilterProvider.notifier)
//                               .state = severityFilter == Severity.minor
//                                   ? null
//                                   : Severity.minor,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _SevChip(
//                   label: 'Major',
//                   activeColor: _C.red,
//                   isOn: severityFilter == Severity.major,
//                   onTap:
//                       () =>
//                           ref
//                               .read(selectedSeverityFilterProvider.notifier)
//                               .state = severityFilter == Severity.major
//                                   ? null
//                                   : Severity.major,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 22),

//           // ── APPLY BUTTON — teal ──
//           GestureDetector(
//             onTap: onClose,
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 15),
//               decoration: BoxDecoration(
//                 color: _C.teal,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _C.teal.withOpacity(.35),
//                     offset: const Offset(0, 6),
//                     blurRadius: 14,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Icon(
//                     Icons.filter_list_rounded,
//                     size: 16,
//                     color: Colors.white,
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     'TERAPKAN FILTER',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                       letterSpacing: .6,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Filter component widgets ─────────────────────────────────────────

// class _FieldLabel extends StatelessWidget {
//   const _FieldLabel(this.text);
//   final String text;

//   @override
//   Widget build(BuildContext context) => Text(
//     text,
//     style: const TextStyle(
//       fontSize: 9,
//       fontWeight: FontWeight.w800,
//       color: _C.textMuted,
//       letterSpacing: .7,
//     ),
//   );
// }

// class _ToggleBtn extends StatelessWidget {
//   const _ToggleBtn({
//     required this.label,
//     required this.icon,
//     required this.isOn,
//     required this.onTap,
//   });
//   final String label;
//   final IconData icon;
//   final bool isOn;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(vertical: 11),
//         decoration: BoxDecoration(
//           color: isOn ? _C.textPrimary : _C.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow:
//               isOn
//                   ? [
//                     BoxShadow(
//                       color: _C.textPrimary.withOpacity(.28),
//                       offset: const Offset(3, 4),
//                       blurRadius: 10,
//                     ),
//                   ]
//                   : _raised,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 14, color: isOn ? Colors.white : _C.textSecondary),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//                 color: isOn ? Colors.white : _C.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NeuDropdown extends StatelessWidget {
//   const _NeuDropdown({
//     required this.icon,
//     required this.value,
//     required this.items,
//     required this.onChanged,
//   });
//   final IconData icon;
//   final String value;
//   final List<String> items;
//   final void Function(String) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 48,
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       decoration: BoxDecoration(
//         color: _C.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: _raised,
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: _C.textMuted),
//           const SizedBox(width: 10),
//           Expanded(
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: value,
//                 isExpanded: true,
//                 icon: const Icon(
//                   Icons.keyboard_arrow_down_rounded,
//                   size: 18,
//                   color: _C.textMuted,
//                 ),
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: _C.textPrimary,
//                   fontFamily: 'Inter',
//                 ),
//                 dropdownColor: _C.white,
//                 borderRadius: BorderRadius.circular(14),
//                 items:
//                     items
//                         .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                         .toList(),
//                 onChanged: (v) {
//                   if (v != null) onChanged(v);
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SevChip extends StatelessWidget {
//   const _SevChip({
//     required this.label,
//     required this.activeColor,
//     required this.isOn,
//     required this.onTap,
//   });
//   final String label;
//   final Color activeColor;
//   final bool isOn;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(vertical: 11),
//         decoration: BoxDecoration(
//           color: _C.white,
//           borderRadius: BorderRadius.circular(14),
//           border:
//               isOn
//                   ? Border(bottom: BorderSide(color: activeColor, width: 2.5))
//                   : null,
//           boxShadow:
//               isOn
//                   ? [
//                     BoxShadow(
//                       color: _C.shadowDark.withOpacity(.35),
//                       offset: const Offset(2, 2),
//                       blurRadius: 6,
//                       spreadRadius: -1,
//                     ),
//                     const BoxShadow(
//                       color: _C.shadowLight,
//                       offset: Offset(-1, -1),
//                       blurRadius: 4,
//                       spreadRadius: -1,
//                     ),
//                   ]
//                   : _raised,
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w700,
//               color: isOn ? activeColor : _C.textSecondary,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ShimmerBox extends StatelessWidget {
//   const _ShimmerBox();

//   @override
//   Widget build(BuildContext context) => Container(
//     height: 48,
//     decoration: BoxDecoration(
//       color: _C.white,
//       borderRadius: BorderRadius.circular(14),
//       boxShadow: _raised,
//     ),
//   );
// }

// // ══════════════════════════════════════════════════════════════════════
// // SHARED UTILITY
// // ══════════════════════════════════════════════════════════════════════
// class _NeuBtn extends StatelessWidget {
//   const _NeuBtn({
//     required this.size,
//     required this.radius,
//     required this.child,
//     required this.onTap,
//   });
//   final double size, radius;
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           color: _C.white,
//           borderRadius: BorderRadius.circular(radius),
//           boxShadow: _raised,
//         ),
//         child: child,
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               color: _C.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: _raised,
//             ),
//             child: const Icon(
//               Icons.inbox_outlined,
//               size: 26,
//               color: _C.textMuted,
//             ),
//           ),
//           const SizedBox(height: 14),
//           const Text(
//             'Tidak ada laporan',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: _C.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Coba ubah filter atau kata kunci pencarian',
//             style: TextStyle(fontSize: 12, color: _C.textMuted),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ErrorState extends StatelessWidget {
//   const _ErrorState({required this.message});
//   final String message;

//   @override
//   Widget build(BuildContext context) => Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(Icons.cloud_off_rounded, size: 48, color: _C.textMuted),
//         const SizedBox(height: 12),
//         Text(
//           message,
//           style: const TextStyle(fontSize: 13, color: _C.textSecondary),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     ),
//   );
// }
