import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/providers/realtime_providers.dart';

class InviteBottomSheet extends ConsumerStatefulWidget {
  final String inviteCode;

  const InviteBottomSheet({super.key, required this.inviteCode});

  @override
  ConsumerState<InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends ConsumerState<InviteBottomSheet> {
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest() async {
    final inviteCode = _inviteCodeController.text.trim().toUpperCase();
    if (inviteCode.isEmpty) {
      context.showErrorSnackBar('Please enter an invite code');
      return;
    }

    if (inviteCode.length != 6) {
      context.showErrorSnackBar('Invite code must be 6 characters');
      return;
    }

    try {
      await ref.read(addFriendProvider.notifier).sendFriendRequest(inviteCode);
      _inviteCodeController.clear();
      if (mounted) {
        context.showSuccessSnackBar('Friend request sent!');
        // Invalidate cache to refresh lists
        ref.invalidate(friendsListProvider);
        ref.invalidate(pendingRequestsProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    context.showSuccessSnackBar('Invite code copied!');
  }

  void _shareInviteCode(String code) {
    Share.share(
      'Join me on Moments! Use my invite code: $code',
      subject: 'Join me on Moments',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundBeige,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 3),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Invite Friends',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your code to connect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Invite code card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'YOUR CODE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.inviteCode,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          fontFamily: 'monospace',
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _copyInviteCode(widget.inviteCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCopy01,
                                size: 20,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _shareInviteCode(widget.inviteCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedShare01,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Share',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Divider
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 24),

                // Add friend section
                Text(
                  'Add a Friend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ENTER CODE',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      letterSpacing: 2,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 3,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight02,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        _sendFriendRequest();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  onSubmitted: (_) {
                    _sendFriendRequest();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
