import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/profile.dart';
import '../../../widgets/avatar_image.dart';
import '../providers/find_friends_providers.dart';

/// Find Friends page with Search, QR Code, Contacts Sync, and People Nearby.
class FindFriendsPage extends ConsumerStatefulWidget {
  const FindFriendsPage({super.key});

  @override
  ConsumerState<FindFriendsPage> createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends ConsumerState<FindFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _searchQuery = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query.trim());
    });
  }

  Future<void> _sendRequest(Profile profile) async {
    final sending = ref.read(sendingRequestsProvider);
    if (sending.contains(profile.id)) return;
    ref.read(sendingRequestsProvider.notifier).add(profile.id);
    HapticService.lightTap();

    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.sendFriendRequestById(profile.id);
      if (mounted) {
        ref.read(sendingRequestsProvider.notifier).remove(profile.id);
        ref.invalidate(sentRequestsProvider);
        ref.invalidate(friendshipStatusProvider(userId: profile.id));
      }
    } catch (e) {
      if (mounted) {
        ref.read(sendingRequestsProvider.notifier).remove(profile.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Contacts Sync ─────────────────────────────────────────────────

  Future<void> _syncContacts() async {
    HapticService.lightTap();

    await ref.read(contactMatchesProvider.notifier).syncContacts();
    if (mounted) {
      final state = ref.read(contactMatchesProvider);
      if (state is AsyncError && state.error == 'permission_denied') {
        _showPermissionDeniedDialog('Contacts');
      }
    }
  }

  // ── People Nearby ─────────────────────────────────────────────────

  Future<void> _loadNearbyUsers() async {
    HapticService.lightTap();
    await ref.read(nearbyUsersProvider.notifier).loadNearby();
    if (mounted) {
      final state = ref.read(nearbyUsersProvider);
      if (state is AsyncError && state.error == 'permission_denied') {
        _showPermissionDeniedDialog('Location');
      }
    }
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('$permissionName Access'),
        content: Text(
          'Please allow $permissionName access in Settings to use this feature.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── QR Code ───────────────────────────────────────────────────────

  void _showMyQRCode(String inviteCode) {
    HapticService.lightTap();
    final profile = ref.read(currentUserProfileProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarImage(
              userId: profile?.id ?? '',
              size: 72,
              borderWidth: 0,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              profile?.displayName ?? profile?.username ?? '',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            if (profile?.username != null) ...[
              const SizedBox(height: 2),
              Text(
                '@${profile!.username}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textGray,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: QrImageView(
                data: 'moments://invite/$inviteCode',
                version: QrVersions.auto,
                size: 200,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.textDark,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to add me',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundBeige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                inviteCode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      HapticService.lightTap();
                      Share.share(
                        'Add me on Moments! My invite code: $inviteCode',
                      );
                    },
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRScanner() {
    HapticService.lightTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    ).then((inviteCode) {
      if (inviteCode != null && inviteCode is String && mounted) {
        _handleScannedCode(inviteCode);
      }
    });
  }

  Future<void> _handleScannedCode(String code) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.sendFriendRequest(code);
      if (mounted) {
        ref.invalidate(sentRequestsProvider);
        ref.invalidate(friendsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final inviteCode = profileAsync.value?.inviteCode ?? '';
    final searchAsync = _searchQuery.isNotEmpty
        ? ref.watch(searchResultsProvider(query: _searchQuery))
        : const AsyncData<List<Profile>>([]);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Find Friends',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),

          // Search results
          if (_searchQuery.isNotEmpty)
            _buildSearchResults(searchAsync),

          // Quick actions (when not searching)
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 8),
            _buildQRSection(inviteCode),
            const SizedBox(height: 16),
            _buildContactsSection(),
            const SizedBox(height: 16),
            _buildNearbySection(),
            const SizedBox(height: 100),
          ],
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: 'Search by username or phone number',
        placeholderStyle: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.grey.shade400,
        ),
        style: GoogleFonts.inter(fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: null,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(
            CupertinoIcons.search,
            size: 20,
            color: Colors.grey.shade400,
          ),
        ),
        suffix: _searchController.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  },
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              )
            : null,
        onChanged: (v) {
          setState(() {}); // rebuild for suffix icon
          _onSearchChanged(v);
        },
      ),
    );
  }

  // ── Search Results ────────────────────────────────────────────────

  Widget _buildSearchResults(AsyncValue<List<Profile>> searchAsync) {
    return searchAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => _buildEmptyCard('Search failed. Try again.'),
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.person_crop_circle_badge_xmark,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'No users found',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: results.map((profile) {
            return _UserTile(
              profile: profile,
              subtitle:
                  profile.username != null ? '@${profile.username}' : null,
              onSendRequest: () => _sendRequest(profile),
            );
          }).toList(),
        );
      },
    );
  }

  // ── QR Code Section ───────────────────────────────────────────────

  Widget _buildQRSection(String inviteCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('QR Code', CupertinoIcons.qrcode),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.qrcode,
                title: 'My QR Code',
                subtitle: 'Let friends scan to add you',
                onTap: () => _showMyQRCode(inviteCode),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.qrcode_viewfinder,
                title: 'Scan Code',
                subtitle: 'Scan a friend\'s QR code',
                onTap: _showQRScanner,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Contacts Section ──────────────────────────────────────────────

  Widget _buildContactsSection() {
    final contactsAsync = ref.watch(contactMatchesProvider);
    final notSynced = contactsAsync.value == null && !contactsAsync.isLoading && !contactsAsync.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Contacts', CupertinoIcons.person_2),
        const SizedBox(height: 8),
        if (notSynced)
          _buildActionCard(
            icon: CupertinoIcons.person_crop_circle_badge_plus,
            title: 'Sync Contacts',
            subtitle: 'Find friends from your contacts',
            onTap: contactsAsync.isLoading ? null : _syncContacts,
            isLoading: contactsAsync.isLoading,
          )
        else
          contactsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyCard('Could not load contacts'),
            data: (matches) {
              if (matches == null || matches.isEmpty) {
                return _buildEmptyCard('No contacts on Moments yet');
              }
              return Column(
                children: matches
                    .map((profile) => _UserTile(
                          profile: profile,
                          subtitle: 'From your contacts',
                          onSendRequest: () => _sendRequest(profile),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  // ── Nearby Section ────────────────────────────────────────────────

  Widget _buildNearbySection() {
    final nearbyAsync = ref.watch(nearbyUsersProvider);
    final notSynced = nearbyAsync.value == null && !nearbyAsync.isLoading && !nearbyAsync.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('People Nearby', CupertinoIcons.location),
        const SizedBox(height: 8),
        if (notSynced)
          _buildActionCard(
            icon: CupertinoIcons.location_circle,
            title: 'Discover Nearby',
            subtitle: 'Find people with moments near you',
            onTap: nearbyAsync.isLoading ? null : _loadNearbyUsers,
            isLoading: nearbyAsync.isLoading,
          )
        else
          nearbyAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyCard('Could not find nearby people'),
            data: (users) {
              if (users == null || users.isEmpty) {
                return _buildEmptyCard('No one nearby yet');
              }
              return Column(
                children: users.map((user) {
                  final distanceKm =
                      (user['distance_km'] as num?)?.toDouble() ?? 0;
                  final distanceLabel = distanceKm < 1
                      ? '${(distanceKm * 1000).round()}m away'
                      : '${distanceKm.toStringAsFixed(1)}km away';
                  final userId = user['id'] as String;
                  final profile = Profile(
                    id: userId,
                    username: user['username'] as String?,
                    displayName: user['display_name'] as String?,
                    avatarUrl: user['avatar_url'] as String?,
                    inviteCode: user['invite_code'] as String? ?? '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  return _NearbyTile(
                    profile: profile,
                    distanceLabel: distanceLabel,
                    onSendRequest: () => _sendRequest(profile),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textGray),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CupertinoActivityIndicator(),
                  )
                : Icon(icon, size: 24, color: AppTheme.primaryBlue),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textGray,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// User Tile (with reactive friendship status)
// ═════════════════════════════════════════════════════════════════════

class _UserTile extends ConsumerWidget {
  const _UserTile({
    required this.profile,
    this.subtitle,
    required this.onSendRequest,
  });

  final Profile profile;
  final String? subtitle;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(userId: profile.id));
    final sending = ref.watch(sendingRequestsProvider);
    final isSending = sending.contains(profile.id);
    final status = statusAsync.value ?? 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          AvatarImage(
            userId: profile.id,
            size: 44,
            borderWidth: 0,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? profile.username ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textGray,
                    ),
                  ),
              ],
            ),
          ),
          _FriendshipButton(
            status: status,
            isSending: isSending,
            onSendRequest: onSendRequest,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Friendship Button (shared by UserTile and NearbyTile)
// ═════════════════════════════════════════════════════════════════════

class _FriendshipButton extends StatelessWidget {
  const _FriendshipButton({
    required this.status,
    required this.isSending,
    required this.onSendRequest,
  });

  final String status;
  final bool isSending;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Friends',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGray,
          ),
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Pending',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlue,
          ),
        ),
      );
    }

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: AppTheme.primaryBlue,
      borderRadius: BorderRadius.circular(8),
      minSize: 0,
      onPressed: isSending ? null : onSendRequest,
      child: isSending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(color: Colors.white),
            )
          : Text(
              'Add',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Nearby Tile (with distance label)
// ═════════════════════════════════════════════════════════════════════

class _NearbyTile extends ConsumerWidget {
  const _NearbyTile({
    required this.profile,
    required this.distanceLabel,
    required this.onSendRequest,
  });

  final Profile profile;
  final String distanceLabel;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(userId: profile.id));
    final sending = ref.watch(sendingRequestsProvider);
    final isSending = sending.contains(profile.id);
    final status = statusAsync.value ?? 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          AvatarImage(
            userId: profile.id,
            size: 44,
            borderWidth: 0,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? profile.username ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 12,
                      color: AppTheme.textGray,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      distanceLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _FriendshipButton(
            status: status,
            isSending: isSending,
            onSendRequest: onSendRequest,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// QR Scanner Page (public for reuse in invite sheet)
// ═════════════════════════════════════════════════════════════════════

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
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
        Navigator.pop(context, inviteCode);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              'Point your camera at a Moments QR code',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
