import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // Toggle between 'Quick' and 'Detailed' AI models
  bool _isDetailedMode = false;

  // Mock list of messages for the demo
  final List<Map<String, dynamic>> _messages = [
    {
      "text": "Hello! I am your MediMind assistant. How can I help you today?",
      "isUser": false
    },
  ];

  void _handleSendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      // Add user message
      _messages.add({"text": _controller.text, "isUser": true});

      // Simulate AI response based on selected model
      String response = _isDetailedMode
          ? "Analysis: Based on medical guidelines, this medication interacts with..."
          : "Yes, you can take this with water.";

      _messages.add({"text": response, "isUser": false});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "MediMind AI",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Switch for the two models mentioned in Sprint 2
          Row(
            children: [
              Text(
                _isDetailedMode ? "Detailed" : "Quick",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Switch(
                value: _isDetailedMode,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) => setState(() => _isDetailedMode = val),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg["text"], msg["isUser"]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isUser ? Radius.circular(15) : Radius.circular(0),
            bottomRight: isUser ? Radius.circular(0) : Radius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask about your meds...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _handleSendMessage,
            ),
          )
        ],
      ),
    );
  }
}