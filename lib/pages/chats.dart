// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/constants.dart';

class MyChatsPage extends StatefulWidget {
  const MyChatsPage({super.key});

  @override
  _MyChatsPageState createState() => _MyChatsPageState();
}

class _MyChatsPageState extends State<MyChatsPage> {
  final _storage = const FlutterSecureStorage();
  late Future<List<dynamic>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _fetchChats();
  }

  Future<List<dynamic>> _fetchChats() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not logged in. Please log in.")),
        );
        context.go('/login');
      });
      throw Exception('No token found.');
    }

    final url = Uri.parse('$BASE_URL/rooms/');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    print('🔍 Response Status Code: ${response.statusCode}');
    print('🔍 Response Body: ${utf8.decode(response.bodyBytes)}');
    print('🔍 Request URL: $url');
    print('🔍 Token: Bearer $token');

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List<dynamic> data = jsonDecode(decoded);

      // ✅ Sort unread first, then newest messages
      data.sort((a, b) {
        final aUnread = a['unread_count'] ?? 0;
        final bUnread = b['unread_count'] ?? 0;
        if (aUnread != bUnread) return bUnread.compareTo(aUnread);

        final aTime = DateTime.tryParse(a['last_message']?['timestamp'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['last_message']?['timestamp'] ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return data;
    } else if (response.statusCode == 401) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unauthorized. Please log in.")),
        );
        context.go('/login');
      });
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load chats. Status: ${response.statusCode}');
    }
  }

  Widget _buildChatTile(BuildContext context, dynamic chat) {
    final String profileImage =
        chat['store_logo'] ?? 'assets/images/profile.jpg';
    final String chatName = chat['chat_name'] ?? "Unknown";
    final String lastMessage = chat['last_message']?['content'] ?? "";
    String formattedTime = "";
    if (chat['last_message']?['timestamp'] != null) {
      try {
        DateTime dt = DateTime.parse(chat['last_message']['timestamp']);
        formattedTime = DateFormat.Hm().format(dt);
      } catch (e) {
        formattedTime = chat['last_message']['timestamp'];
      }
    }
    final int unreadCount = chat['unread_count'] ?? 0;

    return GestureDetector(
      onTap: () async {
        final token = await _storage.read(key: 'token');
        final roomId = chat['id'];

        // ✅ Mark messages as read
        final markUrl = Uri.parse('$BASE_URL/rooms/$roomId/');
        await http.get(markUrl, headers: {
          'Authorization': 'Bearer $token',
        });

        // ✅ Navigate to chat details
        await context.push('/chat-details', extra: {
          "name": chatName,
          "profileImage": profileImage,
          "roomId": roomId,
        });

        // ✅ Refresh chat list after return
        setState(() {
          _chatsFuture = _fetchChats();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: unreadCount > 0 ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: profileImage.startsWith("http")
                  ? Image.network(profileImage,
                      width: 50, height: 50, fit: BoxFit.cover)
                  : Image.asset(profileImage,
                      width: 50, height: 50, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$unreadCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChatsBanner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No chats available",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return _buildNoChatsBanner();
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return _buildChatTile(context, chats[index]);
              },
            );
          }
        },
      ),
    );
  }
}
