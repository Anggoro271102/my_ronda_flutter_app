import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/home/presentation/screen/dashboard_screen.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/inspeksi/presentation/screen/inspection_screen.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/list_inspeksi/presentation/screen/report_list_screen.dart';
// import 'package:flutter_samples/samples/ui/rive_app/navigation/my_list_inspeksi/presentation/screen/report_list_screen.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'dart:math' as math;
import 'package:flutter_samples/samples/ui/rive_app/navigation/custom_tab_bar.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/side_menu.dart';
import 'package:flutter_samples/samples/ui/rive_app/theme.dart';
import 'package:flutter_samples/samples/ui/rive_app/assets.dart' as app_assets;
import 'package:url_launcher/url_launcher.dart';

import 'navigation/auth/entities/user_model.dart';
import 'navigation/inspeksi/presentation/provider/inspection_provider.dart';
import 'navigation/list_inspeksi/presentation/provider/filter_provider.dart';
import 'on_boarding/onboarding_view.dart';

// Common Tab Scene for the tabs other than 1st one, showing only tab name in center
Widget commonTabScene(String tabName) {
  return Container(
    color: RiveAppTheme.background,
    alignment: Alignment.center,
    child: Text(
      tabName,
      style: const TextStyle(
        fontSize: 28,
        fontFamily: "Poppins",
        color: Colors.black,
      ),
    ),
  );
}

class RiveAppHome extends ConsumerStatefulWidget {
  const RiveAppHome({super.key, required this.user});
  final UserModel user;
  static const String route = '/course-rive';

  @override
  ConsumerState<RiveAppHome> createState() => _RiveAppHomeState();
}

