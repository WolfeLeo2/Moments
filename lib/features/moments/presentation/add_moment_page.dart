import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/repositories/moment_repository.dart';
import '../../../widgets/bouncing_button.dart';

class AddMomentPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? imagePath;

  const AddMomentPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.imagePath,
  });

  @override
  State<AddMomentPage> createState() => _AddMomentPageState();
}

class _AddMomentPageState extends State<AddMomentPage> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final MomentRepository _momentRepository = MomentRepository();

  File? _imageFile;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();

    // Set image if provided
    if (widget.imagePath != null) {
      _imageFile = File(widget.imagePath!);
    }

    // Set initial coordinates
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    // Get location automatically
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(AppConstants.locationServiceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(AppConstants.locationPermissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(AppConstants.locationPermissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _createMoment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      context.showErrorSnackBar('Please select an image');
      return;
    }

    if (_latitude == null || _longitude == null) {
      context.showErrorSnackBar('Location is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final caption = _captionController.text.trim();

      await _momentRepository.createMoment(
        title: caption.isEmpty
            ? 'Moment at ${_locationName ?? 'Unknown'}'
            : caption,
        location:
            _locationName ??
            'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
        latitude: _latitude!,
        longitude: _longitude!,
        imageFile: _imageFile,
        description: caption.isNotEmpty ? caption : null,
      );

      if (mounted) {
        context.showSuccessSnackBar(AppConstants.momentCreated);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to create moment: $e');
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
        title: Text('NEW MOMENT', style: context.textTheme.headlineSmall),
        leading: BouncingButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              if (_imageFile != null)
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Image.file(
                      _imageFile!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: AppTheme.spacing24),

              // Caption Field
              TextFormField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Add a caption to your moment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  filled: true,
                  fillColor: AppTheme.cardWhite,
                ),
              ),

              const SizedBox(height: AppTheme.spacing24),

              // Location Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: _isGettingLocation
                      ? Colors.orange.shade50
                      : (_latitude != null && _longitude != null)
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: _isGettingLocation
                        ? Colors.orange.shade200
                        : (_latitude != null && _longitude != null)
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isGettingLocation)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _latitude != null && _longitude != null
                            ? Icons.location_on
                            : Icons.location_off,
                        color: _latitude != null && _longitude != null
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        size: 16,
                      ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        _isGettingLocation
                            ? 'Getting your location...'
                            : (_latitude != null && _longitude != null)
                            ? 'Location: ${_locationName ?? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'}'
                            : 'Location unavailable',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: _isGettingLocation
                              ? Colors.orange.shade800
                              : (_latitude != null && _longitude != null)
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                    if (_latitude != null &&
                        _longitude != null &&
                        !_isGettingLocation)
                      BouncingButton(
                        onPressed: _getCurrentLocation,
                        child: Icon(
                          Icons.refresh,
                          size: 20,
                          color: Colors.green.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: BouncingButton(
                  onPressed: _isLoading ? null : _createMoment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing16,
                    ),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AppTheme.textGray
                          : AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusCircle,
                      ),
                      boxShadow: _isLoading ? null : AppTheme.buttonShadow,
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Share Moment',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
