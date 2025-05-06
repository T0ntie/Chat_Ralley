import 'dart:ui';
import 'package:flutter/material.dart';

class SidePanel extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final List<Widget> children;

  const SidePanel({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
                    ...children.map(
                          (child) => Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: IconThemeData(color: Colors.white),
                        ),
                        child: child,
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
