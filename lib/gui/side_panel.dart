import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:storytrail/gui/items/glowing_animate_wrapper.dart';

class SidePanel extends StatelessWidget {
  final bool isVisible;
  final bool highlightScanButton;
  final VoidCallback onClose;
  final VoidCallback onScan;
  final List<Widget> children;

  const SidePanel({
    super.key,
    required this.isVisible,
    required this.highlightScanButton,
    required this.onClose,
    required this.onScan,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> itemSlotPlaceholders = List.generate(
      2,
      (_) => Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );

    return AnimatedAlign(
      alignment: Alignment.centerRight,
      duration: Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      child: AnimatedSlide(
        offset: isVisible ? Offset(0, 0) : Offset(1, 0),
        duration: Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
          child: Container(
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(-4, 4),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (children.isEmpty)
                      ...itemSlotPlaceholders
                    else
                      ...children.map(
                        (child) => Theme(
                          data: Theme.of(context).copyWith(
                            iconTheme: IconThemeData(color: Colors.white),
                          ),
                          child: child,
                        ),
                      ),

                    const Divider(
                      color: Colors.white54,
                      thickness: 1.5,
                      height: 20,
                      indent: 12,
                      endIndent: 8,
                    ),
                    GlowingAnimatedWrapper(
                      animate: highlightScanButton,
                      glowColor: Colors.orangeAccent,
                      child: IconButton(
                        icon: Icon(Icons.center_focus_strong_sharp, color: Colors.white),
                        tooltip: "Nach Items suchen",
                        onPressed: onScan,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      tooltip: "Schließen",
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
