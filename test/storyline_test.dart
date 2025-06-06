import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_print

void main() {
  test('JSON-Datei ist inhaltlich konsistent', () async {
    final raw = await File('public/tibia/storyline.json').readAsString();
    final data = jsonDecode(raw);

    final knownInvokeActions = {
      'spawn',
      'follow',
      'talk',
      'reveal',
      'stopMoving',
      'walkTo',
      'behave',
      'saveGame',
      'showHotspot',
      'addToInventory',
      'appear',
      'notify',
      'scanToInventory',
      'stopTalking',
      'revealHotspot',
      'endGame',
      'leadAlong',
    };

    final knownTriggers = {
      'onInit',
      'onRestore',
      'onInteraction',
      'onSignal',
      'onHotspot',
      'onApproach',
      'onMessageCount',
    };

    final unknownActions = <String>{};
    final unknownTriggers = <String>{};
    final missingFields = <String, List<String>>{};

    for (final npc in data['npcs']) {
      final npcId = npc['id'] ?? '(unbekannt)';
      final actions = npc['actions'] ?? [];
      for (final action in actions) {
        final map = action as Map<String, dynamic>;

        final actionType = map['invokeAction'];
        if (actionType is! String || !knownInvokeActions.contains(actionType)) {
          unknownActions.add(actionType.toString());
        }

        for (final key in map.keys) {
          if (key.startsWith('on') && !knownTriggers.contains(key)) {
            unknownTriggers.add(key);
          }
        }

        // Beispiel: wenn "walkTo" verwendet wird, muss "position" da sein
        if (actionType == 'walkTo' && !map.containsKey('position')) {
          missingFields
              .putIfAbsent(npcId, () => [])
              .add('position fehlt bei walkTo');
        }

        if (actionType == 'showHotspot' && !map.containsKey('hotspot')) {
          missingFields
              .putIfAbsent(npcId, () => [])
              .add('hotspot fehlt bei showHotspot');
        }
      }
    }

    expect(
      unknownActions,
      isEmpty,
      reason: 'Unbekannte invokeAction-Typen: $unknownActions',
    );
    expect(
      unknownTriggers,
      isEmpty,
      reason: 'Unbekannte Trigger-Typen: $unknownTriggers',
    );
    expect(
      missingFields,
      isEmpty,
      reason: 'Pflichtfelder fehlen:\n${_formatMissing(missingFields)}',
    );

    print('✅ JSON validiert erfolgreich.');
  });

  test('Alle NPC-Prompt-Dateien existieren', () async {
    final raw = await File('public/tibia/storyline.json').readAsString();
    final data = jsonDecode(raw);

    final promptDir = Directory('public/tibia/prompts');
    final missingPrompts = <String>{};

    for (final npc in data['npcs']) {
      final prompt = npc['prompt'];
      if (prompt is String && prompt.trim().isNotEmpty) {
        final promptPath = File('${promptDir.path}/$prompt');
        if (!promptPath.existsSync()) {
          missingPrompts.add(prompt);
        }
      }
    }

    expect(
      missingPrompts,
      isEmpty,
      reason: 'Fehlende Prompt-Dateien:\n${missingPrompts.join('\n')}',
    );
    print('✅ Alle NPC-Prompt-Dateien vorhanden.');
  });

  test(
    'Alle in Actions referenzierten Hotspots sind im JSON definiert',
    () async {
      final raw = await File('public/tibia/storyline.json').readAsString();
      final json = jsonDecode(raw);

      // 1. Alle existierenden Hotspot-Namen sammeln
      final definedHotspots = <String>{
        for (final h in json['hotspots'] ?? []) h['id'],
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
        reason:
            '❌ Diese Hotspots werden verwendet, sind aber nicht im JSON definiert:\n${unknownHotspots.join('\n')}',
      );

      print('✅ Alle Hotspot-Referenzen stimmen mit der Definition überein.');
    },
  );

  test(
    'Alle in Conditions verwendeten Flags (mit und ohne Prefix) sind im JSON definiert',
    () async {
      final raw = await File('public/tibia/storyline.json').readAsString();
      final json = jsonDecode(raw);

      // 1. Definierte Flags aus dem JSON
      final definedFlags =
          (json['flags'] as Map<String, dynamic>?)?.keys.toSet() ?? {};

      // 2. Alle verwendeten Flags aus den Action-Conditions extrahieren
      final usedFlags = <String>{};

      for (final npc in json['npcs'] ?? []) {
        final actions = npc['actions'] as List? ?? [];
        for (final action in actions) {
          final conditions =
              action['conditions'] as Map<String, dynamic>? ?? {};
          for (final key in conditions.keys) {
            if (key.startsWith('flag:')) {
              usedFlags.add(key.substring(5).trim()); // → flag:xyz
            } else {
              // alles andere ignorieren
            }
          }
        }
      }

      // 3. Abgleich
      final undefinedFlags = usedFlags.difference(definedFlags);

      expect(
        undefinedFlags,
        isEmpty,
        reason:
            '❌ Diese Flags werden in Conditions verwendet, sind aber im JSON nicht definiert:\n${undefinedFlags.join('\n')}',
      );

      print('✅ Alle verwendeten Flags sind korrekt im JSON definiert.');
    },
  );

  test(
    'Alle in Conditions verwendeten Items (mit item:-Prefix) sind im JSON definiert',
    () async {
      final raw = await File('public/tibia/storyline.json').readAsString();
      final json = jsonDecode(raw);

      // 1. Definierte Items aus dem JSON
      final definedItems =
          (json['items'] as List?)
              ?.map((item) => item['id'] as String)
              .toSet() ??
          {};

      // 2. Alle verwendeten Items mit "item:"-Prefix in Conditions
      final usedItems = <String>{};

      for (final npc in json['npcs'] ?? []) {
        final actions = npc['actions'] as List? ?? [];
        for (final action in actions) {
          final conditions =
              action['conditions'] as Map<String, dynamic>? ?? {};
          for (final key in conditions.keys) {
            if (key.startsWith('item:')) {
              final itemId = key.substring(5).trim();
              usedItems.add(itemId);
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
    },
  );

  test('Alle Keys entsprechen der Whitelist', () async {
    final raw = await File('public/tibia/storyline.json').readAsString();
    final json = jsonDecode(raw);

    // Whitelist der gültigen Schlüssel
    final allowedKeys = <String>{
      'scenarioId',
      'title',
      'npcs',
      'hotspots',
      'items',
      'flags',
      'name',
      'position',
      'prompt',
      'image',
      'visible',
      'speed',
      'actions',
      'revealed',
      'icon',
      'owned',
      'useType',
      'targetNpc',
      'radius',
      'onInit',
      'onRestore',
      'onSignal',
      'onInteraction',
      'onHotspot',
      'onApproach',
      'invokeAction',
      'distance',
      'notification',
      'hotspot',
      'trigger',
      'conditions',
      'defer',
      'directive',
      'promptTag',
      'path',
      'item',
      'onMessageCount',
      'iconAsset',
      'id',
      'trailId',
      'creditsText',
      'creditsImage',
      'descriptiveName',
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

  test('Alle referenzierten Positionen sind in positions.json vorhanden', () async {
    final storylineRaw =
        await File('public/tibia/storyline.json').readAsString();
    final storyline = jsonDecode(storylineRaw);

    final positionsRaw =
        await File('public/tibia/positions.json').readAsString();
    final positions =
        (jsonDecode(positionsRaw)['positions'] as Map<String, dynamic>).keys
            .toSet();

    final usedPositions = <String>{};

    // 1. NPCs: prüfe npc["position"]
    for (final npc in storyline['npcs'] ?? []) {
      final pos = npc['position'];
      if (pos is String) {
        usedPositions.add(pos);
      }
    }

    // 2. Hotspots: prüfe hotspot["position"] (wenn nicht lat/lng direkt gesetzt)
    for (final hotspot in storyline['hotspots'] ?? []) {
      final pos = hotspot['position'];
      if (pos is String) {
        usedPositions.add(pos);
      }
    }

    // 3. Actions: prüfe action["position"]
    for (final npc in storyline['npcs'] ?? []) {
      for (final action in npc['actions'] ?? []) {
        final a = action as Map<String, dynamic>;
        final pos = a['position'];
        if (pos is String) {
          usedPositions.add(pos);
        }
      }
    }

    // Vergleich
    final unknownPositions = usedPositions.difference(positions);

    expect(
      unknownPositions,
      isEmpty,
      reason:
          '❌ Diese Positionen werden verwendet, sind aber nicht in positions.json definiert:\n${unknownPositions.join('\n')}',
    );

    print('✅ Alle verwendeten Positionen sind korrekt definiert.');
  });
}

String _formatMissing(Map<String, List<String>> map) {
  return map.entries
      .map((e) => '${e.key}:\n  - ${e.value.join('\n  - ')}')
      .join('\n');
}
