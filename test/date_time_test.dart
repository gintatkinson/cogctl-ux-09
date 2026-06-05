import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/date_time.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    initServiceLocator();
  });
  group('YANG Date & Time Validation Logic Tests', () {
    String? getValidationError(YangDateTimeType type, String value) {
      try {
        YangDateTimeValidator.validate(value, type);
        return null;
      } catch (e) {
        return e.toString();
      }
    }

    test('Valid date-and-time formats', () {
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00Z'), isNull);
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00.123Z'), isNull);
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00+02:00'), isNull);
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00-11:30'), isNull);
    });

    test('Invalid date-and-time formats / regex patterns', () {
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026/06/01 12:00:00Z'), isNotNull);
      expect(getValidationError(YangDateTimeType.dateAndTime, '26-06-01T12:00:00Z'), isNotNull); // 2-digit year
    });

    test('Timezone offset bounds checking (-14:00 to +14:00)', () {
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00+14:00'), isNull);
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00-14:00'), isNull);
      
      final errorHigh = getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00+14:01');
      expect(errorHigh, isNotNull);
      expect(errorHigh, contains('format'));

      final errorLow = getValidationError(YangDateTimeType.dateAndTime, '2026-06-01T12:00:00-15:00');
      expect(errorLow, isNotNull);
      expect(errorLow, contains('format'));
    });

    test('Gregorian calendar days in month bounds', () {
      // April has 30 days
      expect(getValidationError(YangDateTimeType.date, '2026-04-30Z'), isNull);
      final errorApril = getValidationError(YangDateTimeType.date, '2026-04-31Z');
      expect(errorApril, isNotNull);
      expect(errorApril, contains('invalid for month'));

      // December has 31 days
      expect(getValidationError(YangDateTimeType.date, '2026-12-31Z'), isNull);
      final errorDec = getValidationError(YangDateTimeType.date, '2026-12-32Z');
      expect(errorDec, isNotNull);
    });

    test('Leap year rules (February 29)', () {
      // 2024 is a leap year
      expect(getValidationError(YangDateTimeType.date, '2024-02-29Z'), isNull);
      
      // 2026 is not a leap year
      final errorNonLeap = getValidationError(YangDateTimeType.date, '2026-02-29Z');
      expect(errorNonLeap, isNotNull);
      expect(errorNonLeap, contains('leap year'));

      // 2000 is a leap year (divisible by 400)
      expect(getValidationError(YangDateTimeType.date, '2000-02-29Z'), isNull);

      // 1900 is not a leap year (divisible by 100 but not 400)
      final error1900 = getValidationError(YangDateTimeType.date, '1900-02-29Z');
      expect(error1900, isNotNull);
      expect(error1900, contains('leap year'));
    });

    test('Leap seconds validation (23:59:60)', () {
      // Permitted on June 30
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-06-30T23:59:60Z'), isNull);
      // Permitted on December 31
      expect(getValidationError(YangDateTimeType.dateAndTime, '2026-12-31T23:59:60-05:00'), isNull);

      // Rejected on other dates
      final errorJune29 = getValidationError(YangDateTimeType.dateAndTime, '2026-06-29T23:59:60Z');
      expect(errorJune29, isNotNull);
      expect(errorJune29, contains('Leap seconds are only scheduled on June 30 or December 31'));

      // Rejected on other times of June 30
      final errorJune30Time = getValidationError(YangDateTimeType.dateAndTime, '2026-06-30T12:00:60Z');
      expect(errorJune30Time, isNotNull);
    });

    test('date-no-zone validation', () {
      expect(getValidationError(YangDateTimeType.dateNoZone, '2026-06-01'), isNull);
      expect(getValidationError(YangDateTimeType.dateNoZone, '2026-06-01Z'), isNotNull); // should fail if timezone is present
    });

    test('time validation', () {
      expect(getValidationError(YangDateTimeType.time, '12:00:00Z'), isNull);
      expect(getValidationError(YangDateTimeType.time, '12:00:00+05:00'), isNull);
    });

    test('time-no-zone validation', () {
      expect(getValidationError(YangDateTimeType.timeNoZone, '12:00:00'), isNull);
      expect(getValidationError(YangDateTimeType.timeNoZone, '12:00:00Z'), isNotNull); // should fail if timezone is present
    });
  });

  group('YANG Date & Time Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToDateTime(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Date & Time Types'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate, select node, and update value successfully', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());

      // Navigate to screen
      await navigateToDateTime(tester);

      expect(find.text('RFC 9911 Date & Time Types'), findsOneWidget);
      expect(find.text('Update Date / Time String'), findsOneWidget);

      // Verify list of nodes is rendered
      expect(find.textContaining('YANG Date & Time Registry'), findsOneWidget);
      expect(find.textContaining('System Boot Time'), findsWidgets);

      // Find the TextField for value update
      final valField = find.ancestor(
        of: find.text('New Date/Time Value'),
        matching: find.byType(TextField),
      );
      expect(valField, findsOneWidget);

      // Input a new valid date-and-time value
      await tester.enterText(valField, '2026-06-01T15:30:45Z');
      await tester.pump();

      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully updated'), findsOneWidget);
      expect(find.textContaining('2026-06-01T15:30:45Z'), findsWidgets);
    });

    testWidgets('Validation error shown on invalid date format entry', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToDateTime(tester);

      final valField = find.ancestor(
        of: find.text('New Date/Time Value'),
        matching: find.byType(TextField),
      );

      // Input invalid date (e.g., Feb 30)
      await tester.enterText(valField, '2026-02-30T12:00:00Z');
      await tester.pump();

      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      expect(find.textContaining('invalid for month'), findsOneWidget);
    });

    testWidgets('Set to Current button populates text field', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToDateTime(tester);

      final valField = find.ancestor(
        of: find.text('New Date/Time Value'),
        matching: find.byType(TextField),
      );

      // Clear text
      await tester.enterText(valField, '');
      await tester.pump();

      // Tap 'Set to Current'
      await tester.tap(find.text('Set to Current'));
      await tester.pump();

      // Check that field is now populated
      final text = tester.widget<TextField>(valField).controller?.text ?? '';
      expect(text, isNotEmpty);
      
      // Since it is default dateAndTime type, check if it contains T
      expect(text, contains('T'));
    });
  });
}