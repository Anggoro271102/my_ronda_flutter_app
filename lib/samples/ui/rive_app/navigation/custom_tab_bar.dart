import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter_samples/samples/ui/rive_app/models/tab_item.dart';
import 'package:flutter_samples/samples/ui/rive_app/theme.dart';
import 'package:flutter_samples/samples/ui/rive_app/assets.dart' as app_assets;
import 'package:url_launcher/url_launcher.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({
    super.key,
    required this.onTabChange,
    this.selectedIndex = 0,
  });

  final Function(int tabIndex) onTabChange;

  final int selectedIndex;
  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  final List<TabItem> _icons = TabItem.tabItemsList;

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
      "https://wa.me/6285155048775",
    ); // Ganti dengan nomor WA Mario
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  void _onRiveIconInit(Artboard artboard, index) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      _icons[index].stateMachine,
    );
    artboard.addController(controller!);

    _icons[index].status = controller.findInput<bool>("active") as SMIBool;
  }

  void onTabPress(int index) {
    // Gunakan widget.selectedIndex untuk pengecekan
    if (widget.selectedIndex != index) {
      widget.onTabChange(index);

      // Trigger animasi ikon Rive
      _icons[index].status!.change(true);
      Future.delayed(const Duration(seconds: 1), () {
        _icons[index].status!.change(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          // // PERUBAHAN: Row utama untuk memisahkan Bar Kiri dan Tombol Kanan
          children: [
            // --- BAR NAVIGASI KIRI (4 MENU) ---
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: RiveAppTheme.background2.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: RiveAppTheme.background2.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_icons.length, (index) {
                      TabItem icon = _icons[index];
                      return Expanded(
                        key: icon.id,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(12),
                          child: AnimatedOpacity(
                            // // PERUBAHAN: Gunakan widget.selectedIndex
                            opacity: widget.selectedIndex == index ? 1 : 0.5,
                            duration: const Duration(milliseconds: 200),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: -4,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 4,
                                    // // PERUBAHAN: Gunakan widget.selectedIndex
                                    width:
                                        widget.selectedIndex == index ? 20 : 0,
                                    decoration: BoxDecoration(
                                      color: RiveAppTheme.accentColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: RiveAnimation.asset(
                                    app_assets.iconsRiv,
                                    stateMachines: [icon.stateMachine],
                                    artboard: icon.artboard,
                                    onInit: (artboard) {
                                      _onRiveIconInit(artboard, index);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onPressed: () => onTabPress(index),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // const SizedBox(width: 12), // Jarak antara bar kiri dan tombol kanan
            // // --- TOMBOL WHATSAPP KANAN (TERPISAH) ---
            // // // PERUBAHAN: Tombol mandiri sesuai referensi gambar
            // Container(
            //   width: 60,
            //   height: 60,
            //   padding: const EdgeInsets.all(1),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(18),
            //     gradient: LinearGradient(
            //       colors: [
            //         Colors.white.withOpacity(0.5),
            //         Colors.white.withOpacity(0),
            //       ],
            //     ),
            //   ),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: RiveAppTheme.background2.withOpacity(0.8),
            //       borderRadius: BorderRadius.circular(18),
            //       boxShadow: [
            //         BoxShadow(
            //           color: RiveAppTheme.background2.withOpacity(0.3),
            //           blurRadius: 20,
            //           offset: const Offset(0, 20),
            //         ),
            //       ],
            //     ),
            //     child: CupertinoButton(
            //       padding: EdgeInsets.zero,
            //       onPressed: _launchWhatsApp,
            //       child: Icon(
            //         Icons.message, // Menggunakan ikon Material agar kontras
            //         color: Colors.greenAccent,
            //         size: 30,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
