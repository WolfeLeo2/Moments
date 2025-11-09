import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/moment.dart';
import '../../../data/repositories/moment_repository.dart';
import '../../../widgets/spring_button.dart';

class MomentDetailPage extends StatefulWidget {
  final String momentId;

  const MomentDetailPage({
    super.key,
    required this.momentId,
  });

  @override
  State<MomentDetailPage> createState() => _MomentDetailPageState();
}

class _MomentDetailPageState extends State<MomentDetailPage> {
  Moment? _moment;
  bool _isLoading = true;
  final MomentRepository _momentRepository = MomentRepository();

  @override
  void initState() {
    super.initState();
    _loadMoment();
  }

  Future<void> _loadMoment() async {
    try {
      final moments = await _momentRepository.getMoments();
      final moment = moments.firstWhere((m) => m.id == widget.momentId);
      setState(() {
        _moment = moment;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load moment');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            _moment?.title ?? 'LOADING...',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.spacing16),
                  // Contributors avatars (placeholder for now)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                    ),
                    child: Row(
                      children: [
                        _buildContributorAvatar('User'),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          'and others',
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  // Image carousel
                  SizedBox(
                    height: 400,
                    child: PageView.builder(
                      itemCount: 1, // For now, single image
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing24,
                          ),
                          child: Column(
                            children: [
                              // Polaroid card
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(6, 6),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Image
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: AspectRatio(
                                        aspectRatio: 3 / 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: _moment?.imageUrl != null
                                              ? Image.network(
                                                  _moment!.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.error,
                                                          size: 48,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    }
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Icon(Icons.image,
                                                        size: 48),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    // Caption section in polaroid bottom
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        _moment?.caption ?? '',
                                        style:
                                            context.textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'Courier',
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  // Bottom bar with location, emoji, and preview
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    margin: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Location tag
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brightYellow,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _moment?.location ?? 'Unknown',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        // Emoji button
                        SpringButton(
                          onTap: () {
                            // TODO: Add emoji/sticker picker
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.emoji_emotions,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        // Preview/Share button
                        SpringButton(
                          onTap: () {
                            // TODO: Add share functionality
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              'SHARE',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildContributorAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
