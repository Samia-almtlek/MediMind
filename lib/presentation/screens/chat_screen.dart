import 'package:flutter/material.dart';
import 'package:medimind/service/chatbot/authorized_context_provider.dart';
import 'package:medimind/service/chatbot/chatbot_prompts.dart';
import 'package:medimind/service/chatbot/lm_studio_chat_client.dart';
import 'package:medimind/service/chatbot/lm_studio_config.dart';
import '../../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthorizedContextProvider _contextProvider =
      LocalDrugListContextProvider();
  late final LmStudioChatClient _chatClient;
  // Toggle between 'Quick' and 'Detailed' models
  bool _isDetailedMode = false;
  bool _isTyping = false; // To show typing indicator

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

  @override
  void initState() {
    super.initState();
    _chatClient = LmStudioChatClient();
  }

  Future<void> _handleSendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    if (_isTyping) return;
    final userText = _controller.text.trim();

    setState(() {
      // Add user message
      _messages.add({"text": userText, "isUser": true, "time": DateTime.now()});
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    String response;

    try {
      final endpoint = LmStudioConfig.completionUri;
      if (endpoint == null) {
        throw LmStudioException(
          'LM Studio URL is missing. Run with --dart-define=LM_STUDIO_BASE_URL=http://169.254.5.254:1234',
        );
      }

      final authorizedContext =
          await _contextProvider.buildAuthorizedContext(userText);

      response = await _chatClient.complete(
        endpoint: endpoint,
        model: _isDetailedMode ? LmStudioModels.detailed : LmStudioModels.quick,
        authorizedContext: authorizedContext,
        question: userText,
      );
    } on LmStudioException catch (error) {
      response =
          'I cannot complete this request right now: ${error.message}';
    } catch (_) {
      response =
          'I cannot complete this request right now. Please verify LM Studio is running and reachable.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isTyping = false;
      _messages.add({"text": response, "isUser": false, "time": DateTime.now()});
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatClient.dispose();
    super.dispose();
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
          _buildModeBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0), // Add extra item for typing indicator
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                } else {
                  return _buildChatBubble(_messages[index]);
                }
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildModeBanner() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _isDetailedMode ? AppColors.primaryBlue.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDetailedMode ? Icons.biotech : Icons.bolt,
            size: 14,
            color: _isDetailedMode ? AppColors.primaryBlue : Colors.orange,
          ),
          SizedBox(width: 8),
          Text(
            _isDetailedMode ? "Detailed Mode: Extensive Medical Insights" : "Quick Mode: Fast & Direct Answers",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isDetailedMode ? AppColors.primaryBlue : Colors.orange[800],
            ),
          ),
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
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text("Quick", style: TextStyle(fontSize: 10, fontWeight: _isDetailedMode ? FontWeight.normal : FontWeight.bold)),
          SizedBox(width: 4),
          Icon(Icons.bolt, size:14, color: _isDetailedMode ? Colors.grey : Colors.amber),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _isDetailedMode,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) => setState(() => _isDetailedMode = value),
            ),
          ),
          Icon(Icons.biotech, size: 14, color: _isDetailedMode ? AppColors.primaryBlue : Colors.grey),
          SizedBox(width: 4),
          Text("Detailed", style: TextStyle(fontSize: 10, fontWeight: _isDetailedMode ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
            SizedBox(width: 10),
            Text("AI is generating response...", style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic)),

          ],
        ),
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
              onSubmitted: (_) {
                _handleSendMessage();
              },
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _handleSendMessage();
            },
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