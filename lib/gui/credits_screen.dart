
import 'package:flutter/material.dart';
import '../engine/story_journal.dart';
import '../services/gpt_utilities.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final ScrollController _scrollController = ScrollController();
  final double pixelsPerSecond = 50;

  String _story = "";
  final String _creditsText = '''
Herzliche Gratulation !!

Du hast den Fall gelöst den Knochen gefunden und Knöcherich Beißbert ist wieder hergestellt!

Hier folgt deine Geschichte: 
''';

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
    _loadStoryAndStartScrolling();
  }

  Future<void> _loadStoryAndStartScrolling() async{
    final story = await GptUtilities.buildCreditsStory(StoryJournal().toStory());
    if (!mounted) return;
    setState(() {
      _story = story;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
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
          Container(color: Colors.black.withAlpha((0.5 * 255).toInt())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: IgnorePointer(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight),
                    Text(
                      "$_creditsText $_story",
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