class _RiveAppHomeState extends ConsumerState<RiveAppHome>
    with TickerProviderStateMixin {
  late AnimationController? _animationController;
  late AnimationController? _onBoardingAnimController;
  late Animation<double> _onBoardingAnim;
  late Animation<double> _sidebarAnim;

  SMIBool? _menuBtn;

  int _selectedTabIndex = 0;

  bool _showOnBoarding = false;
  Widget _tabBody = Container(color: RiveAppTheme.background);
  final List<Widget> _screens = [
    const DashboardScreen(),
    const InspectionScreen(),
    const ReportListScreen(),
    // const MyReportListScreen(),
    // commonTabScene("Search"),
    // commonTabScene("Timer"),
    // commonTabScene("Bell"),
    // commonTabScene("User"),
  ];

  final springDesc = const SpringDescription(
    mass: 0.1,
    stiffness: 40,
    damping: 5,
  );

  void _onMenuIconInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine",
    );
    artboard.addController(controller!);

    setState(() {
      _menuBtn = controller.findInput<bool>("isOpen") as SMIBool;
      _menuBtn?.value = true;
    });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  Future<void> _showExitWarningDialog(
    BuildContext context,
    VoidCallback onConfirm,
  ) async {
    return showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text("Laporan Belum Tersimpan"),
            content: const Text(
              "Pindah halaman akan menghapus data analisis ini. Lanjutkan keluar?",
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("Ya, Keluar"),
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  onConfirm(); // Jalankan callback pindah tab
                },
              ),
            ],
          ),
    );
  }

  Future<void> _launchWhatsApp() async {
    // Pesan otomatis agar user tidak perlu mengetik lagi di lapangan
    const String phoneNumber =
        "6285155048775"; // Ganti dengan nomor WhatsApp tujuan
    const String message =
        "Halo Admin, saya menemukan kendala saat menggunakan aplikasi. Mohon bantuannya.";

    final Uri url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint("Gagal membuka WhatsApp. Pastikan aplikasi terinstal.");
      }
    } catch (e) {
      debugPrint("Error saat membuka URL: $e");
    }
  }

  void _presentOnBoarding(bool show) {
    if (show) {
      setState(() {
        _showOnBoarding = true;
      });
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _onBoardingAnimController?.animateWith(springAnim);
    } else {
      _onBoardingAnimController?.reverse().whenComplete(
        () => {
          setState(() {
            _showOnBoarding = false;
          }),
        },
      );
    }
  }

  // void _changeTab(int index) {
  //   if (_selectedTabIndex != index) {
  //     setState(() {
  //       _selectedTabIndex = index;
  //       _tabBody = _screens[index];
  //     });
  //   }
  // }
  void _showExitInspectionDialog(BuildContext context, VoidCallback onConfirm) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text("Laporan Belum Tersimpan"),
            content: const Text(
              "Pindah halaman akan menghapus hasil analisis saat ini. Lanjutkan keluar?",
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Warna merah untuk aksi penghapusan
                child: const Text("Lanjutkan"),
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  onConfirm(); // Jalankan fungsi hapus data & pindah tab
                },
              ),
            ],
          ),
    );
  }

  void _changeTab(int index) async {
    // Gunakan ref.read untuk mendapatkan nilai instan tanpa mendengarkan terus-menerus
    final inspection = ref.read(inspectionStateProvider);
    debugPrint("LOG: Mencoba pindah ke tab $index dari $_selectedTabIndex");
    if (_selectedTabIndex == 1 &&
        index != 1 &&
        inspection.reportId != null &&
        !inspection.isFinalSubmitted) {
      // Pastikan dialog ini dipanggil dan ditunggu
      _showExitInspectionDialog(context, () async {
        // 1. Eksekusi hapus database
        debugPrint(
          "🧹 User konfirmasi: Menghapus draft ID ${inspection.reportId}",
        );
        await ref
            .read(inspectionStateProvider.notifier)
            .deleteReport(inspection.reportId!, isSilent: true);

        // 2. SETELAH API delete selesai, baru ubah tab
        if (mounted) {
          setState(() {
            _selectedTabIndex = index;
            _tabBody = _screens[index];
          });
          // Update provider navigasi agar Bottom Bar ikut bergeser
          ref.read(navIndexProvider.notifier).update((state) => index);
        }
      });
    } else {
      // Navigasi normal
      if (_selectedTabIndex != index && mounted) {
        setState(() {
          _selectedTabIndex = index;
          _tabBody = _screens[index];
        });
        ref.read(navIndexProvider.notifier).update((state) => index);
      }
    }
  }

  void onMenuPress() {
    // 1. Cek apakah menu button sudah terinisialisasi
    if (_menuBtn == null) return;

    if (_menuBtn!.value) {
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _animationController?.animateWith(springAnim);
    } else {
      _animationController?.reverse();
    }

    // 2. Ubah status Rive
    _menuBtn!.change(!_menuBtn!.value);

    // 3. Update Status Bar Android/iOS secara aman
    SystemChrome.setSystemUIOverlayStyle(
      _menuBtn!.value ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
    );
  }

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      upperBound: 1,
      vsync: this,
    );
    _onBoardingAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      upperBound: 1,
      vsync: this,
    );

    _sidebarAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.linear),
    );

    _onBoardingAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _onBoardingAnimController!, curve: Curves.linear),
    );

    _tabBody = _screens[0];
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _onBoardingAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(navIndexProvider, (previous, next) {
      if (_selectedTabIndex != next) {
        setState(() {
          _selectedTabIndex = next;
          _tabBody = _screens[next];
        });
      }
    });
    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        // <--- Bungkus area utama
        onHorizontalDragUpdate: (details) {
          // 1. Definisikan status menu secara aman (Null-Safety)
          // Jika _menuBtn null, kita asumsikan menu tertutup (value = true)
          final bool isCurrentlyOpen = !(_menuBtn?.value ?? true);

          // 2. LOGIKA SWIPE KIRI (MENUTUP)
          // Terjadi jika geser ke kiri (delta negatif) DAN menu sedang TERBUKA
          if (details.delta.dx < -10 && isCurrentlyOpen) {
            onMenuPress();
          }
          // 3. LOGIKA SWIPE KANAN (MEMBUKA)
          // Terjadi jika geser ke kanan (delta positif) DAN menu sedang TERTUTUP
          else if (details.delta.dx > 10 && !isCurrentlyOpen) {
            onMenuPress();
          }
        },
        child: Stack(
          children: [
            Positioned(child: Container(color: RiveAppTheme.background2)),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _sidebarAnim,
                builder: (BuildContext context, Widget? child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(
                            ((1 - _sidebarAnim.value) * -30) * math.pi / 180,
                          )
                          ..translate((1 - _sidebarAnim.value) * -300),
                    child: child,
                  );
                },
                child: FadeTransition(
                  opacity: _sidebarAnim,
                  child: SideMenu(
                    selectedIndex: _selectedTabIndex,
                    user: widget.user,
                    onTabClick: (index) {
                      _changeTab(index);
                      onMenuPress();
                    },
                    // // PERUBAHAN: Hubungkan aksi klik dari Sidebar
                    onProfileClick: () async {
                      onMenuPress(); // Tutup sidebar dulu
                      await Future.delayed(const Duration(milliseconds: 100));
                      _presentOnBoarding(
                        true,
                      ); // Tampilkan ProfileView/Onboarding
                    },
                    onWhatsAppClick: () {
                      _launchWhatsApp(); // Jalankan redirect URL ke wa.me
                    },
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _showOnBoarding ? _onBoardingAnim : _sidebarAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        1 -
                        (_showOnBoarding
                            ? _onBoardingAnim.value * 0.08
                            : _sidebarAnim.value * 0.1),
                    child: Transform.translate(
                      offset: Offset(_sidebarAnim.value * 265, 0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(
                                (_sidebarAnim.value * 30) * math.pi / 180,
                              ),
                        child: GestureDetector(
                          onTap: () {
                            // Mengecek status menu secara aman:
                            // Jika _menuBtn null, kita anggap menu sedang tertutup (true)
                            final bool isMenuOpen = !(_menuBtn?.value ?? true);

                            if (isMenuOpen) {
                              onMenuPress();
                            }
                          },
                          // --- INTEGRASI AbsorbPointer & AnimatedOpacity DENGAN NULL-SAFETY ---
                          child: Builder(
                            builder: (context) {
                              // Kita hitung status menu terbuka atau tidak
                              final bool isMenuOpen =
                                  !(_menuBtn?.value ?? true);

                              return AbsorbPointer(
                                // 'absorbing: true' akan mematikan semua klik pada konten dashboard
                                absorbing: isMenuOpen,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  // Jika menu terbuka, turunkan opasitas ke 0.8 agar terlihat redup
                                  opacity: isMenuOpen ? 0.8 : 1.0,
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: _tabBody,
              ),
            ),
            AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  right: (_sidebarAnim.value * -100) + 16,
                  child: child!,
                );
              },
              child: GestureDetector(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: RiveAppTheme.shadow.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_outline),
                  ),
                ),
                onTap: () {
                  _presentOnBoarding(true);
                },
              ),
            ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _sidebarAnim,
                builder: (context, child) {
                  return SafeArea(
                    child: Row(
                      children: [
                        // There's an issue/behaviour in flutter where translating the GestureDetector or any button
                        // doesn't translate the touch area, making the Widget unclickable, so instead setting a SizedBox
                        // in a Row to have a similar effect
                        SizedBox(width: _sidebarAnim.value * 216),
                        child!,
                      ],
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: onMenuPress,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(44 / 2),
                        boxShadow: [
                          BoxShadow(
                            color: RiveAppTheme.shadow.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: RiveAnimation.asset(
                        app_assets.menuButtonRiv,
                        stateMachines: const ["State Machine"],
                        animations: const ["open", "close"],
                        onInit: _onMenuIconInit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showOnBoarding)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _onBoardingAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        -(MediaQuery.of(context).size.height +
                                MediaQuery.of(context).padding.bottom) *
                            (1 - _onBoardingAnim.value),
                      ),
                      child: child!,
                    );
                  },
                  child: SafeArea(
                    top: false,
                    maintainBottomViewPadding: true,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 40),
                          ),
                        ],
                      ),
                      child: ProfileView(
                        user: widget.user, // // KIRIM DATA USER DI SINI
                        onClose: () {
                          // Menutup overlay profil
                          _presentOnBoarding(false);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            // White underlay behind the bottom tab bar
            IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: !_showOnBoarding ? _sidebarAnim : _onBoardingAnim,
                  builder: (context, child) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RiveAppTheme.background.withOpacity(0),
                            RiveAppTheme.background.withOpacity(
                              1 -
                                  (!_showOnBoarding
                                      ? _sidebarAnim.value
                                      : _onBoardingAnim.value),
                            ),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: AnimatedBuilder(
          animation: !_showOnBoarding ? _sidebarAnim : _onBoardingAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                !_showOnBoarding
                    ? _sidebarAnim.value * 300
                    : _onBoardingAnim.value * 200,
              ),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomTabBar(
                selectedIndex: _selectedTabIndex,
                onTabChange: (tabIndex) {
                  // ref.read(navIndexProvider.notifier).state = tabIndex;
                  _changeTab(tabIndex);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
