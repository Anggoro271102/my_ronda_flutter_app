import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter_samples/samples/ui/rive_app/components/menu_row.dart';
import 'package:flutter_samples/samples/ui/rive_app/models/menu_item.dart';
import 'package:flutter_samples/samples/ui/rive_app/theme.dart';
import 'package:flutter_samples/samples/ui/rive_app/assets.dart' as app_assets;

import '../core/localizations/app_localizations.dart';
import 'auth/entities/user_model.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({
    super.key,
    required this.onTabClick,
    required this.selectedIndex, // Parameter index aktif dari RiveAppHome
    required this.onProfileClick, // // PERUBAHAN: Callback untuk Profile
    required this.onWhatsAppClick, // // PERUBAHAN: Callback untuk WA
    required this.user,
  });

  final UserModel user;
  final Function(int index) onTabClick;
  final int selectedIndex;
  final VoidCallback onProfileClick;
  final VoidCallback onWhatsAppClick;

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  // final List<MenuItemModel> _browseMenuIcons = MenuItemModel.menuItems;
  // final List<MenuItemModel> _historyMenuIcons = MenuItemModel.menuItems2;
  final List<MenuItemModel> _themeMenuIcon = MenuItemModel.menuItems3;

  bool _isDarkMode = false;
  // // PERUBAHAN: Menambah variabel untuk history agar bisa diklik mandiri
  String _selectedHistoryLabel = "";

  void onThemeRiveIconInit(artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      _themeMenuIcon[0].riveIcon.stateMachine,
    );
    artboard.addController(controller!);
    _themeMenuIcon[0].riveIcon.status =
        controller.findInput<bool>("active") as SMIBool;
  }

  // // PERUBAHAN: Fungsi tekan menu disederhanakan
  void onMenuPress(int index) {
    widget.onTabClick(index);
  }

  void onThemeToggle(value) {
    setState(() {
      _isDarkMode = value;
    });
    _themeMenuIcon[0].riveIcon.status!.change(value);
  }

  @override
  Widget build(BuildContext context) {
    // // PERUBAHAN: Menentukan title menu aktif berdasarkan index dari parent
    final List<MenuItemModel> browseMenuIcons = MenuItemModel.getMenuItems(
      context,
    );
    final l10n = AppLocalizations.of(context)!;
    final String activeMenuTitle = browseMenuIcons[widget.selectedIndex].title;
    final List<MenuItemModel> secondaryMenu = MenuItemModel.getMenuItems2(
      context,
    );
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom - 60,
      ),
      constraints: const BoxConstraints(maxWidth: 288),
      decoration: BoxDecoration(
        color: RiveAppTheme.background2,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      widget.user.avatarUrl != null
                          ? NetworkImage(widget.user.avatarUrl!)
                          : null,
                  child:
                      widget.user.avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: "Inter",
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.role,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        fontFamily: "Inter",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // // PERUBAHAN: Mengirim activeMenuTitle agar highlight biru sinkron
                  _buildMenuSection(
                    l10n.browseMenu.toUpperCase(),
                    browseMenuIcons,
                    true,
                    activeMenuTitle,
                  ),
                  MenuButtonSection(
                    title: l10n.accountSupport.toUpperCase(),
                    selectedMenu: "",
                    menuIcons:
                        secondaryMenu, // Gunakan hasil dari fungsi getMenuItems2
                    onMenuPress: (menu) {
                      if (menu.title == AppLocalizations.of(context)!.profile) {
                        widget.onProfileClick();
                      } else if (menu.title == "WhatsApp") {
                        widget.onWhatsAppClick();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(20),
          //   child: Row(
          //     children: [
          //       SizedBox(
          //         width: 32,
          //         height: 32,
          //         child: Opacity(
          //           opacity: 0.6,
          //           child: RiveAnimation.asset(
          //             app_assets.iconsRiv,
          //             stateMachines: [_themeMenuIcon[0].riveIcon.stateMachine],
          //             artboard: _themeMenuIcon[0].riveIcon.artboard,
          //             onInit: onThemeRiveIconInit,
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 14),
          //       Expanded(
          //         child: Text(
          //           _themeMenuIcon[0].title,
          //           style: const TextStyle(
          //             color: Colors.white,
          //             fontSize: 17,
          //             fontFamily: "Inter",
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       ),
          //       CupertinoSwitch(value: _isDarkMode, onChanged: onThemeToggle),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // // PERUBAHAN: Menambahkan parameter currentSelected agar highlight berfungsi
  Widget _buildMenuSection(
    String title,
    List<MenuItemModel> items,
    bool isNavigable,
    String currentSelected,
  ) {
    return MenuButtonSection(
      title: title,
      selectedMenu: currentSelected, // Mengontrol background biru
      menuIcons: items,
      onMenuPress: (menu) {
        int index = items.indexOf(menu);
        if (isNavigable) {
          onMenuPress(index);
        } else {
          // Hanya update lokal untuk section non-navigasi (History)
          setState(() => _selectedHistoryLabel = menu.title);
        }
      },
    );
  }
}

class MenuButtonSection extends StatelessWidget {
  const MenuButtonSection({
    super.key,
    required this.title,
    required this.menuIcons,
    this.selectedMenu = "Home",
    this.onMenuPress,
  });

  final String title;
  final String selectedMenu;
  final List<MenuItemModel> menuIcons;
  final Function(MenuItemModel menu)? onMenuPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 40,
            bottom: 8,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              fontFamily: "Inter",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (var menu in menuIcons) ...[
                Divider(
                  color: Colors.white.withOpacity(0.1),
                  thickness: 1,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                MenuRow(
                  menu: menu,
                  selectedMenu: selectedMenu,
                  onMenuPress: () => onMenuPress!(menu),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
