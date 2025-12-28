import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:moments/features/chat/widgets/message_bubble.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/data/sources/supabase_config.dart';
import 'package:moments/data/models/message.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:moments/features/chat/widgets/audio_message_bubble.dart';
import 'package:moments/features/chat/widgets/audio_recorder_widget.dart';
import 'package:moments/features/chat/widgets/image_message_bubble.dart';
import 'package:moments/features/chat/widgets/video_message_bubble.dart';
import 'package:moments/features/chat/widgets/typing_indicator_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:icon_button_m3e/icon_button_m3e.dart';

import 'package:moments/core/services/firebase_messaging_service.dart';

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
  Timer? _typingTimer;

  bool _showScrollToBottomButton = false;
  int _unreadCount = 0;
  bool _isFirstLoad = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _scrollController.addListener(_onScroll);

    // Set current chat ID to suppress notifications
    // We need to get the conversation ID first
    Future.delayed(Duration.zero, () {
      final conversationAsync = ref.read(
        conversationIdProvider(widget.friendId),
      );
      conversationAsync.whenData((id) {
        // Update static var for service
        FirebaseMessagingService.currentChatId = id;
        // Clear any existing notification for this chat
        FirebaseMessagingService.cancelNotificationByRelatedId(id);
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    FirebaseMessagingService.currentChatId = null; // Clear static var
    super.dispose();
  }

  @override
  void deactivate() {
    FirebaseMessagingService.currentChatId = null;
    super.deactivate();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Show button if we are more than 200 pixels away from bottom
    final show = (maxScroll - currentScroll) > 200;

    if (show != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = show;
        if (!show) {
          _unreadCount = 0; // Reset count when we scroll to bottom manually
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

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.sendMessage(
        conversationId: conversationId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to send message');
      }
    }
  }

  Future<void> _sendAudioMessage(
    String conversationId,
    String path,
    int durationMs,
  ) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.sendAudioMessage(
        conversationId: conversationId,
        audioPath: path,
        durationMs: durationMs,
      );

      ref.read(isRecordingProvider(conversationId).notifier).stop();

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending audio: $e');
      if (mounted) {
        context.showErrorSnackBar('Failed to send voice note');
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    // Use SchedulerBinding to ensure layout is complete
    // A small delay helps when images/content are still sizing
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
        if (mounted) {
          setState(() {
            _unreadCount = 0;
          });
        }
      }
    });
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
        leadingWidth: 24,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AvatarCacheService().getAvatarImageProvider(
                widget.friendAvatarUrl,
              ),
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
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
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
                // Mark as read without awaiting to avoid blocking UI
                ref.read(chatRepositoryProvider).markAsRead(conversationId);
              }

              // Handle Scroll Logic
              final oldLen = previous?.value?.length ?? 0;
              final newLen = messages.length;
              if (newLen > oldLen) {
                final lastMsg = messages.last;
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

                        // Initial Scroll Logic
                        if (_isFirstLoad) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollToBottom(animated: false);
                              _isFirstLoad = false;
                            }
                          });
                        }

                        // Find the index of the last message sent by the current user
                        int lastMyMessageIndex = -1;
                        for (int i = messages.length - 1; i >= 0; i--) {
                          if (messages[i].senderId == currentUserId) {
                            lastMyMessageIndex = i;
                            break;
                          }
                        }

                        // Build list items with Smart Date Headers and Tail logic
                        final List<Widget> chatItems = [];
                        for (int i = 0; i < messages.length; i++) {
                          final message = messages[i];
                          final isMe = message.senderId == currentUserId;
                          final isFirst = i == 0;

                          // Smart Date Header Logic
                          bool showDate = false;
                          if (isFirst) {
                            showDate = true;
                          } else {
                            final prevDate = messages[i - 1].createdAt;
                            final currDate = message.createdAt;
                            final diff = currDate
                                .difference(prevDate)
                                .inMinutes;
                            if (diff > 60 || prevDate.day != currDate.day) {
                              showDate = true;
                            }
                          }

                          if (showDate) {
                            chatItems.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    _formatDateHeader(message.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                            // Also add tail if next message is > 60 mins away (new block)
                            final nextDate = nextMessage.createdAt;
                            final diff = nextDate
                                .difference(message.createdAt)
                                .inMinutes;
                            if (diff > 60) {
                              tail = true;
                            }
                          }

                          // Add Message Bubble
                          Widget bubble;
                          if (message.messageType == MessageType.audio) {
                            bubble = AudioMessageBubble(
                              message: message,
                              isMe: isMe,
                            );
                          } else if (message.messageType == MessageType.image) {
                            bubble = ImageMessageBubble(
                              message: message,
                              isMe: isMe,
                            );
                          } else if (message.messageType == MessageType.video) {
                            bubble = VideoMessageBubble(
                              message: message,
                              isMe: isMe,
                            );
                          } else {
                            bubble = MessageBubble(
                              message: message,
                              isMe: isMe,
                              tail: tail,
                            );
                          }

                          chatItems.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical:
                                    2, // Reduced vertical padding for tighter groups
                                horizontal: 8,
                              ),
                              child: Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: bubble,
                              ),
                            ),
                          );

                          // Status Label (Delivered/Read) - Only for the last message sent by me
                          if (i == lastMyMessageIndex) {
                            final statusText = message.isRead
                                ? 'Read'
                                : 'Delivered';
                            chatItems.add(
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 2,
                                  bottom: 8,
                                  right: 12,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }

                        // Add typing indicator if someone is typing
                        final typingUsers = ref.watch(
                          typingUsersProvider(conversationId),
                        );
                        if (typingUsers.isNotEmpty) {
                          chatItems.add(
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TypingIndicatorBubble(),
                              ),
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
                      loading: () => Center(
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          width: 150,
                          height: 150,
                        ),
                      ),
                      error: (error, stack) =>
                          Center(child: Text('Error loading messages: $error')),
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
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    IconButtonM3E(
                                      variant: IconButtonM3EVariant.filled,
                                      shape: IconButtonM3EShapeVariant.square,
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
                                          borderRadius: BorderRadius.circular(
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
                                                Icons.sticky_note_2_outlined,
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
                                          variant: IconButtonM3EVariant.filled,
                                          icon: Icon(
                                            showSend
                                                ? Icons.send
                                                : Icons.mic_none_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: showSend
                                              ? () =>
                                                    _sendMessage(conversationId)
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
                                );
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
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendImageMessage(
            conversationId: conversationId,
            imagePath: file.path,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
      }
    }
  }

  Future<void> _sendVideoMessage(String conversationId, File file) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendVideoMessage(
            conversationId: conversationId,
            videoPath: file.path,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send video: $e')));
      }
    }
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
}
