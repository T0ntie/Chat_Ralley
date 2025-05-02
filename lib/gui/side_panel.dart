
import 'package:flutter/material.dart';

class SidePanel extends StatelessWidget{

  final bool isVisible;
  final  VoidCallback onClose;
  final List<Widget> children;

  const SidePanel({super.key, required this.isVisible, required this.onClose, required this.children});

  @override
  Widget build(BuildContext context)
  {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      top: MediaQuery.of(context).size.height / 2 - 100, // ca. zentriert
      right: isVisible ? 0 : -100, // rein/raus
      width: 80,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 900),
        opacity: isVisible ? 1.0 : 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
          child: Container(
            color: Colors.white.withAlpha((0.9 * 255).toInt()),
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...children,
                IconButton(
                  icon: Icon(Icons.close),
                  tooltip: "Schließen",
                  onPressed: onClose
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }

}