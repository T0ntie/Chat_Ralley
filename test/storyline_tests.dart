import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/actions/npc_action.dart';
import 'package:hello_world/engine/story_line.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses real storyline.json without throwing', () async {
    try {
      NpcAction.registerAllNpcActions();
      final storyline = await StoryLine.loadStoryLine();

      expect(storyline.scenarioId.isNotEmpty, isTrue);
      expect(storyline.title.isNotEmpty, isTrue);
      print('✅ Storyline geladen: ${storyline.title}');
    } catch (e, stack) {
      fail('❌ Fehler beim Laden der echten Storyline-Datei:\n$e\n$stack');
    }
  });

  test('Alle invokeAction-Typen im JSON sind gültig', () async {
    final raw = await File('assets/story/storyline.json').readAsString();
    final json = jsonDecode(raw);

    final unknownActions = <String>{};
    final unknownTriggers = <String>{};

    final actions = (json['npcs'] as List)
        .map((npc) => npc['actions'] ?? [])
        .expand((a) => a)
        .cast<Map<String, dynamic>>();

    for (final action in actions) {
      final actionType = action['invokeAction'];
      if (actionType is String && !NpcAction.actionRegistryForTest.containsKey(actionType)) {
        unknownActions.add(actionType);
      }

      for (final key in action.keys) {
        if (key.startsWith('on') && !NpcActionTrigger.stringToTriggerTypeForTest.containsKey(key)) {
          unknownTriggers.add(key);
        }
      }
    }

    expect(unknownActions, isEmpty, reason: 'Unbekannte invokeAction-Typen:\n$unknownActions');
    expect(unknownTriggers, isEmpty, reason: 'Unbekannte Trigger-Typen:\n$unknownTriggers');
    print('✅ Alle Actions überprüft');
  });

  test('Alle in storyline referenzierten Prompt-Dateien existieren', () async {
    final storyline = await StoryLine.loadStoryLine();
    final missingFiles = <String>[];

    for (final npc in storyline.npcs) {
      final ppath = 'assets/story/prompts/${npc.prompt.promptFile}';
      if (!await File(ppath).exists()) {
        missingFiles.add(ppath);
      }
      final ipath = 'assets/story/${npc.imageAsset}';
      if (!await File(ipath).exists()) {
        missingFiles.add(ipath);
      }
    }

    expect(missingFiles, isEmpty,
        reason: 'Fehlende NPC-Dateien:\n${missingFiles.join('\n')}');
    print('✅ Alle Prompt-Dateien existieren');
  });

  test('Alle in Actions referenzierten Hotspots sind im JSON definiert', () async {
    final raw = await File('assets/story/storyline.json').readAsString();
    final json = jsonDecode(raw);

    // 1. Alle existierenden Hotspot-Namen sammeln
    final definedHotspots = <String>{
      for (final h in json['hotspots'] ?? []) h['name']
    };

    // 2. Alle verwendeten Hotspot-Namen in Actions finden
    final usedHotspots = <String>{};

    for (final npc in json['npcs'] ?? []) {
      final actions = npc['actions'] as List? ?? [];
      for (final action in actions) {
        if (action.containsKey('onHotspot')) {
          final h = action['onHotspot'];
          if (h is String) usedHotspots.add(h);
        }
        if (action.containsKey('hotspot')) {
          final h = action['hotspot'];
          if (h is String) usedHotspots.add(h);
        }
      }
    }

    // 3. Vergleich
    final unknownHotspots = usedHotspots.difference(definedHotspots);

    expect(
      unknownHotspots,
      isEmpty,
      reason: '❌ Diese Hotspots werden verwendet, sind aber nicht im JSON definiert:\n${unknownHotspots.join('\n')}',
    );

    print('✅ Alle Hotspot-Referenzen stimmen mit der Definition überein.');
  });

  test('Alle in Conditions verwendeten Flags (mit und ohne Prefix) sind im JSON definiert', () async {
    final raw = await File('assets/story/storyline.json').readAsString();
    final json = jsonDecode(raw);

    // 1. Definierte Flags aus dem JSON
    final definedFlags = (json['flags'] as Map<String, dynamic>?)?.keys.toSet() ?? {};

    // 2. Alle verwendeten Flags aus den Action-Conditions extrahieren
    final usedFlags = <String>{};

    for (final npc in json['npcs'] ?? []) {
      final actions = npc['actions'] as List? ?? [];
      for (final action in actions) {
        final conditions = action['conditions'] as Map<String, dynamic>? ?? {};
        for (final key in conditions.keys) {
          if (key.startsWith('flag:')) {
            usedFlags.add(key.substring(5).trim()); // → flag:xyz
          } else if (key.startsWith('item:')) {
            // Items ignorieren
          } else {
            usedFlags.add(key.trim()); // → xyz ohne Prefix = auch ein Flag
          }
        }
      }
    }

    // 3. Abgleich
    final undefinedFlags = usedFlags.difference(definedFlags);

    expect(
      undefinedFlags,
      isEmpty,
      reason: '❌ Diese Flags werden in Conditions verwendet, sind aber im JSON nicht definiert:\n${undefinedFlags.join('\n')}',
    );

    print('✅ Alle verwendeten Flags sind korrekt im JSON definiert.');
  });

  test('Alle in Conditions verwendeten Items (mit item:-Prefix) sind im JSON definiert', () async {
    final raw = await File('assets/story/storyline.json').readAsString();
    final json = jsonDecode(raw);

    // 1. Definierte Items aus dem JSON
    final definedItems = (json['items'] as List?)
        ?.map((item) => item['name'] as String)
        .toSet() ??
        {};

    // 2. Alle verwendeten Items mit "item:"-Prefix in Conditions
    final usedItems = <String>{};

    for (final npc in json['npcs'] ?? []) {
      final actions = npc['actions'] as List? ?? [];
      for (final action in actions) {
        final conditions = action['conditions'] as Map<String, dynamic>? ?? {};
        for (final key in conditions.keys) {
          if (key.startsWith('item:')) {
            final itemName = key.substring(5).trim();
            usedItems.add(itemName);
          }
        }
      }
    }

    // 3. Abgleich
    final undefinedItems = usedItems.difference(definedItems);

    expect(
      undefinedItems,
      isEmpty,
      reason:
      '❌ Diese Items werden in Conditions verwendet, sind aber im JSON nicht definiert:\n${undefinedItems.join('\n')}',
    );

    print('✅ Alle verwendeten Items sind korrekt im JSON definiert.');
  });

  test('Alle JSON-Schlüssel entsprechen der Whitelist gültiger Schlüssel', () async {
    final raw = await File('assets/story/storyline.json').readAsString();
    final json = jsonDecode(raw);

    // Whitelist der gültigen Schlüssel
    final allowedKeys = <String>{
      'scenarioId', 'title', 'npcs', 'hotspots', 'items', 'flags',
      'name', 'position', 'prompt', 'image', 'visible', 'speed', 'actions',
      'revealed', 'icon', 'owned', 'useType', 'targetNpc', 'radius',
      'onInit', 'onSignal', 'onInteraction', 'onHotspot', 'onApproach',
      'invokeAction', 'distance', 'notification', 'hotspot', 'trigger',
      'conditions', 'defer', 'directive', 'promptTag', 'path',
      'item', 'onMessageCount', 'iconAsset'
    };

    final invalidKeys = <String>[]; // <-- HIER wird sie deklariert
    final ignoredParentKeys = {'conditions', 'flags', 'position'};

    void checkKeys(dynamic node, [String path = '']) {
      if (node is Map) {
        for (final entry in node.entries) {
          final key = entry.key;
          final fullPath = path.isEmpty ? key : '$path.$key';

          final parentKey = path.split('.').lastOrNull ?? '';
          final shouldCheck = !ignoredParentKeys.contains(parentKey);

          if (shouldCheck && !allowedKeys.contains(key)) {
            invalidKeys.add(fullPath);
          }

          checkKeys(entry.value, fullPath);
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          checkKeys(node[i], '$path[$i]');
        }
      }
    }

    checkKeys(json);

    expect(
      invalidKeys,
      isEmpty,
      reason: '❌ Ungültige JSON-Schlüssel gefunden:\n${invalidKeys.join('\n')}',
    );

    print('✅ Alle JSON-Schlüssel sind gültig.');
  });

}
