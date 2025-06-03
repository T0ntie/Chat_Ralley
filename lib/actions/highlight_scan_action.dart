import 'package:storytrail/gui/intents/highlight_scan_button_intent.dart';
import 'package:storytrail/gui/intents/ui_intent.dart';
import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class HighlightScanAction extends NpcAction {

  HighlightScanAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC "${npc.name}" weist auf den Scanbutton hin.');

    dispatchUIIntent(
      HighlightScanButtonIntent()
    );
    return true;
  }

  static HighlightScanAction actionFromJson(Map<String, dynamic> json) {
    final (
      trigger,
      conditions,
      notification,
      defer,
    ) = NpcAction.actionFieldsFromJson(json);
    return HighlightScanAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
    );
  }

  static void register() {
    NpcAction.registerAction(
      'highlightScan',
      HighlightScanAction.actionFromJson,
    );
  }
}