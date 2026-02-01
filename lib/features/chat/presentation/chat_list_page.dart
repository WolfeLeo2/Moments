import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:moments/features/chat/presentation/chat_page.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/widgets/time_ago_text.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/presentation/widgets/new_chat_sheet.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  void _showNewChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatSheet(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedMessageAdd01,
          color: Colors.white,
          size: 24,
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Left arrow.svg',
            width: 34.w,
            height: 34.h,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: chatListAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage01,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 0),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ChatListTile(
                conversationId: conversation['conversationId'] as String,
                lastMessage: conversation['lastMessage'] as Message,
                otherUserId: conversation['otherUserId'] as String,
                unreadCount: conversation['unreadCount'] as int? ?? 0,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class ChatListTile extends ConsumerWidget {
  final String conversationId;
  final Message lastMessage;
  final String otherUserId;
  final int unreadCount;

  const ChatListTile({
    super.key,
    required this.conversationId,
    required this.lastMessage,
    required this.otherUserId,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(otherUserId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  friendId: otherUserId,
                  friendName:
                      profile.displayName ?? profile.username ?? 'Friend',
                  friendAvatarUrl: profile.avatarUrl,
                ),
              ),
            );
          },
          leading: Container(
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: ref
                  .watch(avatarCacheServiceProvider)
                  .getAvatarImageProvider(profile.avatarUrl),
              child: profile.avatarUrl == null
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      size: 24,
                      color: Colors.grey,
                    )
                  : null,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  profile.displayName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                TimeAgoText(
                  dateTime: lastMessage.createdAt,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                TimeAgoText(
                  dateTime: lastMessage.createdAt,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  lastMessage.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                    fontWeight: unreadCount > 0
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Badge(
                  label: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryBlue,
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 72), // Placeholder height
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
