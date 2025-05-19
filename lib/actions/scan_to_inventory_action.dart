import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/open_qr_scan_dialog_intent.dart';
import 'package:hello_world/gui/ui_intent.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class ScanToInventoryAction extends NpcAction {
  final String itemName;

  ScanToInventoryAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.itemName,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    Item? item = GameEngine().getItemByName(itemName);
    if (item == null) {
      throw Exception("Item '$itemName nicht gefunden.");
    }

    dispatchUIIntent(
      OpenScanDialogIntent(
        title: "${npc.name} scharrt im Boden!",
        expectedItems: [item],
      ),
    );
    return(item.isOwned);
    //show QR Code here
  }

  static ScanToInventoryAction actionFromJson(Map<String, dynamic> json) {
    final (
      trigger,
      conditions,
      notification,
      defer,
    ) = NpcAction.actionFieldsFromJson(json);
    return ScanToInventoryAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      itemName: json['item'],
    );
  }

  static void register() {
    NpcAction.registerAction(
      'scanToInventory',
      ScanToInventoryAction.actionFromJson,
    );
  }
}
