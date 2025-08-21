import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String otherUserId;

  const ChatPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _otherDisplayName;
  List<Map<String, dynamic>> _localMessages = [];

  @override
  void initState() {
    super.initState();
    _loadOtherUserDisplay();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final now = DateTime.now();

    try {
      // Mark all messages from this user as read
      await Supabase.instance.client.from('chat_read_status').upsert({
        'user_id': currentUserId,
        'partner_id': widget.otherUserId,
        'last_read_at': now.toIso8601String(),
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _loadOtherUserDisplay() async {
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', widget.otherUserId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _otherDisplayName =
            (res != null &&
                res['name'] != null &&
                (res['name'] as String).trim().isNotEmpty)
            ? res['name'] as String
            : null;
      });
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    // Get all messages between these two users (across all jobs)
    // We'll filter in the map function since Supabase stream doesn't support complex OR conditions
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) {
          final allMessages = List<Map<String, dynamic>>.from(rows);
          // Filter to only messages between these two users
          final filteredMessages = allMessages.where((msg) {
            final senderId = msg['sender_id'] as String;
            final recipientId = msg['recipient_id'] as String;
            return (senderId == currentUserId &&
                    recipientId == widget.otherUserId) ||
                (senderId == widget.otherUserId &&
                    recipientId == currentUserId);
          }).toList();

          // Mark messages as read when they arrive (if they're from the other user)
          _markNewMessagesAsRead(filteredMessages);

          return filteredMessages;
        });
  }

  Future<void> _markNewMessagesAsRead(List<Map<String, dynamic>> messages) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Find the latest message from the other user
    DateTime? latestMessageTime;
    for (final msg in messages) {
      final senderId = msg['sender_id'] as String;
      if (senderId == widget.otherUserId) {
        final messageTime = DateTime.parse(msg['created_at']);
        if (latestMessageTime == null || messageTime.isAfter(latestMessageTime)) {
          latestMessageTime = messageTime;
        }
      }
    }

    // Update read status if we have new messages
    if (latestMessageTime != null) {
      try {
        await Supabase.instance.client.from('chat_read_status').upsert({
          'user_id': currentUserId,
          'partner_id': widget.otherUserId,
          'last_read_at': latestMessageTime.toIso8601String(),
        });
      } catch (e) {
        print('Error marking new messages as read: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    // Add message locally first for immediate display
    final localMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMessage = {
      'id': localMessageId,
      'job_id': widget.jobId,
      'sender_id': uid,
      'recipient_id': widget.otherUserId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'is_local': true, // Mark as local message
    };
    setState(() {
      _localMessages.add(newMessage);
    });
    _textController.clear();

    // Scroll to bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await Supabase.instance.client.from('messages').insert({
        'job_id': widget.jobId,
        'sender_id': uid,
        'recipient_id': widget.otherUserId,
        'content': content,
      });

      // Remove the local message after successful server save
      setState(() {
        _localMessages.removeWhere((msg) => msg['id'] == localMessageId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      // Remove the local message if send failed
      setState(() {
        _localMessages.removeWhere((msg) => msg['id'] == localMessageId);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_otherDisplayName ?? 'Chat'),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final serverMessages = snapshot.data!;
                final allMessages = [...serverMessages, ..._localMessages];
                allMessages.sort(
                  (a, b) => DateTime.parse(
                    a['created_at'],
                  ).compareTo(DateTime.parse(b['created_at'])),
                );

                // Auto-scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && allMessages.isNotEmpty) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent + 80,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    final isMe = msg['sender_id'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFDCF8C6)
                              : const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _sendMessage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A9CE), // teal/blue color
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      minimumSize: Size(120, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // rounded corners
                      ),
                    ),
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8),
                  // IconButton(
                  //   icon: const Icon(Icons.send, color: Colors.blueAccent),
                  //   onPressed: _sendMessage,
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
