import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/item.dart';
import 'package:storytrail/gui/intents/new_item_intent.dart';
import 'package:storytrail/gui/intents/ui_intent.dart';
import 'package:storytrail/services/log_service.dart';
import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class AddToInventoryAction extends NpcAction {
  final String itemId;

  AddToInventoryAction({
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
      log.e('❌ no item with id "$itemId" found.', stackTrace: StackTrace.current);
      throw Exception('❌ no item with id "$itemId" found.');
    }
    log.i('🎬 NPC "${npc.name}" hat ein neues Item: "$itemId" bekommen.');
    item.isOwned = true;
    item.isNew = true;
    super.jlog("${npc.name} hat dem Spieler folgenden Gegenstand gegeben: ${item.name}");
    dispatchUIIntent(NewItemIntent());
    return item.isOwned;
  }

  static AddToInventoryAction actionFromJson(Map<String, dynamic> json) {
    final (
      trigger,
      conditions,
      notification,
      defer,
    ) = NpcAction.actionFieldsFromJson(json);
    return AddToInventoryAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      itemId: json['item'],
    );
  }

  static void register() {
    NpcAction.registerAction(
      'addToInventory',
      AddToInventoryAction.actionFromJson,
    );
  }
}