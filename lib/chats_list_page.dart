import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage>
    with WidgetsBindingObserver {
  final Set<String> _readChats = <String>{};
  final Map<String, DateTime> _lastReadTimes = <String, DateTime>{};
  Stream<List<Map<String, dynamic>>>? _chatsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastReadTimes();
    _initializeChatsStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh the stream when app comes back to foreground
      _refreshChatsList();
    }
  }

  void _initializeChatsStream() {
    _chatsStream = _getChatsStream();
  }

  Future<void> _loadLastReadTimes() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('chat_read_status')
          .select('partner_id, last_read_at')
          .eq('user_id', currentUserId);

      for (final row in response) {
        final partnerId = row['partner_id'] as String;
        final lastReadAt = DateTime.parse(row['last_read_at']);
        _lastReadTimes[partnerId] = lastReadAt;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading last read times: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _getChatsStream() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    // Use a more efficient stream that triggers on any message change
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Get latest messages first
        .limit(1000) // Limit to prevent performance issues
        .map((rows) {
          final allMessages = List<Map<String, dynamic>>.from(rows);

          // Process messages in chronological order
          final chronologicalMessages = allMessages.reversed.toList();

          // Get unique chat partners for current user
          final chatPartners = <String>{};
          final lastMessages = <String, Map<String, dynamic>>{};
          final unreadCounts = <String, int>{};

          // First pass: collect all chat partners and last messages
          for (final msg in chronologicalMessages) {
            final senderId = msg['sender_id'] as String;
            final recipientId = msg['recipient_id'] as String;
            final messageTime = DateTime.parse(msg['created_at']);

            if (senderId == currentUserId) {
              // I sent this message
              chatPartners.add(recipientId);

              // Update last message if this is more recent
              final existingLast = lastMessages[recipientId];
              if (existingLast == null ||
                  messageTime.isAfter(
                    DateTime.parse(existingLast['created_at']),
                  )) {
                lastMessages[recipientId] = msg;
              }
            } else if (recipientId == currentUserId) {
              // I received this message
              chatPartners.add(senderId);

              // Update last message if this is more recent
              final existingLast = lastMessages[senderId];
              if (existingLast == null ||
                  messageTime.isAfter(
                    DateTime.parse(existingLast['created_at']),
                  )) {
                lastMessages[senderId] = msg;
              }
            }
          }

          // Second pass: count unread messages for each partner
          for (final msg in chronologicalMessages) {
            final senderId = msg['sender_id'] as String;
            final recipientId = msg['recipient_id'] as String;
            final messageTime = DateTime.parse(msg['created_at']);

            // Only count messages sent TO the current user (received messages)
            if (recipientId == currentUserId) {
              final lastReadTime = _lastReadTimes[senderId];
              
              // Message is unread if:
              // 1. No last read time exists for this sender, OR
              // 2. This message was sent after the last read time
              if (lastReadTime == null || messageTime.isAfter(lastReadTime)) {
                unreadCounts[senderId] = (unreadCounts[senderId] ?? 0) + 1;
              }
            }
          }

          // Create chat list with user details
          final chats = <Map<String, dynamic>>[];
          for (final partnerId in chatPartners) {
            chats.add({
              'partner_id': partnerId,
              'last_message': lastMessages[partnerId],
              'unread_count': unreadCounts[partnerId] ?? 0,
            });
          }

          // Sort by last message time (stable sorting)
          chats.sort((a, b) {
            final aTime = DateTime.parse(a['last_message']['created_at']);
            final bTime = DateTime.parse(b['last_message']['created_at']);
            if (aTime.isAtSameMomentAs(bTime)) {
              // If same time, sort by partner ID for stability
              return (a['partner_id'] as String).compareTo(
                b['partner_id'] as String,
              );
            }
            return bTime.compareTo(aTime); // Most recent first
          });

          return chats;
        });
  }

  Future<void> _markChatAsRead(String partnerId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final now = DateTime.now();

    // Update local state immediately
    setState(() {
      _lastReadTimes[partnerId] = now;
    });

    // Save to database
    try {
      await Supabase.instance.client.from('chat_read_status').upsert({
        'user_id': currentUserId,
        'partner_id': partnerId,
        'last_read_at': now.toIso8601String(),
      });
    } catch (e) {
      print('Error saving read status: $e');
    }
  }

  void _refreshChatsList() {
    setState(() {
      _initializeChatsStream();
    });
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      return res?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshChatsList,
            tooltip: 'Refresh chats',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshChatsList();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  'No chats yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final partnerId = chat['partner_id'] as String;
                final lastMessage =
                    chat['last_message'] as Map<String, dynamic>;
                final unreadCount = chat['unread_count'] as int;

                return FutureBuilder<String?>(
                  future: _getUserName(partnerId),
                  builder: (context, nameSnapshot) {
                    final userName = nameSnapshot.data;
                    final initials = _getInitials(userName);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: _getAvatarColor(initials),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          userName ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          lastMessage['content'] ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: unreadCount > 0
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () async {
                          await _markChatAsRead(partnerId);
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                jobId: lastMessage['job_id'],
                                jobTitle: 'Chat',
                                otherUserId: partnerId,
                              ),
                            ),
                          );
                          // Refresh the chat list when returning from chat
                          _refreshChatsList();
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(String initials) {
    final colors = [
      const Color(0xFFE57373), // Red
      const Color(0xFF81C784), // Green
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFBA68C8), // Purple
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFFFF8A65), // Deep Orange
      const Color(0xFF7986CB), // Indigo
    ];

    final index = initials.hashCode % colors.length;
    return colors[index];
  }
}
