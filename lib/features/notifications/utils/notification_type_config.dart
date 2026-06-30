import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/notifications/models/notification_item.dart';

class NotificationTypeConfig {
  final Color accentColor;
  final Color backgroundColor;
  final IconData icon;
  final String label;

  const NotificationTypeConfig({
    required this.accentColor,
    required this.backgroundColor,
    required this.icon,
    required this.label,
  });

  static NotificationTypeConfig forType(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return NotificationTypeConfig(
          accentColor: AppTheme.primaryBlue,
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
          icon: CupertinoIcons.person_add_solid,
          label: 'Friend Request',
        );
      case NotificationType.collaborationInvite:
      case NotificationType.momentInvite:
        return NotificationTypeConfig(
          accentColor: AppTheme.electricPurple,
          backgroundColor: AppTheme.electricPurple.withValues(alpha: 0.08),
          icon: CupertinoIcons.person_2,
          label: 'Collaboration',
        );
      case NotificationType.momentLike:
        return NotificationTypeConfig(
          accentColor: const Color(0xFFE91E63),
          backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.08),
          icon: CupertinoIcons.heart_fill,
          label: 'Reaction',
        );
      case NotificationType.newMoment:
        return NotificationTypeConfig(
          accentColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.08),
          icon: CupertinoIcons.photo,
          label: 'New Moment',
        );
      case NotificationType.system:
        return NotificationTypeConfig(
          accentColor: const Color(0xFFFF9800),
          backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.08),
          icon: CupertinoIcons.settings,
          label: 'System',
        );
      case NotificationType.promo:
        return NotificationTypeConfig(
          accentColor: AppTheme.neonPink,
          backgroundColor: AppTheme.neonPink.withValues(alpha: 0.08),
          icon: CupertinoIcons.gift,
          label: 'Promo',
        );
      case NotificationType.other:
        return NotificationTypeConfig(
          accentColor: Colors.grey,
          backgroundColor: Colors.grey.withValues(alpha: 0.08),
          icon: CupertinoIcons.bell,
          label: 'Notification',
        );
    }
  }
}
