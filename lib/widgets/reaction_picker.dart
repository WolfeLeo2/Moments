import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';

/// Common emoji reactions for moments
const List<String> kDefaultReactions = ['❤️', '😍', '🔥', '😂', '😮', '👏'];

/// A popup picker for selecting emoji reactions
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final String? currentReaction;
  final VoidCallback? onRemoveReaction;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.currentReaction,
    this.onRemoveReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderBlack,
          width: AppTheme.borderMedium,
        ),
        boxShadow: AppTheme.brutalShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in kDefaultReactions)
            _ReactionButton(
              emoji: emoji,
              isSelected: currentReaction == emoji,
              onTap: () {
                HapticService.selectionClick();
                if (currentReaction == emoji && onRemoveReaction != null) {
                  onRemoveReaction!();
                } else {
                  onReactionSelected(emoji);
                }
              },
            ),
        ],
      ),
    );
  }

  /// Show the reaction picker as a popup at the given position
  static Future<String?> show(
    BuildContext context, {
    required Offset position,
    String? currentReaction,
  }) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    return showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromCenter(center: position, width: 0, height: 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppTheme.borderBlack,
          width: AppTheme.borderMedium,
        ),
      ),
      color: AppTheme.cardWhite,
      elevation: 8,
      constraints: const BoxConstraints(maxWidth: 280),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final emoji in kDefaultReactions)
                _PopupReactionButton(
                  emoji: emoji,
                  isSelected: currentReaction == emoji,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PopupReactionButton extends StatelessWidget {
  final String emoji;
  final bool isSelected;

  const _PopupReactionButton({
    required this.emoji,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        Navigator.pop(context, emoji);
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

/// Display reaction summary (emoji + count)
class ReactionSummaryRow extends StatelessWidget {
  final List<ReactionDisplay> reactions;
  final VoidCallback? onTap;

  const ReactionSummaryRow({
    super.key,
    required this.reactions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderBlack.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < reactions.length && i < 3; i++) ...[
              Text(
                reactions[i].emoji,
                style: const TextStyle(fontSize: 14),
              ),
              if (i < reactions.length - 1 && i < 2)
                const SizedBox(width: 2),
            ],
            if (reactions.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '${reactions.fold<int>(0, (sum, r) => sum + r.count)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple display model for reactions
class ReactionDisplay {
  final String emoji;
  final int count;
  final bool userReacted;

  const ReactionDisplay({
    required this.emoji,
    required this.count,
    this.userReacted = false,
  });
}
