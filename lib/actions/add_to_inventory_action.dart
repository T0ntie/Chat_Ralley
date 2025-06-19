import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/engine/item.dart';
import 'package:aitrailsgo/gui/intents/new_item_intent.dart';
import 'package:aitrailsgo/gui/intents/ui_intent.dart';
import 'package:aitrailsgo/services/log_service.dart';
import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';

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
    log.i('🎬 NPC "${npc.name}" übergibt dem Spieler folgenden Gegenstand: "$itemId".');
    item.isOwned = true;
    item.isNew = true;
    super.jlog("${npc.name} übergibt dem Spieler folgenden Gegenstand: ${item.name}");
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