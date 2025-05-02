import 'package:flutter/material.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/npc.dart';
import 'package:hello_world/gui/item-call-backs.dart';

class Item {
  final String name;
  bool isOwned;
  final String iconAsset;
  final String useType;
  final String npcName;

  Npc get npc {
    final npc = GameEngine().getNpcByName(npcName);
    if (npc == null) {
      throw Exception('Npc "$npcName" nicht gefunden.');
    }
    return npc;
  }

  Item({required this.name, required this.isOwned, required this.iconAsset, required this.useType, required this.npcName} );

  static Item fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      isOwned: json['owned'] as bool? ?? false,
      iconAsset: json['icon'],
      useType: json['useType'],
      npcName: json['targetNpc'],
    );
  }
  Future<void> execute(BuildContext context) async {
    final callback = ItemCallbacks.useCallbackMap[useType];
    if (callback != null) {
      await callback(context, this);
    } else {
      throw Exception('Kein Callback für ItemUseType "$useType" registriert.');
    }
  }
}
