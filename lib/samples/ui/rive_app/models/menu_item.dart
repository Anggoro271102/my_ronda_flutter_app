import 'package:flutter/material.dart';
import 'package:flutter_samples/samples/ui/rive_app/models/tab_item.dart';

import '../core/localizations/app_localizations.dart';

class MenuItemModel {
  MenuItemModel({this.id, this.title = "", required this.riveIcon});

  UniqueKey? id = UniqueKey();
  String title;
  TabItem riveIcon;

  // // PERUBAHAN: Menyesuaikan dengan 4 Tab Utama di Bottom Bar
  static List<MenuItemModel> getMenuItems(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!; // Context sekarang tersedia di sini

    return [
      MenuItemModel(
        title: l10n.dashboard, // Mengambil "Dasbor" atau "Dashboard"
        riveIcon: TabItem(stateMachine: "HOME_Interactivity", artboard: "HOME"),
      ),
      MenuItemModel(
        title: l10n.inspection, // Mengambil "Inspeksi" atau "Inspection"
        riveIcon: TabItem(
          stateMachine: "SEARCH_Interactivity",
          artboard: "SEARCH",
        ),
      ),
      MenuItemModel(
        title: l10n.listReports, // Mengambil "Laporan" atau "Reports"
        riveIcon: TabItem(
          stateMachine: "TIMER_Interactivity",
          artboard: "TIMER",
        ),
      ),
    ];
  }

  static List<MenuItemModel> getMenuItems2(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      MenuItemModel(
        title:
            l10n.profile, // Menggunakan key 'accountDetails' untuk "Profil" atau "Profile"
        riveIcon: TabItem(stateMachine: "USER_Interactivity", artboard: "USER"),
      ),
      MenuItemModel(
        title:
            "WhatsApp", // Tetap statis karena nama brand biasanya tidak diterjemahkan
        riveIcon: TabItem(stateMachine: "CHAT_Interactivity", artboard: "CHAT"),
      ),
    ];
  }

  static List<MenuItemModel> menuItems3 = [
    MenuItemModel(
      title: "Dark Mode",
      riveIcon: TabItem(
        stateMachine: "SETTINGS_Interactivity",
        artboard: "SETTINGS",
      ),
    ),
  ];
}
