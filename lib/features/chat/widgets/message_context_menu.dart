import 'package:flutter/material.dart';
import 'package:moments/data/models/message.dart';

/// Action type for message context menu
enum MessageAction { reply, edit, deleteForSelf, deleteForEveryone, copy }

/// WhatsApp/IG style floating context menu with emoji reactions
class MessageContextMenu extends StatefulWidget {
  const MessageContextMenu({
    super.key,
    required this.message,
    required this.isMe,
    required this.canEdit,
    required this.onAction,
    required this.onReaction,
    required this.onDismiss,
    required this.anchorRect,
  });

  final Message message;
  final bool isMe;
  final bool canEdit;
  final void Function(MessageAction action) onAction;
  final void Function(String emoji) onReaction;
  final VoidCallback onDismiss;
  final Rect anchorRect;

  @override
  State<MessageContextMenu> createState() => _MessageContextMenuState();
}

class _MessageContextMenuState extends State<MessageContextMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Position menu above or below the message
    final showAbove = widget.anchorRect.center.dy > screenHeight / 2;

    // Calculate menu position
    double top;
    if (showAbove) {
      top = widget.anchorRect.top - 220;
      if (top < 60) top = 60;
    } else {
      top = widget.anchorRect.bottom + 8;
    }

    // Horizontal alignment
    double left;
    if (widget.isMe) {
      left = screenWidth - 270;
    } else {
      left = 16;
    }
    if (left < 16) left = 16;
    if (left + 260 > screenWidth) left = screenWidth - 270;

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(
              alpha: 0.4 * _opacityAnimation.value,
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: widget.isMe ? Alignment.topRight : Alignment.topLeft,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Emoji reactions row
                          _EmojiReactionsRow(
                            onReaction: (emoji) {
                              widget.onReaction(emoji);
                              _dismiss();
                            },
                          ),

                          Divider(
                            height: 1,
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                          ),

                          // Actions
                          _ActionItem(
                            icon: Icons.reply,
                            label: 'Reply',
                            isDark: isDark,
                            onTap: () {
                              widget.onAction(MessageAction.reply);
                              _dismiss();
                            },
                          ),

                          if (widget.message.messageType == MessageType.text)
                            _ActionItem(
                              icon: Icons.copy,
                              label: 'Copy',
                              isDark: isDark,
                              onTap: () {
                                widget.onAction(MessageAction.copy);
                                _dismiss();
                              },
                            ),

                          if (widget.isMe &&
                              widget.canEdit &&
                              widget.message.messageType == MessageType.text)
                            _ActionItem(
                              icon: Icons.edit,
                              label: 'Edit',
                              isDark: isDark,
                              onTap: () {
                                widget.onAction(MessageAction.edit);
                                _dismiss();
                              },
                            ),

                          Divider(
                            height: 1,
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                          ),

                          _ActionItem(
                            icon: Icons.delete_outline,
                            label: 'Delete for me',
                            isDark: isDark,
                            onTap: () {
                              widget.onAction(MessageAction.deleteForSelf);
                              _dismiss();
                            },
                            isDestructive: true,
                          ),

                          if (widget.isMe)
                            _ActionItem(
                              icon: Icons.delete_forever,
                              label: 'Delete for everyone',
                              isDark: isDark,
                              onTap: () {
                                widget.onAction(
                                  MessageAction.deleteForEveryone,
                                );
                                _dismiss();
                              },
                              isDestructive: true,
                            ),

                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiReactionsRow extends StatelessWidget {
  const _EmojiReactionsRow({required this.onReaction});

  final void Function(String emoji) onReaction;

  static const _reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final emoji in _reactions)
            _EmojiButton(emoji: emoji, onTap: () => onReaction(emoji)),
          GestureDetector(
            onTap: () {
              // TODO: Show emoji picker
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  const _EmojiButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 1.3),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : Colors.black87);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// Show floating context menu overlay
void showFloatingMessageMenu({
  required BuildContext context,
  required Message message,
  required bool isMe,
  required Rect anchorRect,
  required void Function(MessageAction action) onAction,
  required void Function(String emoji) onReaction,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  // Check if message can be edited (within 15 minutes)
  final timeSinceSent = DateTime.now().difference(message.createdAt);
  final canEdit = timeSinceSent.inMinutes <= 15;

  entry = OverlayEntry(
    builder: (context) => MessageContextMenu(
      message: message,
      isMe: isMe,
      canEdit: canEdit,
      anchorRect: anchorRect,
      onAction: onAction,
      onReaction: onReaction,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}
