import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/item.dart';
import 'package:storytrail/gui/intents/open_qr_scan_dialog_intent.dart';
import 'package:storytrail/gui/intents/ui_intent.dart';

import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

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
    log.i('🎬 NPC "${npc.name}" hat ein Item ("$itemId") zum Scannen gefunden.');
    Item? item = GameEngine().getItemById(itemId);
    if (item == null) {
      log.e('❌ Item with id: "$itemId" not found.');
      assert(false, '❌ Item with id: "$itemId" not found.');
      return false;
    }

    dispatchUIIntent(
      OpenScanDialogIntent(
        title: "${npc.name} scharrt im Boden!",
        expectedItems: [item],
      ),
    );
    return(item.isOwned);
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