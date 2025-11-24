import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:moments/features/chat/widgets/message_bubble.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/data/sources/supabase_config.dart';
import 'package:moments/data/models/message.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatarUrl;

  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  bool _isLoading = true;
  bool _showSendButton = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🔵 [ChatPage] initState called - conversationId: $_conversationId, isLoading: $_isLoading',
    );
    _messageController.addListener(_onMessageChanged);

    // Check cache first
    final cachedId = ref
        .read(conversationCacheProvider.notifier)
        .getCachedConversationId(widget.friendId);
    if (cachedId != null) {
      debugPrint('✅ [ChatPage] Found cached conversationId: $cachedId');
      setState(() {
        _conversationId = cachedId;
        _isLoading = false;
      });
    } else {
      debugPrint('🔵 [ChatPage] No cached conversationId, initializing...');
      _initializeConversation();
    }
  }

  void _onMessageChanged() {
    setState(() {
      _showSendButton = _messageController.text.trim().isNotEmpty;
    });
  }

  Future<void> _initializeConversation() async {
    debugPrint('🔵 [ChatPage] _initializeConversation started');
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final conversationId = await chatRepo.getOrCreateConversation(
        widget.friendId,
      );

      if (!mounted) return;

      debugPrint(
        '✅ [ChatPage] Got conversationId: $conversationId, setting isLoading to false',
      );

      // Cache the conversation ID
      ref
          .read(conversationCacheProvider.notifier)
          .cacheConversationId(widget.friendId, conversationId);

      setState(() {
        _conversationId = conversationId;
        _isLoading = false;
      });

      // Mark as read when opening chat
      // Wrap in try-catch so it doesn't block the UI if it fails
      try {
        await chatRepo.markAsRead(conversationId);
      } catch (e) {
        debugPrint('Failed to mark as read: $e');
      }
    } catch (e) {
      debugPrint('❌ [ChatPage] Error initializing conversation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Only show error if we really failed to get the conversation
        if (_conversationId == null) {
          context.showErrorSnackBar('Failed to load conversation');
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _conversationId == null) return;

    _messageController.clear();

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.sendMessage(
        conversationId: _conversationId!,
        content: content,
      );

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to send message');
      }
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    debugPrint(
      '🔵 [ChatPage] build called - conversationId: $_conversationId, isLoading: $_isLoading',
    );
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;

    // Listen to message updates to mark them as read in real-time
    if (_conversationId != null) {
      ref.listen<AsyncValue<List<Message>>>(
        messagesStreamProvider(_conversationId!),
        (previous, next) {
          next.whenData((messages) {
            if (messages.isEmpty) return;

            // Check if there are any unread messages from the other user
            final hasUnreadMessages = messages.any(
              (m) => m.senderId != currentUserId && !m.isRead,
            );

            if (hasUnreadMessages) {
              // Mark as read without awaiting to avoid blocking UI
              ref.read(chatRepositoryProvider).markAsRead(_conversationId!);
            }
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige.withValues(alpha: 0.3),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        leadingWidth: 24,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.friendAvatarUrl != null
                  ? NetworkImage(widget.friendAvatarUrl!)
                  : null,
              backgroundColor: AppTheme.electricPurple.withValues(alpha: 0.2),
              child: widget.friendAvatarUrl == null
                  ? Text(
                      widget.friendName.isNotEmpty ? widget.friendName[0] : '?',
                      style: const TextStyle(
                        color: AppTheme.electricPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.friendName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversationId == null
          ? const Center(child: Text('Failed to load conversation'))
          : Stack(
              children: [
                // Messages list
                Positioned.fill(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final messagesAsync = ref.watch(
                        messagesStreamProvider(_conversationId!),
                      );

                      return messagesAsync.when(
                        data: (messages) {
                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Say something! 👋',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Scroll to bottom when new messages arrive
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });

                          // Build list items with DateChips and Tail logic
                          final List<Widget> chatItems = [];
                          for (int i = 0; i < messages.length; i++) {
                            final message = messages[i];
                            final isMe = message.senderId == currentUserId;
                            final isFirst = i == 0;

                            // Date Chip
                            bool showDate = false;
                            if (isFirst) {
                              showDate = true;
                            } else {
                              final prevDate = messages[i - 1].createdAt;
                              final currDate = message.createdAt;
                              if (prevDate.day != currDate.day ||
                                  prevDate.month != currDate.month ||
                                  prevDate.year != currDate.year) {
                                showDate = true;
                              }
                            }

                            if (showDate) {
                              chatItems.add(
                                Center(
                                  child: DateChip(
                                    date: message.createdAt,
                                    color: const Color(0x558AD3D5),
                                  ),
                                ),
                              );
                            }

                            // Tail Logic
                            bool tail = false;
                            if (i == messages.length - 1) {
                              tail = true;
                            } else {
                              final nextMessage = messages[i + 1];
                              if (nextMessage.senderId != message.senderId) {
                                tail = true;
                              }
                              // Also add tail if next message is on a different day (optional but looks better)
                              final nextDate = nextMessage.createdAt;
                              if (message.createdAt.day != nextDate.day) {
                                tail = true;
                              }
                            }

                            chatItems.add(
                              MessageBubble(
                                message: message,
                                isMe: isMe,
                                tail: tail,
                              ),
                            );
                          }

                          return SafeArea(
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                left: 0, // Bubbles handle their own padding
                                right: 0,
                                top: 100, // Space for AppBar
                                bottom: 100, // Space for Input Area
                              ),
                              children: chatItems,
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text('Error loading messages: $error'),
                        ),
                      );
                    },
                  ),
                ),

                // Glassmorphism Message Input
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          // Just the blur, no added color as requested
                          color: Colors.white.withValues(alpha: 0.3),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: 8 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: AppTheme.electricPurple,
                              ),
                              onPressed: () {}, // TODO: Add attachment
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLarge + 2,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Message...',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                        ),
                                        maxLines: null,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.sticky_note_2_outlined,
                                        color: Colors.grey[600],
                                        size: 24,
                                      ),
                                      onPressed: () {}, // TODO: Stickers
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppTheme.electricPurple,
                              ),
                              onPressed: () {}, // TODO: Camera
                            ),
                            IconButton(
                              icon: Icon(
                                _showSendButton
                                    ? Icons.send
                                    : Icons.mic_none_outlined,
                                color: AppTheme.electricPurple,
                              ),
                              onPressed: _showSendButton
                                  ? _sendMessage
                                  : () {}, // TODO: Implement voice note
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
