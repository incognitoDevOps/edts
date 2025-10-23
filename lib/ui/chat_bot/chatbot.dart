import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const ChatBotApp());

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  Set<int> _selectedIndices = {};
  bool _selectionMode = false;
  late ScrollController _scrollController;
  final TextEditingController _textController = TextEditingController();

  final Map<String, String> _qaMap = {
    "What is your name?": "I'm BuzRyde Bot!",
    "How can I help you?": "You can ask anything about our services.",
    "Where are you located?": "We are based in Canada.",
    "How do I contact support?":
        "You can reach support at support@buzryde.com.",
    "How do I book a ride?":
        "To book a ride:\n1. Open the BuzRyde app\n2. Enter your destination\n3. Choose your ride type\n4. Tap 'Request Ride'.",
    "Can I cancel my ride?":
        "Yes, before the driver arrives. Go to 'Your Trips' > Select Ride > Cancel.",
    "My driver was late or didn’t show up.":
        "Sorry about that! Please report the trip via 'Your Trips' > Select Ride > Report an Issue.",
    "Can I ride city to city?":
        "City-to-city rides are not available yet but coming soon.",
    "How do I change my account details?":
        "Go to 'Profile' and tap the section you want to update.",
    "How do I delete my account?":
        "Go to 'Settings' > 'Delete Account' or contact support.",
    "I’m not receiving notifications.":
        "Ensure notifications are enabled and the app is updated.",
    "How do I reset my password?":
        "From the login screen, tap 'Forgot Password' and follow the steps.",
    "How do I pay for a ride?":
        "You can pay using card or wallet balance. Stripe handles payments securely.",
    "My wallet top-up failed. What should I do?":
        "Check your balance and internet connection. If deducted, contact support with a screenshot.",
    "How do I load money into my wallet?":
        "Go to 'Wallet' > 'Add Funds', enter the amount and card details.",
    "Will I get discounts or offers?":
        "Yes! Check the Promotions section in your app.",
    "How can I become a BuzRyde driver?":
        "Download the Driver App, sign up and upload your documents.",
    "How long does driver approval take?":
        "Usually 24–48 hours, depending on document verification.",
    "How do referrals and the affiliate program work?":
        "You earn 5% for up to 6 months from referrals. More details in-app soon.",
    "I was charged incorrectly.":
        "Report it under 'Your Trips' > Select Ride > Report an Issue.",
    "My app is crashing or slow.":
        "Try restarting, updating, or checking your network. Contact us if it continues.",
    "I have another issue.":
        "Please describe it briefly and support will reach out.",
    "Can I speak to someone directly?":
        "Sure. Type 'Talk to a human' and we’ll connect you to support.",
    "How fast does support respond?":
        "We usually reply within 2–6 hours. Urgent issues are prioritized.",
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('chat_messages', encoded);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('chat_messages') ?? [];
    setState(() {
      _messages = data.map((e) => Message.fromJson(jsonDecode(e))).toList();
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleQuestionClick(String question) {
    _handleTypedMessage(question);
  }

  void _handleTypedMessage(String input) async {
    if (input.isEmpty) return;

    final userMsg = Message(
      text: input,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final lowerInput = input.toLowerCase().trim();

    String botReply;

    if (_qaMap.containsKey(input)) {
      botReply = _qaMap[input]!;
    } else if (RegExp(r'^(hi|hello|hey|good (morning|afternoon|evening))$')
        .hasMatch(lowerInput)) {
      botReply = "Hi there! How can I assist you today?";
    } else if (lowerInput.contains("talk to human") ||
        lowerInput.contains("another issue") ||
        lowerInput.contains("need more help") ||
        lowerInput.contains("someone") ||
        lowerInput.contains("representative")) {
      botReply =
          "Sure! Please send your query to our support team at support@buzryde.com and they'll get back to you.";
    } else {
      botReply =
          "Sorry, I didn’t understand that. A support team member will get back to you shortly.";
    }

    final botMsg = Message(
      text: botReply,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.addAll([userMsg, botMsg]);
    });

    await _saveMessages();
    _scrollToBottom();
  }

  void _onLongPress(int index) {
    setState(() {
      _selectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _onTapMessage(int index) {
    if (_selectionMode) {
      setState(() {
        _selectedIndices.contains(index)
            ? _selectedIndices.remove(index)
            : _selectedIndices.add(index);

        if (_selectedIndices.isEmpty) _selectionMode = false;
      });
    }
  }

  Future<void> _deleteSelectedMessages() async {
    setState(() {
      _messages = [
        for (int i = 0; i < _messages.length; i++)
          if (!_selectedIndices.contains(i)) _messages[i]
      ];
      _selectedIndices.clear();
      _selectionMode = false;
    });

    await _saveMessages();
    _scrollToBottom();
  }

  Widget _buildMessage(Message msg, int index) {
    final isUser = msg.isUser;
    final isSelected = _selectedIndices.contains(index);
    final time =
        "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onLongPress: () => _onLongPress(index),
      onTap: () => _onTapMessage(index),
      child: Container(
        color: isSelected ? Colors.grey.shade300 : Colors.transparent,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? Colors.green.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 12),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(msg.text, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _qaMap.keys.map((q) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: () => _handleQuestionClick(q),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.black87,
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: Text(q),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type your question...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onSubmitted: (value) {
                _handleTypedMessage(value.trim());
                _textController.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () {
              _handleTypedMessage(_textController.text.trim());
              _textController.clear();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              backgroundColor: const Color.fromARGB(255, 245, 135, 127),
              title: Text('${_selectedIndices.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedMessages,
                )
              ],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i], i),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: SingleChildScrollView(child: _buildQuestionList()),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
