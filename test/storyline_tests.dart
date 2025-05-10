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
}
