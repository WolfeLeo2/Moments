import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/services/chat_offline_service.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/sources/supabase_config.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:moments/features/chat/widgets/message_bubble.dart';
import 'package:moments/features/chat/widgets/audio_message_bubble.dart';
import 'package:moments/features/chat/widgets/image_message_bubble.dart';
import 'package:moments/features/chat/widgets/video_message_bubble.dart';
import 'package:moments/features/chat/widgets/audio_recorder_widget.dart';
import 'package:moments/features/chat/widgets/typing_indicator_bubble.dart';
import 'package:moments/features/chat/widgets/reply_preview.dart';
import 'package:moments/features/chat/widgets/message_context_menu.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:icon_button_m3e/icon_button_m3e.dart';

import 'package:moments/core/services/firebase_messaging_service.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
  });

  final String? friendAvatarUrl;
  final String friendId;
  final String friendName;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with AutomaticKeepAliveClientMixin {
  Message? _editingMessage;
  bool _isSearchMode = false;
  final TextEditingController _messageController = TextEditingController();
  // Reply/Edit state
  Message? _replyingToMessage;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showScrollToBottomButton = false;
  Timer? _typingTimer;
  int _unreadCount = 0;

  @override
  void deactivate() {
    FirebaseMessagingService.currentChatId = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    FirebaseMessagingService.currentChatId = null; // Clear static var
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _scrollController.addListener(_onScroll);

    // Listen to conversation ID changes to set currentChatId
    ref.listenManual(conversationIdProvider(widget.friendId), (previous, next) {
      next.whenData((id) {
        FirebaseMessagingService.currentChatId = id;
        FirebaseMessagingService.cancelNotificationByRelatedId(id);

        // Mark messages as read (offline-first)
        ref.read(markAsReadActionProvider.notifier).markAsRead(id);
      });
    }, fireImmediately: true);
  }

  // Track messages being deleted (for poof animation)

  @override
  bool get wantKeepAlive => true;

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // With reverse: true, position 0 is at the bottom (newest messages)
    // So we check if we're scrolled UP away from 0
    final currentScroll = _scrollController.offset;
    final show = currentScroll > 200;

    if (show != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = show;
        if (!show) {
          _unreadCount = 0; // Reset count when we scroll to bottom
        }
      });
    }
  }

  void _onMessageChanged() {
    final conversationAsync = ref.read(conversationIdProvider(widget.friendId));

    conversationAsync.whenData((conversationId) {
      final hasText = _messageController.text.trim().isNotEmpty;
      final currentShowSend = ref.read(showSendButtonProvider(conversationId));

      if (currentShowSend != hasText) {
        if (hasText) {
          ref.read(showSendButtonProvider(conversationId).notifier).show();
        } else {
          ref.read(showSendButtonProvider(conversationId).notifier).hide();
        }
      }
      _handleTyping(conversationId);
    });
  }

  void _handleTyping(String conversationId) {
    // Cancel existing timer
    _typingTimer?.cancel();

    // Send typing event on every keystroke
    // This ensures the indicator stays alive while actively typing
    ref.read(chatRepositoryProvider).sendTyping(conversationId);

    // Auto-clear after 2 seconds of inactivity (no more keystrokes)
    _typingTimer = Timer(const Duration(seconds: 2), () {
      // Timer expired - user stopped typing
    });
  }

  void _subscribeToTyping(String conversationId) {
    ref.read(chatRepositoryProvider).subscribeToTyping(conversationId).listen((
      userId,
    ) {
      if (mounted) {
        // Update typing users map with current timestamp
        ref
            .read(typingUsersProvider(conversationId).notifier)
            .addTypingUser(userId);

        // Clear typing indicator after 5 seconds of inactivity
        // This gives a smooth experience as typing events are sent every ~2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Clear old typing indicators
            ref
                .read(typingUsersProvider(conversationId).notifier)
                .clearOldTypingIndicators(const Duration(seconds: 2));
          }
        });
      }
    });
  }

  Future<void> _sendMessage(String conversationId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _typingTimer?.cancel();

    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) context.showErrorSnackBar('Not authenticated');
      return;
    }

    final offlineService = ref.read(chatOfflineServiceProvider);

    if (_editingMessage != null) {
      // Edit existing message (optimistic - updates local DB immediately)
      await offlineService.editMessageOptimistic(
        messageId: _editingMessage!.id,
        newContent: content,
      );
      setState(() => _editingMessage = null);
      return;
    }

    // Send text message using unified offline-first service
    final replyTo = _replyingToMessage;
    if (replyTo != null) {
      setState(() => _replyingToMessage = null);
    }

    await offlineService.sendTextOptimistic(
      conversationId: conversationId,
      senderId: currentUserId,
      content: content,
      replyToMessageId: replyTo?.id,
      replyToMessage: replyTo,
    );
  }

  /// Retry a failed message
  Future<void> _retryFailedMessage(String messageId) async {
    final offlineService = ref.read(chatOfflineServiceProvider);
    final success = await offlineService.retryMessage(messageId);

    if (!success && mounted) {
      context.showErrorSnackBar('Failed to retry message');
    }
  }

  void _startReply(Message message) {
    setState(() {
      _replyingToMessage = message;
      _editingMessage = null;
    });
  }

  void _startEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _replyingToMessage = null;
      _messageController.text = message.content;
    });
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingToMessage = null;
      _editingMessage = null;
      _messageController.clear();
    });
  }

  Future<void> _handleMessageAction(
    Message message,
    MessageAction action,
  ) async {
    switch (action) {
      case MessageAction.reply:
        _startReply(message);
        break;

      case MessageAction.edit:
        _startEdit(message);
        break;

      case MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.content));
        if (mounted) {
          context.showSuccessSnackBar('Copied to clipboard');
        }
        break;

      case MessageAction.deleteForSelf:
        final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
        if (currentUserId != null) {
          final offlineService = ref.read(chatOfflineServiceProvider);
          await offlineService.deleteForSelfOptimistic(
            messageId: message.id,
            currentUserId: currentUserId,
          );
        }
        break;

      case MessageAction.deleteForEveryone:
        final offlineService = ref.read(chatOfflineServiceProvider);
        await offlineService.deleteForEveryoneOptimistic(messageId: message.id);
        break;
    }
  }

  Future<void> _sendAudioMessage(
    String conversationId,
    String path,
    int durationMs,
  ) async {
    // Stop recording state FIRST to immediately remove the recorder widget
    ref.read(isRecordingProvider(conversationId).notifier).stop();

    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Use offline-first service for optimistic audio sending
    final offlineService = ref.read(chatOfflineServiceProvider);
    await offlineService.sendAudioOptimistic(
      conversationId: conversationId,
      senderId: currentUserId,
      localPath: path,
      durationMs: durationMs,
    );

    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    // With reverse: true, scrolling to 0 takes us to the bottom (newest messages)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            0, // Position 0 is the bottom with reverse: true
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(0);
        }
        if (mounted) {
          setState(() {
            _unreadCount = 0;
          });
        }
      }
    });
  }

  Future<void> _pickMedia(String conversationId) async {
    try {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.common, // Images and Videos
        ),
      );

      if (result != null && result.isNotEmpty) {
        final asset = result.first;
        final file = await asset.file;
        if (file == null) return;

        if (asset.type == AssetType.video) {
          await _sendVideoMessage(conversationId, file);
        } else if (asset.type == AssetType.image) {
          await _sendImageMessage(conversationId, file);
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking media: $e')));
      }
    }
  }

  Future<void> _sendImageMessage(String conversationId, File file) async {
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Use offline-first service for optimistic image sending
    final offlineService = ref.read(chatOfflineServiceProvider);
    await offlineService.sendImageOptimistic(
      conversationId: conversationId,
      senderId: currentUserId,
      localPath: file.path,
    );
    _scrollToBottom();
  }

  Future<void> _sendVideoMessage(String conversationId, File file) async {
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Use offline-first service for optimistic video sending
    final offlineService = ref.read(chatOfflineServiceProvider);
    await offlineService.sendVideoOptimistic(
      conversationId: conversationId,
      senderId: currentUserId,
      localPath: file.path,
    );
    _scrollToBottom();
  }

  Future<void> _pickCameraImage(String conversationId) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        await _sendImageMessage(conversationId, File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking camera image: $e');
    }
  }

  String _formatDateHeader(DateTime date) {
    // Ensure we're working with local time
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final timestring = DateFormat('h:mm a').format(localDate);

    if (messageDate == today) {
      return 'Today $timestring';
    } else if (messageDate == yesterday) {
      return 'Yesterday $timestring';
    } else {
      return '${DateFormat('d MMM').format(date)} $timestring';
    }
  }

  // Removed duplicate dispose method

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final conversationAsync = ref.watch(
      conversationIdProvider(widget.friendId),
    );
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        shape: const Border(
          bottom: BorderSide(color: Colors.white70, width: 1.0),
        ),
        elevation: 0,
        centerTitle: false,
        leadingWidth: 48,
        leading: IconButton(
          icon: Icon(
            _isSearchMode ? CupertinoIcons.clear : CupertinoIcons.back,
            color: Colors.black,
            size: 32,
          ),
          onPressed: () {
            if (_isSearchMode) {
              setState(() {
                _isSearchMode = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: ref
                        .watch(avatarCacheServiceProvider)
                        .getAvatarImageProvider(widget.friendAvatarUrl),
                    backgroundColor: AppTheme.electricPurple.withValues(
                      alpha: 0.2,
                    ),
                    child: widget.friendAvatarUrl == null
                        ? Text(
                            widget.friendName.isNotEmpty
                                ? widget.friendName[0]
                                : '?',
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
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
        actions: [
          if (!_isSearchMode)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                setState(() => _isSearchMode = true);
              },
            ),
        ],
      ),
      body: conversationAsync.when(
        loading: () => Center(
          child: Lottie.asset(
            'assets/animations/loading.json',
            width: 150,
            height: 150,
          ),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (conversationId) {
          // Initialize typing subscription once we have the ID
          // We use a post-frame callback to avoid build-phase side effects
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // This is safe to call repeatedly as it handles its own subscription state
            _subscribeToTyping(conversationId);
          });

          // Listen to message updates to mark them as read in real-time
          ref.listen<
            AsyncValue<List<Message>>
          >(messagesStreamProvider(conversationId), (previous, next) {
            next.whenData((messages) {
              if (messages.isEmpty) return;

              // Check if there are any unread messages from the other user
              final hasUnreadMessages = messages.any(
                (m) => m.senderId != currentUserId && !m.isRead,
              );

              if (hasUnreadMessages) {
                // Mark as read (offline-first - instant local update)
                ref
                    .read(markAsReadActionProvider.notifier)
                    .markAsRead(conversationId);
              }

              // Handle Scroll Logic
              final oldLen = previous?.value?.length ?? 0;
              final newLen = messages.length;
              if (newLen > oldLen) {
                // With DESC ordering, newest message is at index 0 (messages.first)
                final lastMsg = messages.first;
                final isMe = lastMsg.senderId == currentUserId;

                if (isMe) {
                  _scrollToBottom();
                } else {
                  // If user is near bottom (button hidden), scroll. Else show badge.
                  if (!_showScrollToBottomButton) {
                    _scrollToBottom();
                  } else {
                    setState(() {
                      _unreadCount++;
                    });
                  }
                }
              }
            });
          });

          return Stack(
            children: [
              // Messages list
              Positioned.fill(
                child: Consumer(
                  builder: (context, ref, child) {
                    final messagesAsync = ref.watch(
                      messagesStreamProvider(conversationId),
                    );

                    return Builder(
                      builder: (context) {
                        final messagesNullable = messagesAsync.asData?.value;

                        if (messagesAsync.isLoading &&
                            messagesNullable == null) {
                          return Center(
                            child: Lottie.asset(
                              'assets/animations/loading.json',
                              width: 150,
                              height: 150,
                            ),
                          );
                        }
                        if (messagesAsync.hasError &&
                            messagesNullable == null) {
                          return Center(
                            child: Text(
                              'Error loading messages: ${messagesAsync.error}',
                            ),
                          );
                        }

                        final messages = messagesNullable ?? [];
                        // Filter messages if search is active
                        final filteredMessages = _searchQuery.isEmpty
                            ? messages
                            : messages
                                  .where(
                                    (m) => m.content.toLowerCase().contains(
                                      _searchQuery,
                                    ),
                                  )
                                  .toList();

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

                        // Show "no results" if search has no matches
                        if (_searchQuery.isNotEmpty &&
                            filteredMessages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // No need for initial scroll with reverse: true -
                        // newest messages are already at the bottom

                        // With DESC ordering, index 0 is newest.
                        // Find the newest message sent by the current user (first match = newest)
                        int lastMyMessageIndex = -1;
                        for (int i = 0; i < filteredMessages.length; i++) {
                          if (filteredMessages[i].senderId == currentUserId) {
                            lastMyMessageIndex = i;
                            break; // First match in DESC order = newest sent by me
                          }
                        }

                        // Check if anyone is typing (hide during search)
                        final typingUsers = _searchQuery.isEmpty
                            ? ref.watch(typingUsersProvider(conversationId))
                            : <String, DateTime>{};
                        final hasTypingIndicator = typingUsers.isNotEmpty;

                        // Total items = messages + typing indicator (if any)
                        final itemCount =
                            filteredMessages.length +
                            (hasTypingIndicator ? 1 : 0);

                        return SafeArea(
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true, // Newest messages at bottom
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            shrinkWrap:
                                false, // Important: false for performance
                            padding: const EdgeInsets.only(
                              left: 0,
                              right: 0,
                              top: 100, // Space for AppBar
                              bottom: 100, // Space for Input Area
                            ),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              // With reverse: true, index 0 is the NEWEST message
                              // Typing indicator goes at index 0 (appears at bottom)
                              if (hasTypingIndicator && index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 8,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TypingIndicatorBubble(),
                                  ),
                                );
                              }

                              // Adjust index for typing indicator
                              final messageIndex = hasTypingIndicator
                                  ? index - 1
                                  : index;
                              final message = filteredMessages[messageIndex];
                              final isMe = message.senderId == currentUserId;

                              // For date headers and tail logic, we need to look at
                              // adjacent messages. In reverse order:
                              // - "next" visually (above) is messageIndex + 1
                              // - "prev" visually (below) is messageIndex - 1
                              final isNewest = messageIndex == 0;
                              final isOldest =
                                  messageIndex == filteredMessages.length - 1;

                              // Smart Date Header Logic (shows ABOVE message in visual order)
                              // In reverse list, we show header if THIS message starts a new day/time block
                              // iMessage shows timestamp after ~2 minute gaps or day changes
                              bool showDate = false;
                              if (isOldest) {
                                showDate =
                                    true; // Always show for oldest message
                              } else {
                                final olderMessage =
                                    filteredMessages[messageIndex + 1];
                                final diff = message.createdAt
                                    .difference(olderMessage.createdAt)
                                    .inMinutes
                                    .abs();
                                // iMessage-style: show timestamp after 2+ minute gaps or day changes
                                if (diff >= 2 ||
                                    message.createdAt.day !=
                                        olderMessage.createdAt.day) {
                                  showDate = true;
                                }
                              }

                              // Tail Logic - show tail if this is the last in a group
                              // iMessage-style: group messages within ~1 minute from same sender
                              bool tail = false;
                              if (isNewest) {
                                tail = true;
                              } else {
                                final newerMessage =
                                    filteredMessages[messageIndex - 1];
                                // Different sender = new group, show tail
                                if (newerMessage.senderId != message.senderId) {
                                  tail = true;
                                }
                                // Same sender but >1 minute gap = show tail (iMessage grouping)
                                final diff = newerMessage.createdAt
                                    .difference(message.createdAt)
                                    .inSeconds
                                    .abs();
                                if (diff > 60) {
                                  tail = true;
                                }
                              }

                              // Build Message Bubble
                              Widget bubble;
                              if (message.messageType == MessageType.audio) {
                                bubble = AudioMessageBubble(
                                  message: message,
                                  isMe: isMe,
                                );
                              } else if (message.messageType ==
                                  MessageType.image) {
                                bubble = ImageMessageBubble(
                                  message: message,
                                  isMe: isMe,
                                );
                              } else if (message.messageType ==
                                  MessageType.video) {
                                bubble = VideoMessageBubble(
                                  message: message,
                                  isMe: isMe,
                                );
                              } else {
                                String? replySenderName;
                                if (message.replyToMessage != null) {
                                  replySenderName =
                                      message.replyToMessage!.senderId ==
                                          currentUserId
                                      ? 'You'
                                      : widget.friendName;
                                }

                                bubble = MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                  tail: tail,
                                  replySenderName: replySenderName,
                                  onRetry:
                                      message.sendStatus ==
                                          MessageSendStatus.failed
                                      ? () => _retryFailedMessage(message.id)
                                      : null,
                                );
                              }

                              // Wrap with SwipeTo for swipe-to-reply
                              final bubbleKey = GlobalKey();
                              bubble = SwipeTo(
                                key: ValueKey('swipe_${message.id}'),
                                iconOnLeftSwipe: Icons.reply,
                                iconColor: Colors.blue,
                                onLeftSwipe: (details) {
                                  HapticFeedback.mediumImpact();
                                  _startReply(message);
                                },
                                child: GestureDetector(
                                  key: bubbleKey,
                                  onLongPress: () {
                                    final renderBox =
                                        bubbleKey.currentContext
                                                ?.findRenderObject()
                                            as RenderBox?;
                                    if (renderBox == null) return;
                                    final position = renderBox.localToGlobal(
                                      Offset.zero,
                                    );
                                    final size = renderBox.size;
                                    final anchorRect = Rect.fromLTWH(
                                      position.dx,
                                      position.dy,
                                      size.width,
                                      size.height,
                                    );

                                    showFloatingMessageMenu(
                                      context: context,
                                      message: message,
                                      isMe: isMe,
                                      anchorRect: anchorRect,
                                      onAction: (action) =>
                                          _handleMessageAction(message, action),
                                      onReaction: (emoji) async {
                                        final currentUserId = SupabaseConfig
                                            .client
                                            .auth
                                            .currentUser
                                            ?.id;
                                        if (currentUserId == null) return;

                                        // Use offline-first service for optimistic reactions
                                        final offlineService = ref.read(
                                          chatOfflineServiceProvider,
                                        );
                                        await offlineService
                                            .addReactionOptimistic(
                                              messageId: message.id,
                                              emoji: emoji,
                                              userId: currentUserId,
                                            );
                                      },
                                    );
                                  },
                                  child: bubble,
                                ),
                              );

                              // Build the complete item with optional date header and status
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Date header (appears ABOVE message visually, but we add it first
                                  // because Column is not reversed)
                                  if (showDate)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _formatDateHeader(message.createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ),
                                  // The message bubble
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 8,
                                    ),
                                    child: Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: bubble,
                                    ),
                                  ),
                                  // Status Label (for the newest message sent by me)
                                  if (messageIndex == lastMyMessageIndex)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        bottom: 8,
                                        right: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          message.isRead ? 'Read' : 'Delivered',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.grey[500],
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        );
                      },
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
                      child: Consumer(
                        builder: (context, ref, child) {
                          final isRecording = ref.watch(
                            isRecordingProvider(conversationId),
                          );

                          return isRecording
                              ? AudioRecorderWidget(
                                  onRecordingComplete: (path, duration) =>
                                      _sendAudioMessage(
                                        conversationId,
                                        path,
                                        duration,
                                      ),
                                  onCancel: () {
                                    ref
                                        .read(
                                          isRecordingProvider(
                                            conversationId,
                                          ).notifier,
                                        )
                                        .stop();
                                  },
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Reply/Edit preview
                                    if (_replyingToMessage != null)
                                      ReplyPreview(
                                        message: _replyingToMessage!,
                                        senderName:
                                            _replyingToMessage!.senderId ==
                                                SupabaseConfig
                                                    .client
                                                    .auth
                                                    .currentUser
                                                    ?.id
                                            ? 'You'
                                            : widget.friendName,
                                        onCancel: _cancelReplyOrEdit,
                                      ),
                                    if (_editingMessage != null)
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: const Border(
                                            left: BorderSide(
                                              color: Colors.amber,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'Editing message',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _cancelReplyOrEdit,
                                              child: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        IconButtonM3E(
                                          variant: IconButtonM3EVariant.filled,
                                          shape:
                                              IconButtonM3EShapeVariant.square,
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _pickMedia(conversationId),
                                        ),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusLarge + 2,
                                                  ),
                                              border: Border.all(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _messageController,
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
                                                        TextCapitalization
                                                            .sentences,
                                                    onSubmitted: (_) =>
                                                        _sendMessage(
                                                          conversationId,
                                                        ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .sticky_note_2_outlined,
                                                    color: Colors.grey[600],
                                                    size: 24,
                                                  ),
                                                  onPressed:
                                                      () {}, // TODO: Stickers
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        IconButtonM3E(
                                          variant: IconButtonM3EVariant.filled,
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _pickCameraImage(conversationId),
                                        ),
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final showSend = ref.watch(
                                              showSendButtonProvider(
                                                conversationId,
                                              ),
                                            );

                                            return IconButtonM3E(
                                              variant:
                                                  IconButtonM3EVariant.filled,
                                              icon: Icon(
                                                showSend
                                                    ? Icons.send
                                                    : Icons.mic_none_outlined,
                                                color: Colors.white,
                                              ),
                                              onPressed: showSend
                                                  ? () => _sendMessage(
                                                      conversationId,
                                                    )
                                                  : () {
                                                      ref
                                                          .read(
                                                            isRecordingProvider(
                                                              conversationId,
                                                            ).notifier,
                                                          )
                                                          .start();
                                                    },
                                            );
                                          },
                                        ),
                                      ],
                                    ), // Close Row
                                  ],
                                ); // Close Column
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Scroll to bottom button
              if (_showScrollToBottomButton)
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: GestureDetector(
                    onTap: () => _scrollToBottom(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
