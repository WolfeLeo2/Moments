import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/core/services/haptic_service.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/widgets/avatar_image.dart';

class InviteBottomSheet extends ConsumerStatefulWidget {
  final String inviteCode;

  const InviteBottomSheet({super.key, required this.inviteCode});

  @override
  ConsumerState<InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends ConsumerState<InviteBottomSheet> {
  final TextEditingController _inviteCodeController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasScanned = false;
  MobileScannerController? _scannerController;

  static const _pageLabels = ['Invite Code', 'My QR Code', 'Scan QR'];

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _pageController.dispose();
    _scannerController?.dispose();
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
    HapticService.lightTap();
    Clipboard.setData(ClipboardData(text: code));
    context.showSuccessSnackBar('Invite code copied!');
  }

  void _shareInviteCode(String code) {
    HapticService.lightTap();
    Share.share(
      'Join me on Moments! Use my invite code: $code',
      subject: 'Join me on Moments',
    );
  }

  void _onQRDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      String? inviteCode;
      if (rawValue.startsWith('moments://invite/')) {
        inviteCode = rawValue.replaceFirst('moments://invite/', '');
      } else if (rawValue.length == 6 &&
          RegExp(r'^[A-Z0-9]+$').hasMatch(rawValue)) {
        inviteCode = rawValue;
      }

      if (inviteCode != null) {
        _hasScanned = true;
        HapticService.mediumTap();
        _scannerController?.dispose();
        _scannerController = null;
        Navigator.pop(context);
        _handleScannedCode(inviteCode);
        return;
      }
    }
  }

  Future<void> _handleScannedCode(String code) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.sendFriendRequest(code);
      if (mounted) {
        ref.invalidate(sentRequestsProvider);
        ref.invalidate(friendsListProvider);
        context.showSuccessSnackBar('Friend request sent!');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──
          Text(
            'Invite Friends',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your code or scan to connect',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 16),

          // ── Page indicators ──
          _buildPageIndicator(),
          const SizedBox(height: 16),

          // ── PageView ──
          Flexible(
            child: SizedBox(
              height: 380 + bottomInset,
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  // Lazily create scanner when reaching page 2
                  if (page == 2 && _scannerController == null) {
                    _scannerController = MobileScannerController(
                      detectionSpeed: DetectionSpeed.normal,
                      facing: CameraFacing.back,
                    );
                    setState(() {});
                  }
                },
                children: [
                  _buildInviteCodePage(bottomInset),
                  _buildQRCodePage(),
                  _buildScanQRPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page Indicator ──────────────────────────────────────────────

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = _currentPage == index;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 14.0 : 10.0,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3))
                  : null,
            ),
            child: Text(
              _pageLabels[index],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textGray,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Page 1: Invite Code ─────────────────────────────────────────

  Widget _buildInviteCodePage(double bottomInset) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        children: [
          // Code card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'YOUR CODE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.inviteCode,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Copy & Share buttons
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _copyInviteCode(widget.inviteCode),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.doc_on_doc,
                          size: 18, color: AppTheme.textDark),
                      const SizedBox(width: 6),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _shareInviteCode(widget.inviteCode),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.share,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Divider
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 20),

          // Enter a friend's code
          Text(
            'Enter a friend\'s code',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 10),
          CupertinoTextField(
            controller: _inviteCodeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            placeholder: 'ENTER CODE',
            placeholderStyle: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.grey.shade300,
              letterSpacing: 4,
            ),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                minSize: 0,
                padding: const EdgeInsets.all(6),
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
                onPressed: () {
                  _sendFriendRequest();
                  Navigator.pop(context);
                },
                child: const Icon(
                  CupertinoIcons.arrow_right,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            onSubmitted: (_) {
              _sendFriendRequest();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ── Page 2: My QR Code ──────────────────────────────────────────

  Widget _buildQRCodePage() {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AvatarImage(
            userId: profile?.id ?? '',
            size: 64,
            borderWidth: 0,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          Text(
            profile?.displayName ?? profile?.username ?? '',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          if (profile?.username != null) ...[
            const SizedBox(height: 2),
            Text(
              '@${profile!.username}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textGray,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: QrImageView(
              data: 'moments://invite/${widget.inviteCode}',
              version: QrVersions.auto,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.textDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan to add me',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.inviteCode,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 3: Scan QR Code ────────────────────────────────────────

  Widget _buildScanQRPage() {
    if (_scannerController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.qrcode_viewfinder,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Swipe here to start scanning',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onQRDetect,
                  ),
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Point camera at a Moments QR code',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
