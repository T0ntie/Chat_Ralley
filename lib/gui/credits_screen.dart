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

  String _creditsBase = 'Game Over.';
  String _creditsStory = '';
  bool _gptDone = false;
  bool _showLoader = false;

  final ScrollController _scrollController = ScrollController();
  final double pixelsPerSecond = 30;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBaseCredits(); // async Funktion
    });
  }

  Future<void> _loadBaseCredits() async {
    log.d("🟡 Lade-Credits gestartet");

    try {
      _creditsBase = await FirebaseHosting.loadStringFromUrl(GameEngine().creditsTextPath());
      log.d("✅ Credits-Text geladen");

    } catch (e) {
      widget.onFatalError?.call("Failed to load credits from ${GameEngine().creditsTextPath()}: $e");
      return;
    }

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToUpperThird());

    // GPT laden nebenbei starten
    _loadGptStory();
  }

  bool _firstScrollDone = false;


  Future<void> _loadGptStory() async {
    setState(() {
      _showLoader = true;
    });

    try {
      log.d("🟡 Lasse die Story von GPT generieren");
      final story = await GptUtilities.buildCreditsStory(StoryJournal().toStory());
      log.d("✅ Story von GPT generiert");
      _creditsStory = story;
      _gptDone = true;
    } catch (e) {
      widget.onFatalError?.call("Failed to build credits story by GPT: $e");
      return;
    }

    setState(() {
      _showLoader = false;
    });

    if (_firstScrollDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGptOnly());
    }
  }



  void _scrollToUpperThird() {
    if (!_scrollController.hasClients) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final stopAt = screenHeight * (2 / 3); // credits.txt erscheint im oberen Drittel

    _scrollController
        .animateTo(
      stopAt,
      duration: Duration(
        milliseconds: (stopAt / pixelsPerSecond * 1000).round(),
      ),
      curve: Curves.linear,
    )
        .then((_) {
      setState(() {
        _firstScrollDone = true;
        if (!_gptDone) {
          _showLoader = true;
        }
      });

      if (_gptDone) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGptOnly());
      }
    });
  }

  void _scrollStoryToTop() {
    if (!_scrollController.hasClients) return;

    final totalHeight = _scrollController.position.maxScrollExtent;
    final duration = Duration(
      milliseconds: (totalHeight / pixelsPerSecond * 1000).round(),
    );

    _scrollController
        .animateTo(totalHeight,
        duration: duration,
        curve: Curves.linear)
        .then((_) => Navigator.of(context).pop());
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
                      _creditsBase,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.8,
                        fontFamily: 'Times New Roman',
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_showLoader) ...[
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 200),
                    ],
                    if (_gptDone) ...[
                      SizedBox(height: 40),
                      Text(
                        _creditsStory,
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
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Überspringen"),
            ),
          ),        ],
      ),
    );
  }

  void _scrollGptOnly() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final fullExtent = _scrollController.position.maxScrollExtent;

    final remainingScroll = fullExtent - currentOffset;

    if (remainingScroll <= 0) {
      Navigator.of(context).pop(); // schon ganz unten
      return;
    }

    final duration = Duration(
      milliseconds: (remainingScroll / pixelsPerSecond * 1000).round(),
    );

    _scrollController
        .animateTo(
      fullExtent,
      duration: duration,
      curve: Curves.linear,
    )
        .then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }
}
