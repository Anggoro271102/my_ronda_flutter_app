import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class TabItem {
  TabItem({this.stateMachine = "", this.artboard = "", this.status});

  UniqueKey? id = UniqueKey();
  String stateMachine;
  String artboard;
  // // PERUBAHAN: Field baru
  late SMIBool? status;

  // // PERUBAHAN: List dikurangi menjadi 4 item dengan nama artboard standar Rive Icons
  static List<TabItem> tabItemsList = [
    // Tab 1: Dashboard
    TabItem(stateMachine: "HOME_Interactivity", artboard: "HOME"),
    // Tab 2: New Inspection
    TabItem(stateMachine: "SEARCH_Interactivity", artboard: "SEARCH"),
    TabItem(stateMachine: "TIMER_Interactivity", artboard: "TIMER"),

    // Tab 3: All Reports (General)

    // Tab 4: My Reports (User Specific)
    // TabItem(stateMachine: "USER_Interactivity", artboard: "USER"),
  ];
}
