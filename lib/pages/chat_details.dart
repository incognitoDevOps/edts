// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moderntr/constants.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class ChatDetailsPage extends StatefulWidget {
  const ChatDetailsPage({super.key});

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  final _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>>? _chatDetailsFuture;
  late int roomId;
  late String otherName;
  late String otherProfileImage;
  String currentUserId = "";
  final TextEditingController _msgController = TextEditingController();
  bool _didExtractArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didExtractArgs) {
      final args =
          GoRouterState.of(context).extra as Map<String, dynamic>? ?? {};
      roomId = int.tryParse(args["roomId"]?.toString() ?? "0") ?? 0;
      otherName = args["name"] ?? "Unknown";
      otherProfileImage = args["profileImage"] ?? "assets/images/profile.jpg";
      _loadCurrentUserId().then((_) {
        setState(() {
          _chatDetailsFuture = _fetchChatDetails();
        });
      });
      _didExtractArgs = true;
    }
  }

  Future<void> _loadCurrentUserId() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      context.go('/login');
      return;
    }

    final url = Uri.parse('$BASE_URL/user/get-id/');
    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      setState(() {
        currentUserId = data['id'].toString();
      });
    } else {
      context.go('/login');
    }
  }

  Future<Map<String, dynamic>> _fetchChatDetails() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No token found.');
    final url = Uri.parse('$BASE_URL/rooms/$roomId/');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody);
    } else if (response.statusCode == 401) {
      context.go('/login');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load chat details');
    }
  }

  Future<void> _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;
    final token = await _storage.read(key: 'token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No token found. Please login.")));
      return;
    }

    final url = Uri.parse('$BASE_URL/rooms/$roomId/messages/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode == 201) {
      _msgController.clear();
      setState(() {
        _chatDetailsFuture = _fetchChatDetails();
      });
    }
  }

  Widget _buildChatBubble(Map<String, dynamic> messageData) {
    final String message = messageData['content'] ?? "";
    final String msgUserId = messageData['user_id']?.toString() ?? "";
    final DateTime time =
        DateTime.tryParse(messageData['timestamp'] ?? '') ?? DateTime.now();
    final String formattedTime = DateFormat('hh:mm a').format(time);
    final bool isSender = (msgUserId == currentUserId);

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSender ? const Color(0xFF6C1910) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isSender ? const Radius.circular(20) : Radius.zero,
            bottomRight: isSender ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isSender ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 12,
                color: isSender ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = "Today";
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = "Yesterday";
    } else {
      label = DateFormat('EEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }

  Widget _buildChatList(List messages) {
    final List<Widget> chatWidgets = [];
    DateTime? lastDate;

    for (var msg in messages) {
      final msgMap = msg as Map<String, dynamic>;
      final msgTime =
          DateTime.tryParse(msgMap['timestamp'] ?? '') ?? DateTime.now();
      final msgDate = DateTime(msgTime.year, msgTime.month, msgTime.day);

      if (lastDate == null || msgDate != lastDate) {
        chatWidgets.add(_buildDaySeparator(msgTime));
        lastDate = msgDate;
      }

      chatWidgets.add(_buildChatBubble(msgMap));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      children: chatWidgets,
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _msgController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF6C1910),
            radius: 25,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String lastSeenText = "Typing...";

    return FutureBuilder<Map<String, dynamic>>(
      future: _chatDetailsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final messages = (data?['messages'] ?? []) as List;
        if (messages.isNotEmpty) {
          final lastMsg = messages.last;
          try {
            DateTime time = DateTime.parse(lastMsg['timestamp']);
            lastSeenText = DateFormat('hh:mm a').format(time);
          } catch (e) {
            lastSeenText = "Typing...";
          }
        }
        messages.sort((a, b) => DateTime.parse(a['timestamp'])
            .compareTo(DateTime.parse(b['timestamp'])));

        return BackButtonHandler(
          parentRoute: '/chats',
          child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading:
                false, // 👈 disables the default back arrow
            backgroundColor: const Color(0xFF6C1910),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: otherProfileImage.startsWith("http")
                      ? Image.network(
                          otherProfileImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          otherProfileImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      lastSeenText,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? Center(child: Text("Error: ${snapshot.error}"))
                  : Column(
                      children: [
                        Expanded(child: _buildChatList(messages)),
                        _buildMessageInput(),
                      ],
                    ),
          ),
        );
      },
    );
  }
}
