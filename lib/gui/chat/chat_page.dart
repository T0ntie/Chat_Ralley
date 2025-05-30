import 'package:flutter/material.dart';
import 'package:storytrail/services/firebase_serice.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/gui/chat/chat_gui_elements.dart';
import 'package:storytrail/gui/notification_services.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/engine/conversation.dart';

class ChatPage extends StatefulWidget {
  final Npc npc;
  final Medium medium;
  final Widget? floatingActionButton; // Walkie-Talkie-Push-To-Talk Button
  final TextEditingController? externalController;
  final ChatPageController? chatPageController;

  const ChatPage({
    super.key,
    required this.npc,
    this.medium = Medium.chat,
    this.floatingActionButton,
    this.externalController,
    this.chatPageController,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Conversation _conversation;
  late final TextEditingController _controller;

  final ScrollController _scrollController = ScrollController();

  bool get isRadio => widget.medium == Medium.radio;

  Medium get medium => widget.medium;

  @override
  void initState() {
    super.initState();
    _controller = widget.externalController ?? TextEditingController();
    widget.chatPageController?.sendMessage = sendMessage;
    _conversation = widget.npc.currentConversation;
    _conversation.onConversationFinished = _closeChatAfterDelay;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await GameEngine().registerInteraction(widget.npc);
      widget.npc.hasInteracted = true;
      _handleTriggers();
      widget.npc.hasSomethingToSay = false;
    });
  }

  Future<void> _closeChatAfterDelay() async {
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      //Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _handleTriggers() async {
    setState(() {
      _isSending = true;
    });

    await _conversation.handleTriggerMessage();

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });
  }

  bool _isSending = false;

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _conversation.addUserMessage(text, medium);
      _isSending = true;
      widget.chatPageController?.isSending.value = true;
    });

    try {
      String response = await _conversation.processConversation();

      if (!mounted) return;

      setState(() {
        _conversation.addAssistantMessage(response, medium);
      });
    } catch (e, stackTrace) {
      SnackBarService.showErrorSnackBar(
        context,
        '❌ Kommunikation mit Chat GPT fehlgeschlagen.',
      );
      print("Exception occured: $e : \n$stackTrace ");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          widget.chatPageController?.isSending.value = false;
        });
        _controller.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation.getVisibleMessages(medium);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 4,
        foregroundColor: Colors.white,
        title:
            isRadio
                ? Row(
                  children: [
                    SizedBox(width: 8),
                    Text(
                      "Walkie Talkie",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                : Text(
                  widget.npc.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child:
                    isRadio
                        ? Image.asset(
                          'assets/story/images/walkie-talkie.png',
                          fit: BoxFit.cover,
                        )
                        : FirebaseHosting.loadImageWidget(
                          GameEngine().npcImagePath(widget.npc),
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = messages.length - 1 - index;
                      return MessageBubble(message: messages[reversedIndex]);
                    },
                  ),
                ),
                Divider(height: 1),
                InputBar(
                  controller: _controller,
                  scrollController: _scrollController,
                  isSending: _isSending,
                  onSendPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
            if (_isSending) SendingOverlay(),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  @override
  void dispose() {
    if (widget.externalController == null) {
      _controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatPageController {
  void Function(String text)? sendMessage;
  final ValueNotifier<bool> isSending = ValueNotifier(false);
}
