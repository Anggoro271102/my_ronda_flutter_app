// // ══════════════════════════════════════════════════════════════════════
// // dashboard_screen.dart
// // lib/samples/ui/rive_app/navigation/home/presentation/screen/
// // ══════════════════════════════════════════════════════════════════════
// import 'dart:math' as math;

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../../core/localizations/app_localizations.dart';
// import '../../../auth/presentation/provider/user_provider.dart';
// import '../../../inspeksi/entities/inspection_report.dart';
// import '../../../list_inspeksi/presentation/provider/filter_provider.dart';
// import '../provider/report_provider.dart';

// // ══════════════════════════════════════════════════════════════════════
// // MAIN SCREEN
// // ══════════════════════════════════════════════════════════════════════
// class DashboardScreen extends ConsumerWidget {
//   const DashboardScreen({super.key});
//   static const pageBgGray = Color(0xFFECEDF5);
//   // ── Color tokens ────────────────────────────────────────────────────
//   static const Color white = Color(0xFFFFFFFF);
//   static const Color pageBg = Color(0xFFF7F8FA);
//   static const Color border = Color(0xFFE5E7EB);
//   static const Color borderLight = Color(0xFFF3F4F6);

//   static const Color textPrimary = Color(0xFF111827);
//   static const Color textSecondary = Color(0xFF6B7280);
//   static const Color textMuted = Color(0xFF9CA3AF);

//   static const Color blue = Color(0xFF2563EB);
//   static const Color blueLight = Color(0xFFDBEAFE);
//   static const Color green = Color(0xFF16A34A);
//   static const Color greenLight = Color(0xFFDCFCE7);
//   static const Color amber = Color(0xFFD97706);
//   static const Color amberLight = Color(0xFFFEF3C7);
//   static const Color red = Color(0xFFDC2626);
//   static const Color redLight = Color(0xFFFEE2E2);

