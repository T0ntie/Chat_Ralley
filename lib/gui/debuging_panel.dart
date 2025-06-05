import 'package:flutter/material.dart';
import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/item.dart';
import 'package:storytrail/engine/npc.dart';

class ActionTestingPanel extends StatefulWidget {
    final Map<String, List<(Npc, String, NpcAction)>> actionsByNpc;
  final Map<String, bool> flags;
  final List<Item> items;

  const ActionTestingPanel({
    super.key,
    required this.actionsByNpc,
    required this.flags,
    required this.items,
  });

  @override
  State<ActionTestingPanel> createState() => _ActionTestingPanelState();
}

class _ActionTestingPanelState extends State<ActionTestingPanel> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  ScrollController? _lastScrollController;
  bool _isExpanded = false;

  void _shrinkPanel() {
    _controller.animateTo(
      0.1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _lastScrollController?.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _shrinkPanel,
              onTapDown: (_) => _shrinkPanel(),
              onPanDown: (_) => _shrinkPanel(),
              onPanStart: (_) => _shrinkPanel(),
              onLongPress: _shrinkPanel,
              child: Container(color: Colors.transparent),
            ),
          ),
        NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            setState(() {
              _isExpanded = notification.extent > 0.11;
            });
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              _lastScrollController = scrollController;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade700,
                      Colors.blueGrey.shade900,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const Text(
                      "Registrierte Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.actionsByNpc.entries.map((entry) {
                      final npcId = entry.key;
                      final actions = entry.value;

                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          unselectedWidgetColor: Colors.white70,
                          iconTheme: const IconThemeData(color: Colors.white70),
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            GameEngine().getNpcById(npcId)?.name ?? "Unknown",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white70,
                          children:
                              actions.asMap().entries.map((actionEntry) {
                                final index = actionEntry.key;
                                final (npc, trigger, action) = actionEntry.value;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(
                                      (0.08 + (index.isEven ? 0.0 : 0.05) * 255)
                                          .toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    title: Text(
                                      "${trigger}${action.trigger.value != null ? ' (${action.trigger.value})' : ''}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "${action.runtimeType}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),

                                    trailing: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white70,
                                    ),
                                    onTap: () async => await action.invoke(npc),
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Text(
                      "Aktuelle Flags",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.flags.entries.map((entry) {
                      final flagName = entry.key;
                      final flagValue = entry.value;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.05 * 255).toInt()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            // Handle Tap
                            GameEngine().setFlag(flagName, !flagValue);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                flagName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
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
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    const Text(
                      "Aktuelle Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.items.map((item) {
                      final itemName = item.name;
                      final itemOwned = item.isOwned;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.05 * 255).toInt()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            // Handle Tap
                            item.isOwned = !item.isOwned;
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                itemName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                itemOwned ? "owned" : "not owned",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: itemOwned ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
