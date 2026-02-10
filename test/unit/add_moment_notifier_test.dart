import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/features/moments/providers/add_moment_notifier.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/data/models/moment.dart';
import 'package:image_picker/image_picker.dart';

class MockMomentRepository extends Mock implements MomentRepository {}

void main() {
  late MockMomentRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockMomentRepository();
    container = ProviderContainer(
      overrides: [
        addMomentProvider.overrideWith(
          (ref) => AddMomentNotifier(mockRepository),
        ),
      ],
    );

    // Register fallback values for mocktail
    registerFallbackValue(File('dummy'));
    registerFallbackValue(<File>[]);
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'createMoment calls repository.createMomentsBatch with ALL images',
    () async {
      // Setup
      final notifier = container.read(addMomentProvider.notifier);
      final image1 = XFile('path/to/image1.jpg');
      final image2 = XFile('path/to/image2.jpg');
      final images = [image1, image2];

      // Initialize state with images and location
      notifier.initialize(
        imagePaths: [image1.path, image2.path],
        initialLatitude: 37.7749,
        initialLongitude: -122.4194,
      );

      // Mock getNearbyGroups to avoid error
      when(
        () => mockRepository.getNearbyGroups(any(), any()),
      ).thenAnswer((_) async => []);

      // Mock repository response for createMomentsBatch
      when(
        () => mockRepository.createMomentsBatch(
          any(), // List<File>
          any(), // title
          any(), // caption
          any(), // locationName
          any(), // latitude
          any(), // longitude
          isPrivate: any(named: 'isPrivate'),
          momentGroupId: any(named: 'momentGroupId'),
        ),
      ).thenAnswer(
        (_) async => [
          Moment(
            id: 'moment-id-1',
            title: 'Title',
            location: 'Location',
            latitude: 0,
            longitude: 0,
            createdAt: DateTime.now(),
            timestamp: DateTime.now(),
            momentGroupId: 'group-1',
          ),
          Moment(
            id: 'moment-id-2',
            title: 'Title',
            location: 'Location',
            latitude: 0,
            longitude: 0,
            createdAt: DateTime.now(),
            timestamp: DateTime.now(),
            momentGroupId: 'group-1',
          ),
        ],
      );

      // Execute
      await notifier.createMoment(title: 'Test Title', caption: 'Test Caption');

      // Verify
      final captured = verify(
        () => mockRepository.createMomentsBatch(
          captureAny(),
          any(),
          any(),
          any(),
          any(),
          any(),
          isPrivate: any(named: 'isPrivate'),
          momentGroupId: any(named: 'momentGroupId'),
        ),
      ).captured;

      print('Captured calls: ${captured.length}');

      expect(captured.length, 1);
      final capturedImages = captured[0] as List<File>;

      expect(capturedImages.length, 2);
      expect(capturedImages[0].path, image1.path);
      expect(capturedImages[1].path, image2.path);
    },
  );
}
