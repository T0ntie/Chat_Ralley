import 'package:flutter/material.dart';
import 'package:storytrail/engine/game_element.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/gui/items/item_call_backs.dart';
import 'package:storytrail/services/log_service.dart';

class Item with HasGameState {
  @override
  final String id;
  final String name;
  bool isOwned;
  bool isNew;
  bool isScannable;
  final String iconAsset;
  final String useType;
  final String npcId;

  Npc get npc {
    final npc = GameEngine().getNpcById(npcId);
    if (npc == null) {
      log.e('Npc "$npcId" für Item "$name" nicht gefunden.',  stackTrace: StackTrace.current);
      throw Exception('Npc "$npcId" for item "$name" not found.');
    }
    return npc;
  }

  Item({
    required this.id,
    required this.name,
    required this.isOwned,
    required this.isNew,
    required this.isScannable,
    required this.iconAsset,
    required this.useType,
    required this.npcId,
  }) {
    registerSelf();
  }

  static Item fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      isOwned: json['owned'] as bool? ?? false,
      isNew: json['new'] as bool? ?? false,
      isScannable: json['scannable'] as bool? ?? false,
      iconAsset: json['icon'],
      useType: json['useType'],
      npcId: json['targetNpc'],
    );
  }

  @override
  loadGameState(Map<String, dynamic> json) {
    isOwned = json['owned'];
    isNew = json['new'];
  }

  @override
  Map<String, dynamic> saveGameState() => {
    'id': id,
    'owned': isOwned,
    'new': isNew,
  };

  Future<void> execute(BuildContext context) async {
    final callback = ItemCallbacks.useCallbackMap[useType];
    if (callback != null) {
      await callback(context, this);
    } else {
      log.e('Kein Callback für ItemUseType "$useType" registriert.', stackTrace: StackTrace.current);
      throw Exception('No callback for ItemUseType "$useType" registered.');
    }
  }
}