//   // ── Navigation helper ───────────────────────────────────────────────
//   void _navigate({required WidgetRef ref, bool? status, Severity? severity}) {
//     ref.read(selectedStatusFilterProvider.notifier).state = status;
//     ref.read(selectedSeverityFilterProvider.notifier).state = severity;
//     ref.read(navIndexProvider.notifier).state = 2;
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedPlant = ref.watch(plantFilterProvider);
//     final dashboardAsync = ref.watch(dashboardStatsProvider(selectedPlant));
//     final user = ref.watch(userProvider);
//     final l10n = AppLocalizations.of(context)!;

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Container(
//         clipBehavior: Clip.hardEdge,
//         decoration: BoxDecoration(
//           color: pageBgGray,
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: dashboardAsync.when(
//           loading:
//               () => const Center(
//                 child: CircularProgressIndicator(color: blue, strokeWidth: 2),
//               ),
//           error: (err, _) => _ErrorState(message: err.toString()),
//           data:
//               (data) => RefreshIndicator(
//                 color: blue,
//                 backgroundColor: white,
//                 onRefresh:
//                     () => ref.refresh(
//                       dashboardStatsProvider(selectedPlant).future,
//                     ),
//                 child: CustomScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   slivers: [
//                     // ── 1. Header ────────────────────────────────────────
//                     SliverToBoxAdapter(child: _Header(user: user)),

//                     // ── 2. Plant dropdown ────────────────────────────────
//                     const SliverToBoxAdapter(child: _PlantDropdown()),

//                     // ── 3. Hero card ─────────────────────────────────────
//                     SliverPadding(
//                       padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
//                       sliver: SliverToBoxAdapter(
//                         child: _HeroCard(data: data, l10n: l10n),
//                       ),
//                     ),

//                     // ── 4. Stat 2×2 grid ─────────────────────────────────
//                     SliverPadding(
//                       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//                       sliver: SliverToBoxAdapter(
//                         child: _StatSection(
//                           data: data,
//                           l10n: l10n,
//                           onTap:
//                               (status, severity) => _navigate(
//                                 ref: ref,
//                                 status: status,
//                                 severity: severity,
//                               ),
//                         ),
//                       ),
//                     ),

//                     // ── 5. Severity breakdown ─────────────────────────────
//                     SliverPadding(
//                       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//                       sliver: SliverToBoxAdapter(
//                         child: _SeveritySection(
//                           data: data,
//                           l10n: l10n,
//                           onTap:
//                               (severity) =>
//                                   _navigate(ref: ref, severity: severity),
//                         ),
//                       ),
//                     ),

//                     // ── 6. Bar chart ──────────────────────────────────────
//                     SliverPadding(
//                       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//                       sliver: SliverToBoxAdapter(
//                         child: _BarChartSection(data: data),
//                       ),
//                     ),

//                     const SliverToBoxAdapter(child: SizedBox(height: 120)),
//                   ],
//                 ),
//               ),
//         ),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // 1. HEADER
// // ══════════════════════════════════════════════════════════════════════
// class _Header extends StatelessWidget {
//   const _Header({required this.user});
//   final dynamic user; // UserModel?

//   String get _greeting {
//     final h = DateTime.now().hour;
//     if (h < 11) return 'SELAMAT PAGI,';
//     if (h < 15) return 'SELAMAT SIANG,';
//     if (h < 18) return 'SELAMAT SORE,';
//     return 'SELAMAT MALAM,';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 10,
//         left: 20,
//         right: 20,
//         bottom: 12,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 14.0, left: 45.0),
//                   child: Text(
//                     _greeting,
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w700,
//                       color: DashboardScreen.textMuted,
//                       letterSpacing: .6,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 45.0),
//                   child: Text(
//                     user?.name as String? ?? 'Dashboard',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.w700,
//                       color: DashboardScreen.textPrimary,
//                       height: 1.2,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // notification bell
//         ],
//       ),
//     );
//   }
// }

// class _IconButton extends StatelessWidget {
//   const _IconButton({required this.icon, required this.onTap});
//   final IconData icon;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           color: DashboardScreen.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: DashboardScreen.border),
//         ),
//         child: Icon(icon, size: 17, color: DashboardScreen.textSecondary),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // 2. PLANT DROPDOWN (animated expand)
// // ══════════════════════════════════════════════════════════════════════
// class _PlantDropdown extends ConsumerStatefulWidget {
//   const _PlantDropdown();

//   @override
//   ConsumerState<_PlantDropdown> createState() => _PlantDropdownState();
// }

// class _PlantDropdownState extends ConsumerState<_PlantDropdown>
//     with SingleTickerProviderStateMixin {
//   bool _isOpen = false;
//   late final AnimationController _ctrl;
//   late final Animation<double> _expandAnim;
//   late final Animation<double> _fadeAnim;
//   late final Animation<double> _rotateAnim;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 260),
//     );
//     _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
//     _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
//     _rotateAnim = Tween<double>(
//       begin: 0,
//       end: 0.5,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   void _toggle() {
//     setState(() => _isOpen = !_isOpen);
//     _isOpen ? _ctrl.forward() : _ctrl.reverse();
//   }

//   void _select(String plant) {
//     ref.read(plantFilterProvider.notifier).state = plant;
//     Future.delayed(const Duration(milliseconds: 140), _toggle);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final plantsAsync = ref.watch(plantsMasterProvider);
//     final selected = ref.watch(plantFilterProvider);

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//       child: plantsAsync.when(
//         loading: () => const _DropdownShimmer(),
//         error: (_, __) => const SizedBox.shrink(),
//         data:
//             (plants) => AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               decoration: BoxDecoration(
//                 color: DashboardScreen.white,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color:
//                       _isOpen ? DashboardScreen.blue : DashboardScreen.border,
//                   width: _isOpen ? 1.4 : 1,
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // ── Trigger row ──
//                   GestureDetector(
//                     onTap: _toggle,
//                     behavior: HitTestBehavior.opaque,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 12,
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 30,
//                             height: 30,
//                             decoration: BoxDecoration(
//                               color: DashboardScreen.blueLight,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               Icons.location_on_rounded,
//                               size: 15,
//                               color: DashboardScreen.blue,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   'LOKASI PLANT',
//                                   style: TextStyle(
//                                     fontSize: 9,
//                                     fontWeight: FontWeight.w700,
//                                     color: DashboardScreen.textMuted,
//                                     letterSpacing: .7,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 1),
//                                 Text(
//                                   selected,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                     color: DashboardScreen.textPrimary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // animated chevron
//                           AnimatedBuilder(
//                             animation: _rotateAnim,
//                             builder:
//                                 (_, child) => Transform.rotate(
//                                   angle: _rotateAnim.value * math.pi,
//                                   child: child,
//                                 ),
//                             child: Container(
//                               width: 26,
//                               height: 26,
//                               decoration: BoxDecoration(
//                                 color: DashboardScreen.borderLight,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: const Icon(
//                                 Icons.keyboard_arrow_down_rounded,
//                                 size: 18,
//                                 color: DashboardScreen.textSecondary,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   // ── Expandable panel ──
//                   SizeTransition(
//                     sizeFactor: _expandAnim,
//                     child: FadeTransition(
//                       opacity: _fadeAnim,
//                       child: Column(
//                         children: [
//                           Divider(
//                             height: 1,
//                             color: DashboardScreen.borderLight,
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(6),
//                             child: Column(
//                               children:
//                                   plants
//                                       .map(
//                                         (plant) => _DropdownItem(
//                                           label: plant,
//                                           isActive: plant == selected,
//                                           onTap: () => _select(plant),
//                                         ),
//                                       )
//                                       .toList(),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//       ),
//     );
//   }
// }

// class _DropdownItem extends StatelessWidget {
//   const _DropdownItem({
//     required this.label,
//     required this.isActive,
//     required this.onTap,
//   });
//   final String label;
//   final bool isActive;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 140),
//         margin: const EdgeInsets.symmetric(vertical: 2),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
//         decoration: BoxDecoration(
//           color: isActive ? DashboardScreen.blueLight : Colors.transparent,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color:
//                       isActive
//                           ? DashboardScreen.blue
//                           : DashboardScreen.textPrimary,
//                 ),
//               ),
//             ),
//             AnimatedOpacity(
//               duration: const Duration(milliseconds: 140),
//               opacity: isActive ? 1 : 0,
//               child: const Icon(
//                 Icons.check_rounded,
//                 size: 16,
//                 color: DashboardScreen.blue,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DropdownShimmer extends StatelessWidget {
//   const _DropdownShimmer();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 54,
//       decoration: BoxDecoration(
//         color: DashboardScreen.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: DashboardScreen.border),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: Row(
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               color: DashboardScreen.borderLight,
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Container(
//             width: 110,
//             height: 12,
//             decoration: BoxDecoration(
//               color: DashboardScreen.borderLight,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // 3. HERO CARD — donut ring + completion bar
// // ══════════════════════════════════════════════════════════════════════
// class _HeroCard extends StatelessWidget {
//   const _HeroCard({required this.data, required this.l10n});
//   final DashboardData data;
//   final AppLocalizations l10n;

//   @override
//   Widget build(BuildContext context) {
//     final pct =
//         data.total > 0
//             ? (data.complete / data.total * 100).toStringAsFixed(0)
//             : '0';
//     final progress =
//         data.total > 0 ? (data.complete / data.total).clamp(0.0, 1.0) : 0.0;

//     return Container(
//       decoration: BoxDecoration(
//         color: DashboardScreen.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: DashboardScreen.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'TOTAL INSPEKSI',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w700,
//                           color: DashboardScreen.textMuted,
//                           letterSpacing: .7,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         '${data.total}',
//                         style: const TextStyle(
//                           fontSize: 40,
//                           fontWeight: FontWeight.w700,
//                           color: DashboardScreen.textPrimary,
//                           height: 1,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       const Text(
//                         'laporan periode ini',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: DashboardScreen.textMuted,
//                         ),
//                       ),
//                       const SizedBox(height: 14),
//                       Row(
//                         children: [
//                           _MiniLegend(
//                             color: DashboardScreen.blue,
//                             label: '${data.complete} ${l10n.complete}',
//                           ),
//                           const SizedBox(width: 14),
//                           _MiniLegend(
//                             color: DashboardScreen.amber,
//                             label: '${data.incomplete} pending',
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 _DonutRing(
//                   progress: progress,
//                   label: '$pct%',
//                   size: 90,
//                   strokeWidth: 10,
//                   color: DashboardScreen.blue,
//                   bgColor: DashboardScreen.borderLight,
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: progress,
//                     minHeight: 6,
//                     backgroundColor: DashboardScreen.borderLight,
//                     valueColor: const AlwaysStoppedAnimation<Color>(
//                       DashboardScreen.blue,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   '$pct% completion rate',
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: DashboardScreen.textMuted,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MiniLegend extends StatelessWidget {
//   const _MiniLegend({required this.color, required this.label});
//   final Color color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 7,
//           height: 7,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 5),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 11,
//             color: DashboardScreen.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // 4. STAT 2×2 GRID
// // ══════════════════════════════════════════════════════════════════════
// class _StatSection extends StatelessWidget {
//   const _StatSection({
//     required this.data,
//     required this.l10n,
//     required this.onTap,
//   });
//   final DashboardData data;
//   final AppLocalizations l10n;
//   final void Function(bool? status, Severity? severity) onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _SectionTitle('Ringkasan status'),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _StatCard(
//                 icon: Icons.check_circle_outline_rounded,
//                 iconBg: DashboardScreen.greenLight,
//                 iconColor: DashboardScreen.green,
//                 value: '${data.complete}',
//                 label: l10n.complete,
//                 onTap: () => onTap(true, null),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _StatCard(
//                 icon: Icons.timelapse_rounded,
//                 iconBg: DashboardScreen.amberLight,
//                 iconColor: DashboardScreen.amber,
//                 value: '${data.incomplete}',
//                 label: l10n.incomplete,
//                 onTap: () => onTap(false, null),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _StatCard(
//                 icon: Icons.thumb_up_alt_outlined,
//                 iconBg: DashboardScreen.blueLight,
//                 iconColor: DashboardScreen.blue,
//                 value: '${data.good}',
//                 label: 'Good',
//                 onTap: () => onTap(null, Severity.good),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _StatCard(
//                 icon: Icons.warning_amber_rounded,
//                 iconBg: DashboardScreen.redLight,
//                 iconColor: DashboardScreen.red,
//                 value: '${data.critical}',
//                 label: 'Major',
//                 onTap: () => onTap(null, Severity.major),
//               ),
//             ),
//           ],
//         ),
//       ],
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
//     required this.onTap,
//   });

//   final IconData icon;
//   final Color iconBg, iconColor;
//   final String value, label;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: DashboardScreen.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: DashboardScreen.border),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: iconBg,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon, color: iconColor, size: 17),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.w700,
//                 color: DashboardScreen.textPrimary,
//                 height: 1,
//               ),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: DashboardScreen.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // 5. SEVERITY BREAKDOWN — horizontal bar rows
// // ══════════════════════════════════════════════════════════════════════
// class _SeveritySection extends StatelessWidget {
//   const _SeveritySection({
//     required this.data,
//     required this.l10n,
//     required this.onTap,
//   });
//   final DashboardData data;
//   final AppLocalizations l10n;
//   final void Function(Severity severity) onTap;

//   @override
//   Widget build(BuildContext context) {
//     final total = data.good + data.warning + data.critical;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _SectionTitle(l10n.issuesBySeverity),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: DashboardScreen.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: DashboardScreen.border),
//           ),
//           child: Column(
//             children: [
//               _SeverityRow(
//                 icon: Icons.check_circle_outline_rounded,
//                 label: 'Good',
//                 count: data.good,
//                 total: total,
//                 color: DashboardScreen.blue,
//                 trackColor: DashboardScreen.blueLight,
//                 isFirst: true,
//                 isLast: false,
//                 onTap: () => onTap(Severity.good),
//               ),
//               _SeverityRow(
//                 icon: Icons.warning_amber_rounded,
//                 label: 'Minor',
//                 count: data.warning,
//                 total: total,
//                 color: DashboardScreen.amber,
//                 trackColor: DashboardScreen.amberLight,
//                 isFirst: false,
//                 isLast: false,
//                 onTap: () => onTap(Severity.minor),
//               ),
//               _SeverityRow(
//                 icon: Icons.dangerous_outlined,
//                 label: 'Major',
//                 count: data.critical,
//                 total: total,
//                 color: DashboardScreen.red,
//                 trackColor: DashboardScreen.redLight,
//                 isFirst: false,
//                 isLast: true,
//                 onTap: () => onTap(Severity.major),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _SeverityRow extends StatelessWidget {
//   const _SeverityRow({
//     required this.icon,
//     required this.label,
//     required this.count,
//     required this.total,
//     required this.color,
//     required this.trackColor,
//     required this.isFirst,
//     required this.isLast,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final int count, total;
//   final Color color, trackColor;
//   final bool isFirst, isLast;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
//     final pct = (fraction * 100).toStringAsFixed(0);

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.vertical(
//         top: isFirst ? const Radius.circular(16) : Radius.zero,
//         bottom: isLast ? const Radius.circular(16) : Radius.zero,
//       ),
//       child: Column(
//         children: [
//           if (!isFirst) Divider(height: 1, color: DashboardScreen.borderLight),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
//             child: Row(
//               children: [
//                 // icon badge
//                 Container(
//                   width: 26,
//                   height: 26,
//                   decoration: BoxDecoration(
//                     color: trackColor,
//                     borderRadius: BorderRadius.circular(7),
//                   ),
//                   child: Icon(icon, size: 14, color: color),
//                 ),
//                 const SizedBox(width: 8),
//                 // dot
//                 Container(
//                   width: 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     color: color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // label
//                 SizedBox(
//                   width: 42,
//                   child: Text(
//                     label,
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: DashboardScreen.textPrimary,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // bar
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: LinearProgressIndicator(
//                       value: fraction,
//                       minHeight: 6,
//                       backgroundColor: trackColor,
//                       valueColor: AlwaysStoppedAnimation<Color>(color),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 // count + pct
//                 Text(
//                   '$count',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: color,
//                   ),
//                 ),
//                 const SizedBox(width: 3),
//                 Text(
//                   '($pct%)',
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: DashboardScreen.textMuted,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // 6. BAR CHART — premium style
// // ══════════════════════════════════════════════════════════════════════
// class _BarChartSection extends StatelessWidget {
//   const _BarChartSection({required this.data});
//   final DashboardData data;

//   static const double _maxY = 80;

//   @override
//   Widget build(BuildContext context) {
//     final total = data.good + data.warning + data.critical;
//     final goodPct =
//         total > 0 ? (data.good / total * 100).toStringAsFixed(0) : '0';
//     final minorPct =
//         total > 0 ? (data.warning / total * 100).toStringAsFixed(0) : '0';
//     final majorPct =
//         total > 0 ? (data.critical / total * 100).toStringAsFixed(0) : '0';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _SectionTitle('Distribusi temuan'),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: DashboardScreen.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: DashboardScreen.border),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // header
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Severity overview',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: DashboardScreen.textPrimary,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             '$total total temuan dianalisis',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: DashboardScreen.textMuted,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // mini legend column
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: const [
//                         _ChartLegendDot(
//                           color: DashboardScreen.blue,
//                           label: 'Good',
//                         ),
//                         SizedBox(height: 4),
//                         _ChartLegendDot(
//                           color: DashboardScreen.amber,
//                           label: 'Minor',
//                         ),
//                         SizedBox(height: 4),
//                         _ChartLegendDot(
//                           color: DashboardScreen.red,
//                           label: 'Major',
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // chart
//               SizedBox(
//                 height: 180,
//                 child: BarChart(
//                   BarChartData(
//                     maxY: _maxY,
//                     minY: 0,
//                     alignment: BarChartAlignment.spaceAround,
//                     barTouchData: BarTouchData(
//                       enabled: true,
//                       touchTooltipData: BarTouchTooltipData(
//                         tooltipBorderRadius: BorderRadius.circular(8),
//                         getTooltipColor: (_) => DashboardScreen.textPrimary,
//                         getTooltipItem: (group, _, rod, __) {
//                           const labels = ['Good', 'Minor', 'Major'];
//                           return BarTooltipItem(
//                             '${labels[group.x]}  ${rod.toY.toInt()}',
//                             const TextStyle(
//                               color: Colors.white,
//                               fontSize: 11,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     titlesData: FlTitlesData(
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 48,
//                           getTitlesWidget: (v, _) {
//                             final i = v.toInt();
//                             if (i < 0 || i > 2) return const SizedBox.shrink();
//                             final labels = ['Good', 'Minor', 'Major'];
//                             final pcts = [goodPct, minorPct, majorPct];
//                             final colors = [
//                               DashboardScreen.blue,
//                               DashboardScreen.amber,
//                               DashboardScreen.red,
//                             ];
//                             return Padding(
//                               padding: const EdgeInsets.only(top: 6),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     labels[i],
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.w700,
//                                       color: colors[i],
//                                     ),
//                                   ),
//                                   Text(
//                                     '${pcts[i]}%',
//                                     style: const TextStyle(
//                                       fontSize: 9,
//                                       color: DashboardScreen.textMuted,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 28,
//                           interval: 20,
//                           getTitlesWidget:
//                               (v, _) => Text(
//                                 v.toInt().toString(),
//                                 style: const TextStyle(
//                                   fontSize: 9,
//                                   color: DashboardScreen.textMuted,
//                                 ),
//                               ),
//                         ),
//                       ),
//                       topTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       rightTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                     ),
//                     gridData: FlGridData(
//                       show: true,
//                       drawVerticalLine: false,
//                       horizontalInterval: 20,
//                       getDrawingHorizontalLine:
//                           (_) => FlLine(
//                             color: DashboardScreen.borderLight,
//                             strokeWidth: 1,
//                             dashArray: [4, 4],
//                           ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     barGroups: [
//                       _bar(
//                         0,
//                         data.good.toDouble(),
//                         DashboardScreen.blue,
//                         DashboardScreen.blueLight,
//                       ),
//                       _bar(
//                         1,
//                         data.warning.toDouble(),
//                         DashboardScreen.amber,
//                         DashboardScreen.amberLight,
//                       ),
//                       _bar(
//                         2,
//                         data.critical.toDouble(),
//                         DashboardScreen.red,
//                         DashboardScreen.redLight,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 4),

//               // summary strip
//               Container(
//                 margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: DashboardScreen.pageBg,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _SummaryPill(
//                       value: '${data.good}',
//                       label: 'Good',
//                       color: DashboardScreen.blue,
//                       bg: DashboardScreen.blueLight,
//                     ),
//                     Container(
//                       width: 1,
//                       height: 24,
//                       color: DashboardScreen.border,
//                     ),
//                     _SummaryPill(
//                       value: '${data.warning}',
//                       label: 'Minor',
//                       color: DashboardScreen.amber,
//                       bg: DashboardScreen.amberLight,
//                     ),
//                     Container(
//                       width: 1,
//                       height: 24,
//                       color: DashboardScreen.border,
//                     ),
//                     _SummaryPill(
//                       value: '${data.critical}',
//                       label: 'Major',
//                       color: DashboardScreen.red,
//                       bg: DashboardScreen.redLight,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   BarChartGroupData _bar(int x, double y, Color fill, Color bgFill) {
//     return BarChartGroupData(
//       x: x,
//       barRods: [
//         BarChartRodData(
//           toY: y,
//           width: 36,
//           color: fill,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//           backDrawRodData: BackgroundBarChartRodData(
//             show: true,
//             toY: _maxY,
//             color: bgFill,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ChartLegendDot extends StatelessWidget {
//   const _ChartLegendDot({required this.color, required this.label});
//   final Color color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 6,
//           height: 6,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w600,
//             color: DashboardScreen.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _SummaryPill extends StatelessWidget {
//   const _SummaryPill({
//     required this.value,
//     required this.label,
//     required this.color,
//     required this.bg,
//   });
//   final String value, label;
//   final Color color, bg;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
//           decoration: BoxDecoration(
//             color: bg,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: color,
//             ),
//           ),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 10,
//             color: DashboardScreen.textMuted,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════
// // SHARED SMALL WIDGETS
// // ══════════════════════════════════════════════════════════════════════
// class _SectionTitle extends StatelessWidget {
//   const _SectionTitle(this.text);
//   final String text;

//   @override
//   Widget build(BuildContext context) => Text(
//     text.toUpperCase(),
//     style: const TextStyle(
//       fontSize: 10,
//       fontWeight: FontWeight.w700,
//       color: DashboardScreen.textMuted,
//       letterSpacing: .8,
//     ),
//   );
// }

// class _ErrorState extends StatelessWidget {
//   const _ErrorState({required this.message});
//   final String message;

//   @override
//   Widget build(BuildContext context) => Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(
//           Icons.cloud_off_rounded,
//           size: 48,
//           color: DashboardScreen.textMuted,
//         ),
//         const SizedBox(height: 12),
//         Text(
//           message,
//           style: const TextStyle(
//             fontSize: 13,
//             color: DashboardScreen.textSecondary,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     ),
//   );
// }

// // ══════════════════════════════════════════════════════════════════════
// // DONUT RING (CustomPainter — zero extra dependency)
// // ══════════════════════════════════════════════════════════════════════
// class _DonutRing extends StatelessWidget {
//   const _DonutRing({
//     required this.progress,
//     required this.label,
//     required this.size,
//     required this.strokeWidth,
//     required this.color,
//     required this.bgColor,
//   });

//   final double progress, size, strokeWidth;
//   final String label;
//   final Color color, bgColor;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           CustomPaint(
//             size: Size(size, size),
//             painter: _DonutPainter(
//               progress: progress.clamp(0.0, 1.0),
//               color: color,
//               bgColor: bgColor,
//               strokeWidth: strokeWidth,
//             ),
//           ),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//               color: DashboardScreen.textPrimary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DonutPainter extends CustomPainter {
//   _DonutPainter({
//     required this.progress,
//     required this.color,
//     required this.bgColor,
//     required this.strokeWidth,
//   });

//   final double progress, strokeWidth;
//   final Color color, bgColor;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = (size.width - strokeWidth) / 2;
//     final rect = Rect.fromCircle(center: center, radius: radius);

//     // track circle
//     canvas.drawArc(
//       rect,
//       0,
//       2 * math.pi,
//       false,
//       Paint()
//         ..color = bgColor
//         ..strokeWidth = strokeWidth
//         ..style = PaintingStyle.stroke,
//     );

//     // progress arc
//     if (progress > 0) {
//       canvas.drawArc(
//         rect,
//         -math.pi / 2,
//         2 * math.pi * progress,
//         false,
//         Paint()
//           ..color = color
//           ..strokeWidth = strokeWidth
//           ..style = PaintingStyle.stroke
//           ..strokeCap = StrokeCap.round,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(_DonutPainter old) =>
//       old.progress != progress || old.color != color;
// }

// ══════════════════════════════════════════════════════════════════════
// dashboard_screen.dart
// lib/samples/ui/rive_app/navigation/home/presentation/screen/
// ══════════════════════════════════════════════════════════════════════
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localizations/app_localizations.dart';
import '../../../auth/presentation/provider/user_provider.dart';
import '../../../inspeksi/entities/inspection_report.dart';
import '../../../list_inspeksi/presentation/provider/filter_provider.dart';
import '../provider/report_provider.dart';

// ══════════════════════════════════════════════════════════════════════
// COLOR TOKENS  (seirama dengan report_list_screen)
// ══════════════════════════════════════════════════════════════════════
class _C {
  // backgrounds
  static const pageBg = Color(0xFFECEDF5); // abu-abu lavender
  static const white = Color(0xFFFFFFFF); // card / button / komponen

  // neumorphic shadows
  static const shadowDark = Color(0xFFB4B8CC);
  static const shadowLight = Color(0xFFFFFFFF);

  // text
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7080);
  static const textMuted = Color(0xFF9CA3AF);

  // semantic
  static const blue = Color(0xFF2563EB);
  static const blueLight = Color(0xFFDBEAFE);
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const amber = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
}

// ── Shadow helpers (identical to report_list_screen) ─────────────────
List<BoxShadow> get _raised => [
  BoxShadow(
    color: _C.shadowDark.withValues(alpha: 0.42),
    offset: const Offset(4, 6),
    blurRadius: 14,
  ),
  BoxShadow(
    color: _C.shadowLight.withValues(alpha: 0.9),
    offset: const Offset(-2, -2),
    blurRadius: 6,
  ),
];

List<BoxShadow> get _card => [
  BoxShadow(
    color: _C.shadowDark.withValues(alpha: 0.22),
    offset: const Offset(4, 6),
    blurRadius: 16,
  ),
  BoxShadow(
    color: _C.shadowLight.withValues(alpha: 0.8),
    offset: const Offset(-1, -1),
    blurRadius: 4,
  ),
];

// ══════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _navigate({required WidgetRef ref, bool? status, Severity? severity}) {
    ref.read(selectedStatusFilterProvider.notifier).state = status;
    ref.read(selectedSeverityFilterProvider.notifier).state = severity;
    ref.read(navIndexProvider.notifier).state = 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlant = ref.watch(plantFilterProvider);
    final dashboardAsync = ref.watch(dashboardStatsProvider(selectedPlant));
    final user = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: _C.pageBg, // ← abu-abu neumorphic
          borderRadius: BorderRadius.circular(30),
        ),
        child: dashboardAsync.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(
                  color: _C.blue,
                  strokeWidth: 2,
                ),
              ),
          error: (err, _) => _ErrorState(message: err.toString()),
          data:
              (data) => RefreshIndicator(
                color: _C.blue,
                backgroundColor: _C.white,
                onRefresh:
                    () => ref.refresh(
                      dashboardStatsProvider(selectedPlant).future,
                    ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _Header(user: user)),
                    const SliverToBoxAdapter(child: _PlantDropdown()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _HeroCard(data: data, l10n: l10n),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _StatSection(
                          data: data,
                          l10n: l10n,
                          onTap:
                              (status, severity) => _navigate(
                                ref: ref,
                                status: status,
                                severity: severity,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _SeveritySection(
                          data: data,
                          l10n: l10n,
                          onTap:
                              (severity) =>
                                  _navigate(ref: ref, severity: severity),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _BarChartSection(data: data),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 1. HEADER
// ══════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({required this.user});
  final dynamic user;


  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'SELAMAT PAGI,';
    if (h < 15) return 'SELAMAT SIANG,';
    if (h < 18) return 'SELAMAT SORE,';
    return 'SELAMAT MALAM,';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14.0, left: 45.0),
                  child: Text(
                    _greeting,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.textMuted,
                      letterSpacing: .6,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 45.0),
                  child: Text(
                    user?.name as String? ?? 'Dashboard',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _C.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // notification bell — neumorphic button (white, raised)
          const SizedBox(width: 10),
          // avatar
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 2. PLANT DROPDOWN (animated expand — same pattern as report filter)
// ══════════════════════════════════════════════════════════════════════
class _PlantDropdown extends ConsumerStatefulWidget {
  const _PlantDropdown();

  @override
  ConsumerState<_PlantDropdown> createState() => _PlantDropdownState();
}

class _PlantDropdownState extends ConsumerState<_PlantDropdown>
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

  void _select(String plant) {
    ref.read(plantFilterProvider.notifier).state = plant;
    Future.delayed(const Duration(milliseconds: 140), _toggle);
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsMasterProvider);
    final selected = ref.watch(plantFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: plantsAsync.when(
        loading: () => const _DropdownShimmer(),
        error: (_, __) => const SizedBox.shrink(),
        data:
            (plants) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _C.white, // ← white komponen
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isOpen ? _card : _raised, // ← neumorphic shadow
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Trigger ──
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
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: _C.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LOKASI PLANT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textMuted,
                                    letterSpacing: .7,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  selected,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _C.textPrimary,
                                  ),
                                ),
                              ],
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
                                color: _C.pageBg, // ← pageBg inset
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: _C.shadowDark.withValues(alpha: 0.3),
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

                  // ── Expandable list ──
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
                                  plants
                                      .map(
                                        (p) => _DropdownItem(
                                          label: p,
                                          isActive: p == selected,
                                          onTap: () => _select(p),
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
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  const _DropdownItem({
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

class _DropdownShimmer extends StatelessWidget {
  const _DropdownShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _raised,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.pageBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 110,
            height: 12,
            decoration: BoxDecoration(
              color: _C.pageBg,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 3. HERO CARD
// ══════════════════════════════════════════════════════════════════════
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.l10n});
  final DashboardData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final pct =
        data.total > 0
            ? (data.complete / data.total * 100).toStringAsFixed(0)
            : '0';
    final progress =
        data.total > 0 ? (data.complete / data.total).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL INSPEKSI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.textMuted,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data.total}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: _C.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'laporan periode ini',
                        style: TextStyle(fontSize: 12, color: _C.textMuted),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _MiniLegend(
                            color: _C.blue,
                            label: '${data.complete} ${l10n.complete}',
                          ),
                          const SizedBox(width: 14),
                          _MiniLegend(
                            color: _C.amber,
                            label: '${data.incomplete} pending',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _DonutRing(
                  progress: progress,
                  label: '$pct%',
                  size: 90,
                  strokeWidth: 10,
                  color: _C.blue,
                  bgColor: _C.pageBg,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _C.pageBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(_C.blue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$pct% completion rate',
                  style: const TextStyle(fontSize: 11, color: _C.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLegend extends StatelessWidget {
  const _MiniLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _C.textSecondary),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 4. STAT 2×2 GRID
// ══════════════════════════════════════════════════════════════════════
class _StatSection extends StatelessWidget {
  const _StatSection({
    required this.data,
    required this.l10n,
    required this.onTap,
  });
  final DashboardData data;
  final AppLocalizations l10n;
  final void Function(bool? status, Severity? severity) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Ringkasan status'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                iconBg: _C.greenLight,
                iconColor: _C.green,
                value: '${data.complete}',
                label: l10n.complete,
                onTap: () => onTap(true, null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.timelapse_rounded,
                iconBg: _C.amberLight,
                iconColor: _C.amber,
                value: '${data.incomplete}',
                label: l10n.incomplete,
                onTap: () => onTap(false, null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.thumb_up_alt_outlined,
                iconBg: _C.blueLight,
                iconColor: _C.blue,
                value: '${data.good}',
                label: 'Good',
                onTap: () => onTap(null, Severity.good),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.warning_amber_rounded,
                iconBg: _C.redLight,
                iconColor: _C.red,
                value: '${data.critical}',
                label: 'Major',
                onTap: () => onTap(null, Severity.major),
              ),
            ),
          ],
        ),
      ],
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
    required this.onTap,
  });
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _raised,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: _C.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 5. SEVERITY BREAKDOWN
// ══════════════════════════════════════════════════════════════════════
class _SeveritySection extends StatelessWidget {
  const _SeveritySection({
    required this.data,
    required this.l10n,
    required this.onTap,
  });
  final DashboardData data;
  final AppLocalizations l10n;
  final void Function(Severity severity) onTap;

  @override
  Widget build(BuildContext context) {
    final total = data.good + data.warning + data.critical;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.issuesBySeverity),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _card,
          ),
          child: Column(
            children: [
              _SeverityRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Good',
                count: data.good,
                total: total,
                color: _C.blue,
                trackColor: _C.blueLight,
                isFirst: true,
                isLast: false,
                onTap: () => onTap(Severity.good),
              ),
              _SeverityRow(
                icon: Icons.warning_amber_rounded,
                label: 'Minor',
                count: data.warning,
                total: total,
                color: _C.amber,
                trackColor: _C.amberLight,
                isFirst: false,
                isLast: false,
                onTap: () => onTap(Severity.minor),
              ),
              _SeverityRow(
                icon: Icons.dangerous_outlined,
                label: 'Major',
                count: data.critical,
                total: total,
                color: _C.red,
                trackColor: _C.redLight,
                isFirst: false,
                isLast: true,
                onTap: () => onTap(Severity.major),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeverityRow extends StatelessWidget {
  const _SeverityRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.trackColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final int count, total;
  final Color color, trackColor;
  final bool isFirst, isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Column(
        children: [
          if (!isFirst) Divider(height: 1, color: _C.pageBg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '($pct%)',
                  style: const TextStyle(fontSize: 10, color: _C.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 6. BAR CHART
// ══════════════════════════════════════════════════════════════════════
class _BarChartSection extends StatelessWidget {
  const _BarChartSection({required this.data});
  final DashboardData data;

  static const double _maxY = 80;

  @override
  Widget build(BuildContext context) {
    final total = data.good + data.warning + data.critical;
    final goodPct =
        total > 0 ? (data.good / total * 100).toStringAsFixed(0) : '0';
    final minorPct =
        total > 0 ? (data.warning / total * 100).toStringAsFixed(0) : '0';
    final majorPct =
        total > 0 ? (data.critical / total * 100).toStringAsFixed(0) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Distribusi temuan'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Severity overview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$total total temuan dianalisis',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _C.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        _ChartLegendDot(color: _C.blue, label: 'Good'),
                        SizedBox(height: 4),
                        _ChartLegendDot(color: _C.amber, label: 'Minor'),
                        SizedBox(height: 4),
                        _ChartLegendDot(color: _C.red, label: 'Major'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: _maxY,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(8),
                        getTooltipColor: (_) => _C.textPrimary,
                        getTooltipItem: (group, _, rod, __) {
                          const labels = ['Good', 'Minor', 'Major'];
                          return BarTooltipItem(
                            '${labels[group.x]}  ${rod.toY.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i > 2) return const SizedBox.shrink();
                            final labels = ['Good', 'Minor', 'Major'];
                            final pcts = [goodPct, minorPct, majorPct];
                            final colors = [_C.blue, _C.amber, _C.red];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    labels[i],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors[i],
                                    ),
                                  ),
                                  Text(
                                    '${pcts[i]}%',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: _C.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 20,
                          getTitlesWidget:
                              (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _C.textMuted,
                                ),
                              ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine:
                          (_) => FlLine(
                            color: _C.pageBg,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _bar(0, data.good.toDouble(), _C.blue, _C.blueLight),
                      _bar(1, data.warning.toDouble(), _C.amber, _C.amberLight),
                      _bar(2, data.critical.toDouble(), _C.red, _C.redLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // summary strip
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _C.pageBg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _C.shadowDark.withValues(alpha: 0.2),
                      offset: const Offset(2, 2),
                      blurRadius: 6,
                    ),
                    const BoxShadow(
                      color: _C.shadowLight,
                      offset: Offset(-1, -1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryPill(
                      value: '${data.good}',
                      label: 'Good',
                      color: _C.blue,
                      bg: _C.blueLight,
                    ),
                    Container(width: 1, height: 24, color: _C.pageBg),
                    _SummaryPill(
                      value: '${data.warning}',
                      label: 'Minor',
                      color: _C.amber,
                      bg: _C.amberLight,
                    ),
                    Container(width: 1, height: 24, color: _C.pageBg),
                    _SummaryPill(
                      value: '${data.critical}',
                      label: 'Major',
                      color: _C.red,
                      bg: _C.redLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartGroupData _bar(int x, double y, Color fill, Color bgFill) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 36,
          color: fill,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: bgFill,
          ),
        ),
      ],
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _C.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });
  final String value, label;
  final Color color, bg;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: _C.textMuted)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: _C.textMuted,
      letterSpacing: .8,
    ),
  );
}

/// Reusable neumorphic raised button (white, box-shadow)
// ignore: unused_element
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
// DONUT RING
// ══════════════════════════════════════════════════════════════════════
class _DonutRing extends StatelessWidget {
  const _DonutRing({
    required this.progress,
    required this.label,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.bgColor,
  });
  final double progress, size, strokeWidth;
  final String label;
  final Color color, bgColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              progress: progress.clamp(0.0, 1.0),
              color: color,
              bgColor: bgColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });
  final double progress, strokeWidth;
  final Color color, bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.color != color;
}
