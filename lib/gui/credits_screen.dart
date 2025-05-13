import 'package:flutter/material.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final ScrollController _scrollController = ScrollController();
  final double pixelsPerSecond = 50;

  final String _creditsText = '''
StoryTrail präsentiert

Der Fall der verschwundenen Tibia

Ein interaktives Abenteuer von:
Max Mustermann
Erika Beispiel
Lara Langtext
...

Spezialdank an:
Die Geduldigen Tester
Kaffee und Mate

© 2025 StoryTrail
Alle Rechte vorbehalten.
''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!mounted) return;
    final scrollableHeight = _scrollController.position.maxScrollExtent;
    final screenHeight = MediaQuery.of(context).size.height;

    // ⏱️ Rechne zusätzliche Scrollhöhe für "ganz raus scrollen"
    final pixelsToScroll = scrollableHeight;
    final duration = Duration(
      milliseconds: (pixelsToScroll / pixelsPerSecond * 1000).round(),
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollableHeight,
        duration: duration,
        curve: Curves.linear,
      ).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/logo/credits.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: IgnorePointer(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight),
                    Text(
                      _creditsText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.8,
                        fontFamily: 'Times New Roman',
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Überspringen",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
