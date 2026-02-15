import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:moments/features/chat/presentation/chat_page.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/widgets/time_ago_text.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/presentation/new_conversation_page.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _openNewConversation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewConversationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chatListAsync = ref.watch(chatListProvider);
    final notificationCount = ref.watch(notificationCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Space for floating dock
        child: FloatingActionButton.extended(
          onPressed: () => _openNewConversation(context),
          label: Text(
            "New Message",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          elevation: 0,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedMessageAdd02,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            size: 22,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'GoogleSansFlex',
            fontWeight: FontWeight.w900,
            fontVariations: const [
              FontVariation('wght', 900),  
            ],
            color: AppTheme.textDark,
            letterSpacing: -1.5,
          ),
        ),
        actions: [
          Badge(
            isLabelVisible: notificationCount > 0,
            label: Text(
              '$notificationCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppTheme.coralPink,
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsPage()),
              ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              autofocus: false,
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: AppTheme.textGray,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // ── Conversation list ──
          Expanded(
            child: Builder(
        builder: (context) {
          final conversations = chatListAsync.asData?.value;

          if (chatListAsync.isLoading && conversations == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatListAsync.hasError && conversations == null) {
            return Center(child: Text('Error: ${chatListAsync.error}'));
          }

          if (conversations == null || conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage01,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 0),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ChatListTile(
                conversationId: conversation['conversationId'] as String,
                lastMessage: conversation['lastMessage'] as Message,
                otherUserId: conversation['otherUserId'] as String,
                unreadCount: conversation['unreadCount'] as int? ?? 0,
                searchQuery: _searchQuery,
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

class ChatListTile extends ConsumerWidget {
  final String conversationId;
  final Message lastMessage;
  final String otherUserId;
  final int unreadCount;
  final String searchQuery;

  const ChatListTile({
    super.key,
    required this.conversationId,
    required this.lastMessage,
    required this.otherUserId,
    this.unreadCount = 0,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(otherUserId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        // Filter by search query - match name or message content
        if (searchQuery.isNotEmpty) {
          final name = (profile.displayName ?? profile.username ?? '')
              .toLowerCase();
          final content = lastMessage.content.toLowerCase();
          if (!name.contains(searchQuery) && !content.contains(searchQuery)) {
            return const SizedBox.shrink();
          }
        }

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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                TimeAgoText(
                  dateTime: lastMessage.createdAt,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                TimeAgoText(
                  dateTime: lastMessage.createdAt,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                    fontWeight: unreadCount > 0
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Badge(
                  label: Text(
                    unreadCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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
