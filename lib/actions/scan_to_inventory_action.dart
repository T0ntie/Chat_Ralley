import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/item.dart';
import 'package:storytrail/gui/open_qr_scan_dialog_intent.dart';
import 'package:storytrail/gui/ui_intent.dart';

import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class ScanToInventoryAction extends NpcAction {
  final String itemId;

  ScanToInventoryAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.itemId,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    Item? item = GameEngine().getItemById(itemId);
    if (item == null) {
      throw Exception("Item mit id: $itemId nicht gefunden.");
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
      itemId: json['item'],
    );
  }

  static void register() {
    NpcAction.registerAction(
      'scanToInventory',
      ScanToInventoryAction.actionFromJson,
    );
  }
}
