import 'package:flutter/material.dart';
import 'package:hello_world/actions/npc_action.dart';
import '../engine/npc.dart';

class ActionTestingPanel extends StatefulWidget {
  final Map<String, List<(Npc, NpcAction)>> actionsByTrigger;
  final Map<String, bool> flags;

  const ActionTestingPanel({
    Key? key,
    required this.actionsByTrigger,
    required this.flags,
  }) : super(key: key);

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
                      Colors.blueGrey.shade900
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
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
                    ...widget.actionsByTrigger.entries.map((entry) {
                      final triggerName = entry.key;
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
                            triggerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white70,
                          children: actions
                              .asMap()
                              .entries
                              .map((actionEntry) {
                            final index = actionEntry.key;
                            final (npc, action) = actionEntry.value;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                    0.08 + (index.isEven ? 0.0 : 0.05)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                title: Text(
                                  "${npc.name} → ${action.runtimeType}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  "Trigger-Wert: ${action.trigger.value}",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                trailing: const Icon(
                                    Icons.play_arrow, color: Colors.white70),
                                onTap: () async => await action.invoke(npc),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
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
                            vertical: 2, horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              flagName,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
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
                    const SizedBox(height: 16),
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
