import 'package:flutter/material.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/gui/chat/radio_transmission_overlay.dart';
import 'package:storytrail/gui/chat/chat_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:storytrail/engine/conversation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storytrail/services/log_service.dart';

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
      onStatus: (status) => log.i("✅ STT Status: $status"),
      onError: (error) => log.e("❌ STT Fehler: $error"),
    );

    if (!available) {
      log.e('❌ Failed to initialize speech to text', stackTrace: StackTrace.current);
      setState(() => _speechReady = false);
    } else {
      log.i('✅ Speech-to-Text ist bereit.');
      setState(() => _speechReady = true);
    }
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      log.e('❌ Microphone access denied.', stackTrace: StackTrace.current);
    }
  }

  void _startListening() async {
    if (!_speechReady) {
      log.w("⚠️ STT hasn't been initialized.");
      return;
    }
    log.d("🎤 Start listening....");
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          log.d("🎤 ....result: ${result.recognizedWords}");
        });
      },
    );
  }

  void _stopListening() async {
    log.d("🎤 Stop listening.");
    await _speech.stop();
    setState(() => _isListening = false);
    _chatController.sendMessage?.call(_controller.text);
  }

  Widget _buildPushToTalkButton() {
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
