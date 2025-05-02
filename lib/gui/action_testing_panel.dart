import 'package:flutter/material.dart';
import 'package:hello_world/actions/npc_action.dart';
import '../engine/npc.dart';

class ActionTestingPanel extends StatelessWidget {
  final Map<String, List<(Npc, NpcAction)>> actionsByTrigger;

  const ActionTestingPanel({Key? key, required this.actionsByTrigger}) : super(key: key);

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
                  children: actions.map((pair) {
                    final npc = pair.$1;
                    final action = pair.$2;

                    return ListTile(
                      title: Text("${npc.name} → ${action.runtimeType}"),
                      subtitle: Text("Trigger-Wert: ${action.trigger.value}"),
                      trailing: const Icon(Icons.play_arrow),
                      onTap: () => action.invoke(npc),
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
