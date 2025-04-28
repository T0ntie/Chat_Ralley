import 'package:flutter/material.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/gui/flush_bar_service.dart';
import '../engine/npc.dart';
import '../engine/conversation.dart';
import 'snack_bar_service.dart';
import 'package:another_flushbar/flushbar.dart';

class ChatPage extends StatefulWidget {
  ChatPage({super.key, required this.npc});

  final Npc npc;
  final GameEngine gameEngine = GameEngine.instance;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Conversation _conversation;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    FlushBarService().setContext(context);
    _conversation = widget.npc.currentConversation;
    _conversation.onConversationFinished = _closeChatAfterDelay;
    widget.gameEngine.registerInteraction(widget.npc);
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
      _conversation.addUserMessage(text);
      _isSending = true;
    });
    try {
      String response = await _conversation.processConversation();

      if (!mounted) return;

      setState(() {
        _conversation.addAssistantMessage(response);
      });

    } catch (e) {
      SnackBarService.showErrorSnackBar(
        context,
        '❌ Kommunikation mit Chat GPT fehlgeschlagen.',
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _controller.clear();
    }
  }

  CrossAxisAlignment _getAlignmen(bool fromUser){
    return fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }
  Color? _getBubbleColor(bool fromUser) {
    return fromUser ? Colors.green[200] : Colors.grey[300];
  }
  BorderRadius _getRadius(bool fromUser) {
    return fromUser
        ? BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    )
        : BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final bool fromUser = msg.fromUser;
    return Column(
      crossAxisAlignment: _getAlignmen(fromUser),
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: _getBubbleColor(fromUser),borderRadius: _getRadius(fromUser)),
          child: Text(msg.filteredText),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Scrollbar(
                  child: TextField(
                    controller: _controller,
                    scrollController: _scrollController,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: "Nachricht schreiben...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                color: Colors.green,
                onPressed:
                    _isSending ? null : () => _sendMessage(_controller.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation.getVisibleMessages();
    return Scaffold(
      appBar: AppBar(title: Text(widget.npc.displayName)),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
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
                    return _buildMessageBubble(messages[reversedIndex]);
                  },
                ),
              ),
              Divider(height: 1),
              _buildInputBar(),
            ],
          ),
          if (_isSending)
            Positioned.fill(
              child: Container(
                color: Colors.white.withAlpha((0.6 * 255).toInt()),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
