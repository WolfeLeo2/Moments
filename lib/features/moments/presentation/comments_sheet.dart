import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/services/haptic_service.dart';

/// Bottom sheet displaying a real-time comment thread for a moment.
class CommentsSheet extends ConsumerStatefulWidget {
  final String momentId;
  const CommentsSheet({super.key, required this.momentId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final repo = ref.read(momentRepositoryProvider);
      await repo.addComment(widget.momentId, text);
      _controller.clear();
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send comment')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    HapticService.lightTap();
    try {
      final repo = ref.read(momentRepositoryProvider);
      await repo.deleteComment(commentId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(momentRepositoryProvider);
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundBeige,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Comments',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderGray.withValues(alpha: 0.3)),
              // ── Comment list (real-time) ──
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repo.watchCommentsForMoment(widget.momentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textGray,
                          ),
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.chat_bubble,
                              size: 48,
                              color: AppTheme.textGray.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textGray.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to share your thoughts',
                              style: tt.bodySmall?.copyWith(
                                color: AppTheme.textGray.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return _CommentTile(
                          comment: comments[index],
                          onDelete: () =>
                              _deleteComment(comments[index]['id'] as String),
                        );
                      },
                    );
                  },
                ),
              ),
              // ── Input field with send button ──
              _buildInputField(tt),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField(TextTheme tt) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: tt.bodyMedium?.copyWith(color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: AppTheme.textGray.withValues(alpha: 0.45),
                  ),
                  filled: true,
                  fillColor: AppTheme.borderGray.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                ),
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 4),
            _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _sendComment,
                    icon: Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: AppTheme.textDark,
                      size: 28,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Individual comment tile with avatar, name, content, and timestamp.
class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onDelete;

  const _CommentTile({required this.comment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final displayName = (comment['display_name'] as String?) ?? 'Anonymous';
    final avatarUrl = comment['avatar_url'] as String?;
    final content = comment['content'] as String? ?? '';
    final createdAt = DateTime.tryParse(comment['created_at'] as String? ?? '');
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.borderGray.withValues(alpha: 0.15),
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // ── Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: tt.labelSmall?.copyWith(
                        color: AppTheme.textGray.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: tt.bodyMedium?.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }
}
