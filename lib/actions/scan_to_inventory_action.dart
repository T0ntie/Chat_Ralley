import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/engine/item.dart';
import 'package:aitrailsgo/gui/intents/open_qr_scan_dialog_intent.dart';
import 'package:aitrailsgo/gui/intents/ui_intent.dart';

import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

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