import 'package:flutter/material.dart';
import '../engine/item.dart';
import '../engine/story_journal.dart';
import '../gui/item_qr_scan_dialog.dart';
import '../main.dart';
import 'ui_intent.dart';

class OpenScanDialogIntent extends UIIntent {
  final String title;
  final String message;
  static const defaultMessage =
      "Entdecke den Gegenstand – QR-Code scannen, um ihn zu bergen";
  final List<Item> expectedItems;

  List<String> get expectedItemNames =>
      expectedItems.map((item) => item.name).toList();

  OpenScanDialogIntent({
    required this.title,
    String? message,
    required this.expectedItems,
  }) : message = message ?? defaultMessage;

  @override
  Future<void> call(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (_) => ItemQRScanDialog(
            title: title,
            message: message,
            expectedQrCodes: expectedItemNames,
          ),
    );
    print("ShowDialog ist fertig. Result: $result");

    bool exists = expectedItems.any((item) => item.name == result);

    if (exists) {
      Item selectedItem = expectedItems.firstWhere(
        (item) => item.name == result,
      );
      selectedItem.isOwned = true;
      selectedItem.isNew = true;
      StoryJournal().logAction(
        "Spieler hat folgenden Gegenstand gefunden: ${selectedItem.name}",
      );
      print("homPage: ${homePageKey.currentState}");
      homePageKey.currentState?.checkForNewItemsWithDelay();
    }
  }
}
