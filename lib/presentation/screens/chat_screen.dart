import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Toggle between 'Quick' and 'Detailed' models
  bool _isDetailedMode = false;

  // Mock list of messages for the demo
  final List<Map<String, dynamic>> _messages = [
    {
      "text": "Hello! I am your MediMind assistant. How can I help you today?",
      "isUser": false,
      "time": DateTime.now(),
    },
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _handleSendMessage() {
    if (_controller.text.isEmpty) return;
    final userText= _controller.text;

    setState(() {
      // Add user message
      _messages.add({"text": userText, "isUser": true, "time": DateTime.now()});
      _controller.clear();
    });
    _scrollToBottom();

    // Simulate AI response after a short delay
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          // Simulate AI response based on selected model
          String response = _isDetailedMode
              ? "Detailed Analysis: Research suggests that ${userText.toLowerCase().contains('aspirin') ? 'Aspirin' : 'this medication'} can have interactions with blood thinners. Always consult your doctor for a clinical diagnosis."
              : "Quick Check: Generally safe, but take it after a meal to avoid stomach upset.";

          _messages.add({"text": response, "isUser": false, "time": DateTime.now()});
        });
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MediMind Assistant", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),),
            Text("Always online", style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          // Switch for the two models
          _buildToggleSwitch(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
  Widget _buildToggleSwitch() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size:16, color: _isDetailedMode ? Colors.grey : Colors.amber),
          Switch(
            value: _isDetailedMode,
            activeColor: AppColors.primaryBlue,
            onChanged: (value) => setState(()=>_isDetailedMode = value),
            ),
          Icon(Icons.biotech, size: 16, color: _isDetailedMode ? AppColors.primaryBlue : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isUser = msg["isUser"];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isUser ? Radius.circular(20) : Radius.circular(0),
            bottomRight: isUser ? Radius.circular(0) : Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2)
            ),
          ],
        ),
        child: Text(
          msg["text"],
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask about your meds...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSendMessage,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}