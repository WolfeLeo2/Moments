import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:moments/data/models/moment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Mock Supabase to avoid initialization errors if any widget tries to access it
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  setUpAll(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase with dummy values
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'dummy-key',
      debug: false,
    );
  });

  testWidgets('MomentDetailsPage uses CachedImage with correct cacheKey', (
    WidgetTester tester,
  ) async {
    // Setup
    final moment = Moment(
      id: 'moment-1',
      title: 'Test Moment',
      location: 'Test Location',
      latitude: 0,
      longitude: 0,
      createdAt: DateTime.now(),
      timestamp: DateTime.now(),
      mediaPath: 'path/to/image.jpg',
      imageUrl: 'https://example.com/image.jpg', // Fallback URL
      userId: 'user-1',
      momentGroupId: 'group-1',
    );

    // Build the widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MomentDetailsPage(
            locationName: 'Test Location',
            moments: [moment],
          ),
        ),
      ),
    );

    // Allow animations to settle (MomentDetailsPage has spring animations)
    // pumpAndSettle might timeout if animations are complex or looping
    await tester.pump(const Duration(seconds: 2));

    // Verify CachedNetworkImage is present
    final cachedImageFinder = find.byType(CachedNetworkImage);
    expect(cachedImageFinder, findsOneWidget);

    // Verify properties
    final cachedImage = tester.widget<CachedNetworkImage>(cachedImageFinder);
    expect(cachedImage.imageUrl, 'https://example.com/image.jpg');
    expect(cachedImage.cacheKey, 'path/to/image.jpg');
  });
}
