import 'package:flutter/material.dart';
import 'package:hello_world/actions/npc_action.dart';
import 'package:hello_world/app_resources.dart';
import '../engine/npc.dart';

class ActionTestingPanel extends StatelessWidget {
  final Map<String, List<(Npc, NpcAction)>> actionsByTrigger;
  final Map <String, bool> flags;

  const ActionTestingPanel({Key? key, required this.actionsByTrigger, required this.flags})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Text(
                "Registrierte Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...actionsByTrigger.entries.map((entry) {
                final triggerName = entry.key;
                final actions = entry.value;

                return ExpansionTile(
                  title: Text(triggerName),
                  children:
                      actions.asMap().entries.map((actionEntry) {
                        final index = actionEntry.key;
                        final pair = actionEntry.value;
                        final npc = pair.$1;
                        final action = pair.$2;

                        final tileColor =
                            index.isEven
                                ? ResourceColors.tile(context).withAlpha((0.08*255).toInt())
                                : ResourceColors.tile(
                                  context,
                                ).withAlpha((0.16*255).toInt());

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            // wichtig, damit die Container-Farbe durchkommt
                            child: ListTile(
                              title: Text(
                                "${npc.name} → ${action.runtimeType}",
                              ),
                              subtitle: Text(
                                "Trigger-Wert: ${action.trigger.value}",
                              ),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: () => action.invoke(npc),
                              //tileColor: ResourceColors.tile(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // ripple folgt den Ecken
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              }).toList(),
              const Text(
                "Aktuelle Flags",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...flags.entries.map((entry) {
                final flagName = entry.key;
                final flagValue = entry.value;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        flagName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        flagValue ? "true" : "false",
                        style: TextStyle(
                          fontSize: 16,
                          color: flagValue ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
