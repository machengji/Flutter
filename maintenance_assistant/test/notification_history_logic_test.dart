import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';

void main() {
  group('HomeProvider.shouldRestoreMissedNotification', () {
    test('returns false for notifications that happened before history was cleared', () {
      final clearedBefore = DateTime(2026, 3, 23, 15, 0).millisecondsSinceEpoch;
      final trigger = DateTime(2026, 3, 23, 9, 0).millisecondsSinceEpoch;

      final shouldRestore = HomeProvider.shouldRestoreMissedNotification(
        triggerTimestamp: trigger,
        clearedBeforeTimestamp: clearedBefore,
      );

      expect(shouldRestore, isFalse);
    });

    test('returns true for notifications that happen after history was cleared', () {
      final clearedBefore = DateTime(2026, 3, 23, 9, 0).millisecondsSinceEpoch;
      final trigger = DateTime(2026, 3, 23, 18, 0).millisecondsSinceEpoch;

      final shouldRestore = HomeProvider.shouldRestoreMissedNotification(
        triggerTimestamp: trigger,
        clearedBeforeTimestamp: clearedBefore,
      );

      expect(shouldRestore, isTrue);
    });
  });
}
