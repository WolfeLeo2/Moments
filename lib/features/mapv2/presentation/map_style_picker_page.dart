import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/map_v2_providers.dart';

/// A one-off page shown after first login (or accessible from Settings)
/// where the user picks between the native Mapbox map or the classic map view.
class MapStylePickerPage extends ConsumerStatefulWidget {
  /// If true, this is a one-off picker shown after login.
  /// The user must pick a style to continue.
  /// If false, it's opened from settings and has a back button.
  final bool isOnboarding;

  const MapStylePickerPage({super.key, this.isOnboarding = false});

  @override
  ConsumerState<MapStylePickerPage> createState() =>
      _MapStylePickerPageState();
}

class _MapStylePickerPageState extends ConsumerState<MapStylePickerPage> {
  bool? _selectedV2;

  @override
  void initState() {
    super.initState();
    _selectedV2 = ref.read(useMapV2Provider);
  }

  void _confirm() async {
    if (_selectedV2 == null) return;
    MapStylePrefs.setUseV2(ref, _selectedV2!);
    if (widget.isOnboarding) {
      await MapStylePrefs.markPickerSeen();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              backgroundColor: AppTheme.backgroundBeige,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                'Map Style',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isOnboarding) ...[
                const SizedBox(height: 48),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation01,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Your Map',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick how you want to explore your moments on the map. You can change this later in Settings.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Option 1: Native Mapbox (V2)
              _buildOption(
                title: 'Immersive Map',
                description:
                    'Full 3D terrain, smooth animations, and native performance. The default experience.',
                icon: HugeIcons.strokeRoundedEarth,
                isSelected: _selectedV2 == true,
                onTap: () => setState(() => _selectedV2 = true),
              ),

              const SizedBox(height: 16),

              // Option 2: Classic FlutterMap
              _buildOption(
                title: 'Classic Map',
                description:
                    'Lightweight 2D map with fast tile loading. Great for low-end devices.',
                icon: HugeIcons.strokeRoundedMapsLocation01,
                isSelected: _selectedV2 == false,
                onTap: () => setState(() => _selectedV2 = false),
              ),

              const Spacer(),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: _selectedV2 != null ? Colors.black : Colors.grey[300],
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _selectedV2 != null ? _confirm : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        widget.isOnboarding ? 'Continue' : 'Save',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedV2 != null
                              ? Colors.white
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String description,
    required dynamic icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    size: 24,
                    color: isSelected ? AppTheme.primaryBlue : Colors.grey[600]!,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGray,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
