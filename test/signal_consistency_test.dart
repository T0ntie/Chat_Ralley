import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/story_line.dart';
import 'package:aitrailsgo/services/log_service.dart';

final RegExp signalTagPattern = RegExp(
  r'<npc-signal>\s*\{\s*"signal"\s*:\s*"([^"]+)"[\s\S]*?\}\s*</npc-signal>',
);

Set<String> extractSignalsFromPrompt(String text) {
  return signalTagPattern.allMatches(text).map((m) => m.group(1)!).toSet();
}

Set<String> extractSignalTriggersFromStoryLine(StoryLine storyline) {
  final signals = <String>{};

  for (final npc in storyline.npcs) {
    for (final action in npc.actions) {
      final trigger = action.trigger;
      if (trigger.type == TriggerType.signal && trigger.value is String) {
        signals.add(trigger.value as String);
      }
    }
  }

  return signals;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All prompt signals match scenario-defined onSignal values', () async {
    try {
      NpcAction.registerAllNpcActions();
      final storyline = await StoryLine.loadStoryLine("tibia");

      expect(storyline.trailId.isNotEmpty, isTrue);
      expect(storyline.title.isNotEmpty, isTrue);
      log.d('✅ Storyline geladen: ${storyline.title}');

      // Prompt-Dateien
      final promptFiles = [
        'assets/story/prompts/kroll-prompt.txt',
        'assets/story/prompts/knatterbach-prompt.txt',
        'assets/story/prompts/knöchelbein-prompt.txt',
        'assets/story/prompts/bozzi-prompt.txt',
        'assets/story/prompts/tschulli-prompt.txt',
      ];

      // Alle <npc-signal> aus den Prompts sammeln
      final Set<String> usedSignals = {};
      for (final path in promptFiles) {
        final text = await File(path).readAsString();
        usedSignals.addAll(extractSignalsFromPrompt(text));
      }

      // Alle onSignal-Triggers aus dem StoryLine-Objekt
      final definedSignals = extractSignalTriggersFromStoryLine(storyline);

      // Differenzen berechnen
      final undefinedSignals = usedSignals.difference(definedSignals);
      final unusedSignals = definedSignals.difference(usedSignals);

      expect(
        undefinedSignals,
        isEmpty,
        reason:
        '🚨 Diese Signale werden in Prompts verwendet, sind aber im JSON nicht definiert:\n$undefinedSignals',
      );

      expect(
        unusedSignals,
        isEmpty,
        reason:
        'ℹ️ Diese Signale sind im JSON definiert, werden aber in keinem Prompt verwendet:\n$unusedSignals',
      );

      log.d('✅ Signale überprüft');

    } catch (e, stack) {
      fail('❌ Fehler beim Laden der echten Storyline-Datei:\n$e\n$stack');
    }
  });
}
