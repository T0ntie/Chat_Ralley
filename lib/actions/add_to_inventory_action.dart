import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/item.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class AddToInventoryAction extends NpcAction {
  final String itemName;

  AddToInventoryAction({
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
    item.isOwned = true;
    item.isNew = true;
    log("${npc.name} hat dem Spieler folgenden Gegenstand gegeben: $itemName");
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
      itemName: json['item'],
    );
  }

  static void register() {
    NpcAction.registerAction(
      'addToInventory',
      AddToInventoryAction.actionFromJson,
    );
  }
}
