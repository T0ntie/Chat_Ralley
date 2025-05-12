import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/item_qr_scan_dialog.dart';
import 'package:hello_world/main.dart';
import 'ui_intent.dart';

class OpenScanDialogIntent extends UIIntent {
  final String title;
  final String message;
  final Item expectedItem;

  OpenScanDialogIntent({
    required this.title,
    required this.message,
    required this.expectedItem
  });

  @override
  Future<void> call(BuildContext context) async {

    final result = await showDialog<String>(
      context: context,
      builder: (_) => ItemQRScanDialog(
        title: title,
        message: message,
        expectedQrCode: expectedItem.name,
      ),
    );
    print("ShowDialog ist fertig. Result: ${result}");

    if (result == expectedItem.name) {
      expectedItem.isOwned = true;
      print ("homPage: ${homePageKey.currentState}");
      homePageKey.currentState?.checkForNewItemsWithDelay();
    }

  }
}
