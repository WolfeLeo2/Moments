import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/widgets/spring_button.dart';
import '../../data/models/moment.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/share_service.dart';
import 'moment_share_card.dart';

/// Beautiful share bottom sheet inspired by iOS share sheet and Instagram sharing.
/// Features live preview with style switching and one-tap sharing.
class ShareBottomSheet extends StatefulWidget {
  final Moment moment;
  final String? imageUrl;
  final String? localImagePath;

  const ShareBottomSheet({
    super.key,
    required this.moment,
    this.imageUrl,
    this.localImagePath,
  });

  /// Show the share bottom sheet
  static Future<void> show({
    required BuildContext context,
    required Moment moment,
    String? imageUrl,
    String? localImagePath,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        moment: moment,
        imageUrl: imageUrl,
        localImagePath: localImagePath,
      ),
    );
  }

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  ShareCardStyle _selectedStyle = ShareCardStyle.polaroid;
  bool _isSharing = false;

  final List<_StyleOption> _styles = [
    _StyleOption(
      style: ShareCardStyle.polaroid,
      name: 'Polaroid',
      hugeIcon: HugeIcons.strokeRoundedImage02,
    ),
    _StyleOption(
      style: ShareCardStyle.minimal,
      name: 'Minimal',
      hugeIcon: HugeIcons.strokeRoundedSquare,
    ),
    _StyleOption(
      style: ShareCardStyle.story,
      name: 'Story',
      hugeIcon: HugeIcons.strokeRoundedSmartPhone01,
    ),
    _StyleOption(
      style: ShareCardStyle.postcard,
      name: 'Postcard',
      hugeIcon: HugeIcons.strokeRoundedMail01,
    ),
  ];

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);

    // Add slight delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 100));

    final imagePath = await ShareService.captureWidgetAsImage(_repaintKey);

    if (imagePath != null) {
      final shareText = ShareService.generateShareText(widget.moment);
      await ShareService.shareImage(imagePath: imagePath, text: shareText);
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge + 8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppTheme.spacing12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacing24,
              AppTheme.spacing16,
              AppTheme.spacing24,
              AppTheme.spacing16,
            ),
            child: Row(
              children: [
                Text(
                  'SHARE MOMENT',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(letterSpacing: 1.5),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textGray),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.cardWhite,
                  ),
                ),
              ],
            ),
          ),

          // Preview card (scrollable for different sizes)
          SizedBox(
            height: _getPreviewHeight(),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: MomentShareCard(
                    moment: widget.moment,
                    imageUrl: widget.imageUrl,
                    localImagePath: widget.localImagePath,
                    style: _selectedStyle,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: AppTheme.spacing16),

          // Style selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STYLE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textGray,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: AppTheme.spacing12),
                Row(
                  children: _styles.map((option) {
                    final isSelected = option.style == _selectedStyle;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStyle = option.style),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing4,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.borderGray,
                              width: AppTheme.borderThin,
                            ),
                            boxShadow: isSelected
                                ? AppTheme.brutalShadow
                                : null,
                          ),
                          child: Column(
                            children: [
                              HugeIcon(
                                icon: option.hugeIcon,
                                size: 22,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textGray,
                              ),
                              SizedBox(height: AppTheme.spacing4 + 2),
                              Text(
                                option.name,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textGray,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: AppTheme.spacing24),

          // Share actions
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacing24,
              0,
              AppTheme.spacing24,
              AppTheme.spacing16 + bottomPadding,
            ),
            child: Column(
              children: [
                // Share button
                SpringButton(
                  scaleFactor: 0.92,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.borderBlack,
                        width: AppTheme.borderMedium,
                      ),
                      boxShadow: AppTheme.brutalShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSharing ? null : _shareImage,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        child: Center(
                          child: _isSharing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedShare08,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: AppTheme.spacing8),
                                    Text(
                                      'SHARE IMAGE',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spacing12),

                // Save button - Vibrant Green with Neubrutalism shadow
                SpringButton(
                  scaleFactor: 0.92,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantGreen,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.borderBlack,
                        width: AppTheme.borderMedium,
                      ),
                      boxShadow: AppTheme.brutalShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          // Could implement save to gallery feature
                        },
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedDownload04,
                                size: 22,
                                color: AppTheme.borderBlack,
                              ),
                              SizedBox(width: AppTheme.spacing8),
                              Text(
                                'SAVE IMAGE',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppTheme.borderBlack,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                              ),
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
        ],
      ),
    );
  }

  double _getPreviewHeight() {
    switch (_selectedStyle) {
      case ShareCardStyle.polaroid:
        return 380;
      case ShareCardStyle.minimal:
        return 380;
      case ShareCardStyle.story:
        return 420;
      case ShareCardStyle.postcard:
        return 280;
    }
  }
}

class _StyleOption {
  final ShareCardStyle style;
  final String name;
  final dynamic hugeIcon; 

  const _StyleOption({
    required this.style,
    required this.name,
    required this.hugeIcon,
  });
}
