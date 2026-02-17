import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/giphy_picker_helper.dart';
import '../../../widgets/avatar_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Bottom sheet displaying a real-time comment thread for a moment.
///
/// Uses a simple `Padding` + constrained layout — no DraggableScrollableSheet,
/// no emoji panel, no custom tab controller. GIF/Sticker selection opens
/// via `giphy_get`'s built-in picker sheet.
class CommentsSheet extends ConsumerStatefulWidget {
  final String momentId;
  const CommentsSheet({super.key, required this.momentId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _sending = false;

  /// Cached stream to avoid re-creation on rebuilds
  late final Stream<List<Map<String, dynamic>>> _commentsStream;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(momentRepositoryProvider);
    _commentsStream = repo.watchCommentsForMoment(widget.momentId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  /// Opens giphy_get's picker and sends the selected GIF/sticker as a comment.
  Future<void> _openGifPicker() async {
    _focusNode.unfocus();
    final result = await GiphyPickerHelper.pickGif(context);
    if (result == null || !mounted) return;

    setState(() => _sending = true);
    try {
      final repo = ref.read(momentRepositoryProvider);
      await repo.addComment(
        widget.momentId,
        result.url,
        contentType: result.type,
        mediaUrl: result.url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send ${result.type}')),
        );
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
    final tt = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPad + 60),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundBeige,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Text(
                'Comments',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: AppTheme.borderGray.withValues(alpha: 0.3),
            ),
            // ── Comment list ──
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _commentsStream,
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
                              color: AppTheme.textGray.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
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
            // ── Input row ──
            _buildInputField(tt),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // GIF/Sticker picker button
            GestureDetector(
              onTap: _openGifPicker,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  CupertinoIcons.gift,
                  color: AppTheme.textGray,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
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
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
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

/// Individual comment tile using [AvatarImage] for cached avatar display.
class _CommentTile extends ConsumerWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onDelete;

  const _CommentTile({required this.comment, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final displayName = (comment['display_name'] as String?) ?? 'Anonymous';
    final userId = comment['user_id'] as String?;
    final content = comment['content'] as String? ?? '';
    final contentType = comment['content_type'] as String?;
    final mediaUrl = comment['media_url'] as String?;
    final createdAt = DateTime.tryParse(comment['created_at'] as String? ?? '');
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarImage(
            userId: userId,
            size: 32,
            backgroundColor: AppTheme.borderGray.withValues(alpha: 0.15),
            placeholder: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                if (contentType == 'gif' && mediaUrl != null)
                  _buildGifContent(mediaUrl)
                else if (contentType == 'sticker' && mediaUrl != null)
                  _buildStickerContent(mediaUrl)
                else
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

  Widget _buildGifContent(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 150),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 150,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 150,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'GIPHY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickerContent(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox(
          width: 80,
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => const SizedBox(
          width: 80,
          height: 80,
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
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
