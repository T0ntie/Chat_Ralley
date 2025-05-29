import 'package:flutter/material.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/gui/chat/radio_transmission_overlay.dart';
import 'package:storytrail/gui/chat/chat_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:storytrail/engine/conversation.dart';
import 'package:permission_handler/permission_handler.dart';

class RadioChatPage extends StatefulWidget {
  final Npc npc;

  const RadioChatPage({super.key, required this.npc});

  @override
  State<RadioChatPage> createState() => _RadioChatPageState();
}

class _RadioChatPageState extends State<RadioChatPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechReady = false;
  final TextEditingController _controller = TextEditingController();
  final _chatController = ChatPageController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    await _requestMicPermission();

    bool available = await _speech.initialize(
      onStatus: (status) => print("📡 STT Status: $status"),
      onError: (error) => print("❗ STT Fehler: $error"),
    );

    if (!available) {
      print("❌ Speech-to-Text konnte nicht initialisiert werden.");
      setState(() => _speechReady = false);
    } else {
      print("✅ Speech-to-Text ist bereit.");
      setState(() => _speechReady = true);
    }
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("🎤 Mikrofon-Zugriff verweigert");
    }
  }

  void _startListening() async {
    if (!_speechReady) {
      print("⚠️ STT wurde nicht initialisiert. Abbruch.");
      return;
    }
    print("🎤 Start Listening...");
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          print("result: ${result.recognizedWords}");
        });
      },
    );
  }

  void _stopListening() async {
    print("stop talking");
    await _speech.stop();
    setState(() => _isListening = false);
    // Trigger Nachricht senden durch Simulation von Enter
    //FocusScope.of(context).unfocus();
    _chatController.sendMessage?.call(_controller.text);
    // Optional: Text senden über Callback
  }

  Widget _buildPushToTalkButton() {
    print("speechReady: $_speechReady");

    if (!_speechReady) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: _chatController.isSending,
      builder: (context, isSending, _) {
        final disabled = isSending;
        return Padding(
          padding: const EdgeInsets.only(bottom: 40.0, right: 20.0),
          child: GestureDetector(
            onLongPressStart: disabled ? null : (_) => _startListening(),
            onLongPressEnd: disabled ? null : (_) => _stopListening(),
            child: SizedBox(
              width: 80,
              height: 80,
              child: FloatingActionButton(
                backgroundColor: disabled ? Colors.grey : Colors.red,
                shape: const CircleBorder(),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 36,
                ),
                onPressed: () {},
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ChatPage(
          npc: widget.npc,
          medium: Medium.radio,
          externalController: _controller,
          floatingActionButton: _buildPushToTalkButton(),
          chatPageController: _chatController,
        ),
        if (_isListening)  RadioTransmissionOverlay(partialText:  _controller.text,),
      ],
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }
}
