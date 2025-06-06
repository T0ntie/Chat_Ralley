import 'package:flutter/material.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/services/firebase_serice.dart';
import 'package:storytrail/engine/story_journal.dart';
import 'package:storytrail/services/gpt_utilities.dart';
import 'package:storytrail/services/log_service.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key, this.onFatalError});

  final void Function(String error)? onFatalError;

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final ScrollController _scrollController = ScrollController();
  final double pixelsPerSecond = 50;

  String _creditsText ="Game Over";

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
    _loadStoryAndStartScrolling();
  }

  Future<void> _loadStoryAndStartScrolling() async {
    log.d("🟡 Lade-Credits gestartet");

    String credits = "";
    try {
      credits = await FirebaseHosting.loadStringFromUrl(GameEngine().creditsTextPath());
      log.d("✅ Credits-Text geladen");
    } catch (e) {
      widget.onFatalError?.call("Failed to load credits from ${GameEngine().creditsTextPath()}: $e");
    }

    try {
      final story = await GptUtilities.buildCreditsStory(StoryJournal().toStory());
      credits = '$credits\n$story';
      log.d("✅ Story generiert");
    } catch (e) {
      widget.onFatalError?.call("Failed to build credits story: $e");
    }

    if (!mounted) return;
    setState(() {
      _creditsText = credits;
    });

    //WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted) return;
    final scrollableHeight = _scrollController.position.maxScrollExtent;
    //final screenHeight = MediaQuery.of(context).size.height;

    // ⏱️ Rechne zusätzliche Scrollhöhe für "ganz raus scrollen"
    final pixelsToScroll = scrollableHeight;
    final duration = Duration(
      milliseconds: (pixelsToScroll / pixelsPerSecond * 1000).round(),
    );

    if (_scrollController.hasClients) {
      _scrollController
          .animateTo(scrollableHeight, duration: duration, curve: Curves.linear)
          .then((_) {
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
          //Image.asset('assets/logo/credits.png', fit: BoxFit.cover),
          FirebaseHosting.loadImageWidget(GameEngine().creditsImagePath(), fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha((0.5 * 255).round())),
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
