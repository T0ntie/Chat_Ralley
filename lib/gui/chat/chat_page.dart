import 'package:flutter/material.dart';
import 'package:hello_world/app_resources.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/gui/chat/chat_gui_elements.dart';
import 'package:hello_world/gui/notification_services.dart';
import '../../engine/npc.dart';
import '../../engine/conversation.dart';

class ChatPage extends StatefulWidget {

  final Npc npc;
  final Medium medium;
  final VoidCallback? onDispose; // <-- NEU

  const ChatPage({super.key, required this.npc, this.medium = Medium.chat,  this.onDispose,});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Conversation _conversation;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool get isRadio => widget.medium == Medium.radio;
  Medium get medium => widget.medium;

  @override
  void initState() {
    super.initState();
    _conversation = widget.npc.currentConversation;
    _conversation.onConversationFinished = _closeChatAfterDelay;
    GameEngine().registerInteraction(widget.npc);
    _handleTriggers();
    widget.npc.hasSomethingToSay = false;
  }

  void _closeChatAfterDelay() {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _conversation.addUserMessage(text, medium);
      _isSending = true;
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
      print("Exception occured: $e : \n${stackTrace} ");
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation.getVisibleMessages(medium);
    return Scaffold(
      appBar:

      AppBar(
      backgroundColor: Colors.blueGrey.shade900,
      elevation: 4,
      foregroundColor: Colors.white,
      title: isRadio
          ? Row(
        children: [
          Icon(Icons.radio, size: 20, color: Colors.white70),
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






    // AppBar(title: isRadio ? Text("Walkie Talkie"): Text(widget.npc.displayName)),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: isRadio ?
              ResourceImages.walkieTakie(context) :
              Image.asset(
                'assets/story/${widget.npc.displayImageAsset}',
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
                onSendPressed: () => _sendMessage(_controller.text),
              )
            ],
          ),
          if (_isSending) SendingOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    GameEngine().flushDeferredActions();
    widget.onDispose?.call();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
