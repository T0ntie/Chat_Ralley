import 'package:flutter/material.dart';
import 'npc.dart';
import 'conversation.dart';

class ChatPage extends StatefulWidget {
  ChatPage({super.key, required this.npc});
  final NPC npc;


  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  late  Conversation _conversation;
  late List<ChatMessage> _messages = [];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _conversation = widget.npc.currentConversation;
    _messages = _conversation.getMessages();

  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, fromUser: true));
      _messages.add(ChatMessage(text: "Antwort von NPC: $text", fromUser: false));
    });

    _controller.clear();
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final alignment = msg.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = msg.fromUser ? Colors.green[200] : Colors.grey[300];
    final radius = msg.fromUser
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

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
          ),
          child: Text(msg.text),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat mit NPC ${widget.npc.name}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final reversedIndex = _messages.length - 1 - index;
                return _buildMessageBubble(_messages[reversedIndex]);
              },
            ),
          ),
          Divider(height: 1),
          /*Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: "Nachricht schreiben...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.green,
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),*/

          Container(
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
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
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


