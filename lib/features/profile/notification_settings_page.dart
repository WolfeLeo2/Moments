import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

/// Model for notification preferences
class NotificationPreferences {
  final String id;
  final String userId;
  final bool pushEnabled;
  final bool friendRequestEnabled;
  final bool newMessageEnabled;
  final bool momentInviteEnabled;
  final bool systemEnabled;
  final bool promoEnabled;

  NotificationPreferences({
    required this.id,
    required this.userId,
    this.pushEnabled = true,
    this.friendRequestEnabled = true,
    this.newMessageEnabled = true,
    this.momentInviteEnabled = true,
    this.systemEnabled = true,
    this.promoEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      friendRequestEnabled: json['friend_request_enabled'] as bool? ?? true,
      newMessageEnabled: json['new_message_enabled'] as bool? ?? true,
      momentInviteEnabled: json['moment_invite_enabled'] as bool? ?? true,
      systemEnabled: json['system_enabled'] as bool? ?? true,
      promoEnabled: json['promo_enabled'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? friendRequestEnabled,
    bool? newMessageEnabled,
    bool? momentInviteEnabled,
    bool? systemEnabled,
    bool? promoEnabled,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      friendRequestEnabled: friendRequestEnabled ?? this.friendRequestEnabled,
      newMessageEnabled: newMessageEnabled ?? this.newMessageEnabled,
      momentInviteEnabled: momentInviteEnabled ?? this.momentInviteEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
      promoEnabled: promoEnabled ?? this.promoEnabled,
    );
  }
}

/// Provider for notification preferences
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences?>((ref) async {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        final newPrefs = await supabase
            .from('notification_preferences')
            .insert({'user_id': userId})
            .select()
            .single();
        return NotificationPreferences.fromJson(newPrefs);
      }

      return NotificationPreferences.fromJson(response);
    });

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationPreferences? _preferences;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await ref.read(notificationPreferencesProvider.future);
    if (mounted) {
      setState(() {
        _preferences = prefs;
      });
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    if (_preferences == null) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('notification_preferences')
          .update({key: value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', _preferences!.id);

      // Update local state
      setState(() {
        switch (key) {
          case 'push_enabled':
            _preferences = _preferences!.copyWith(pushEnabled: value);
            break;
          case 'friend_request_enabled':
            _preferences = _preferences!.copyWith(friendRequestEnabled: value);
            break;
          case 'new_message_enabled':
            _preferences = _preferences!.copyWith(newMessageEnabled: value);
            break;
          case 'moment_invite_enabled':
            _preferences = _preferences!.copyWith(momentInviteEnabled: value);
            break;
          case 'system_enabled':
            _preferences = _preferences!.copyWith(systemEnabled: value);
            break;
          case 'promo_enabled':
            _preferences = _preferences!.copyWith(promoEnabled: value);
            break;
        }
      });

      ref.invalidate(notificationPreferencesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _preferences == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master switch
                      _buildMasterSwitch(),

                      const SizedBox(height: 24),

                      // Category header
                      Text(
                        'NOTIFICATION TYPES',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Individual toggles
                      _buildToggleTile(
                        icon: HugeIcons.strokeRoundedUserAdd01,
                        iconColor: AppTheme.primaryBlue,
                        title: 'Friend Requests',
                        subtitle: 'When someone sends you a friend request',
                        value: _preferences!.friendRequestEnabled,
                        enabled: _preferences!.pushEnabled,
                        onChanged: (v) =>
                            _updatePreference('friend_request_enabled', v),
                      ),

                      _buildToggleTile(
                        icon: HugeIcons.strokeRoundedMessage01,
                        iconColor: Colors.green,
                        title: 'New Messages',
                        subtitle: 'When you receive a new chat message',
                        value: _preferences!.newMessageEnabled,
                        enabled: _preferences!.pushEnabled,
                        onChanged: (v) =>
                            _updatePreference('new_message_enabled', v),
                      ),

                      _buildToggleTile(
                        icon: HugeIcons.strokeRoundedImageAdd02,
                        iconColor: AppTheme.electricPurple,
                        title: 'Moment Invites',
                        subtitle: 'When someone invites you to collaborate',
                        value: _preferences!.momentInviteEnabled,
                        enabled: _preferences!.pushEnabled,
                        onChanged: (v) =>
                            _updatePreference('moment_invite_enabled', v),
                      ),

                      _buildToggleTile(
                        icon: HugeIcons.strokeRoundedNotification01,
                        iconColor: Colors.orange,
                        title: 'System Updates',
                        subtitle: 'Important app updates and announcements',
                        value: _preferences!.systemEnabled,
                        enabled: _preferences!.pushEnabled,
                        onChanged: (v) =>
                            _updatePreference('system_enabled', v),
                      ),

                      _buildToggleTile(
                        icon: HugeIcons.strokeRoundedGift,
                        iconColor: AppTheme.neonPink,
                        title: 'Promotions & Tips',
                        subtitle: 'Special offers and app tips',
                        value: _preferences!.promoEnabled,
                        enabled: _preferences!.pushEnabled,
                        onChanged: (v) => _updatePreference('promo_enabled', v),
                      ),

                      const SizedBox(height: 32),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedInformationCircle,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can also manage notifications in your device settings.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildMasterSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: _preferences!.pushEnabled
            ? AppTheme.primaryBlue
            : Colors.grey[300],
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16.sp),
          side: BorderSide(color: Colors.black, width: AppTheme.borderThin),
        ),
        shadows: AppTheme.brutalShadowSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              color: _preferences!.pushEnabled
                  ? Colors.white
                  : Colors.grey[600]!,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _preferences!.pushEnabled
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _preferences!.pushEnabled
                      ? 'You\'ll receive notifications'
                      : 'All notifications are off',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _preferences!.pushEnabled
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _preferences!.pushEnabled,
            onChanged: (v) => _updatePreference('push_enabled', v),
            activeColor: Colors.white,
            activeTrackColor: Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required dynamic icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ShapeDecoration(
        color: enabled ? AppTheme.cardWhite : Colors.grey[100],
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(12.sp),
          side: BorderSide(
            color: enabled ? AppTheme.borderBlack : Colors.grey[300]!,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? iconColor.withValues(alpha: 0.1)
                : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: icon,
            color: enabled ? iconColor : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: enabled ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        trailing: Switch.adaptive(
          value: value && enabled,
          onChanged: enabled ? onChanged : null,
          activeColor: iconColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
