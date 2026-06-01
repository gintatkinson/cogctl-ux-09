import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/models/time_duration.dart';
import 'package:cogctl_ux/services/mock_time_duration_service.dart';

void main() {
  group('YANG Time Duration Validation Logic Tests', () {
    String? getValidationError(YangTimeDurationType type, String value) {
      try {
        YangTimeDurationValidator.validate(value, type);
        return null;
      } catch (e) {
        return e.toString();
      }
    }

    test('Valid and invalid 32-bit signed integer values', () {
      expect(getValidationError(YangTimeDurationType.seconds32, '0'), isNull);
      expect(getValidationError(YangTimeDurationType.seconds32, '2147483647'), isNull);
      expect(getValidationError(YangTimeDurationType.seconds32, '-2147483648'), isNull);

      expect(getValidationError(YangTimeDurationType.seconds32, '2147483648'), isNotNull);
      expect(getValidationError(YangTimeDurationType.seconds32, '-2147483649'), isNotNull);
      expect(getValidationError(YangTimeDurationType.seconds32, 'abc'), isNotNull);
    });

    test('Valid and invalid 64-bit signed integer values', () {
      expect(getValidationError(YangTimeDurationType.microseconds64, '0'), isNull);
      expect(getValidationError(YangTimeDurationType.microseconds64, '9223372036854775807'), isNull);
      expect(getValidationError(YangTimeDurationType.microseconds64, '-9223372036854775808'), isNull);

      expect(getValidationError(YangTimeDurationType.microseconds64, '9223372036854775808'), isNotNull);
      expect(getValidationError(YangTimeDurationType.microseconds64, '-9223372036854775809'), isNotNull);
    });

    test('Valid and invalid 32-bit unsigned values (timeticks & timestamp)', () {
      expect(getValidationError(YangTimeDurationType.timeticks, '0'), isNull);
      expect(getValidationError(YangTimeDurationType.timeticks, '4294967295'), isNull);

      expect(getValidationError(YangTimeDurationType.timeticks, '-1'), isNotNull);
      expect(getValidationError(YangTimeDurationType.timeticks, '4294967296'), isNotNull);
    });

    test('Nanoseconds32 unit-specific duration capability bounds check (2 seconds / 2B ns)', () {
      expect(getValidationError(YangTimeDurationType.nanoseconds32, '2000000000'), isNull); // 2s
      expect(getValidationError(YangTimeDurationType.nanoseconds32, '-2000000000'), isNull); // -2s

      final errorTooLarge = getValidationError(YangTimeDurationType.nanoseconds32, '2000000001');
      expect(errorTooLarge, isNotNull);
      expect(errorTooLarge, contains('unit-specific capability bound'));

      final errorTooSmall = getValidationError(YangTimeDurationType.nanoseconds32, '-2000000001');
      expect(errorTooSmall, isNotNull);
      expect(errorTooSmall, contains('unit-specific capability bound'));
    });

    test('Timestamp reset on timeticks wrap in service registry', () {
      final service = MockTimeDurationService();
      
      // Initial values
      service.updateNodeValue('uptime-ticks', '360000');
      service.updateNodeValue('boot-timestamp', '120000');

      final nodesBefore = service.getNodes();
      final uptimeBefore = nodesBefore.firstWhere((n) => n.id == 'uptime-ticks').value;
      final bootBefore = nodesBefore.firstWhere((n) => n.id == 'boot-timestamp').value;
      
      expect(uptimeBefore, '360000');
      expect(bootBefore, '120000');

      // Update timeticks to 0 (wrap-around event)
      service.updateNodeValue('uptime-ticks', '0');

      final nodesAfter = service.getNodes();
      final uptimeAfter = nodesAfter.firstWhere((n) => n.id == 'uptime-ticks').value;
      final bootAfter = nodesAfter.firstWhere((n) => n.id == 'boot-timestamp').value;

      expect(uptimeAfter, '0');
      expect(bootAfter, '0'); // Reset automatically to 0!
    });
  });

  group('YANG Time Duration Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToTimeDuration(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Time Durations'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate, select node, and update value successfully', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      // Reset service values to ensure test isolation
      final service = MockTimeDurationService();
      service.updateNodeValue('uptime-ticks', '360000');
      service.updateNodeValue('boot-timestamp', '120000');
      service.updateNodeValue('sensor-interval', '500000000');

      await tester.pumpWidget(const CogctlUxApp());

      await navigateToTimeDuration(tester);

      expect(find.text('Time Durations Dashboard'), findsOneWidget);
      expect(find.text('RFC 9911 Time-Duration Specs'), findsOneWidget);

      // Verify list contains sensor interval
      expect(find.textContaining('High-Speed Sensor Interval'), findsWidgets);

      // Select Target Node dropdown (should have telemetry-interval by default or we select sensor-interval)
      // Tap dropdown to expand
      await tester.tap(find.byType(DropdownButtonFormField<YangTimeDurationReference>));
      await tester.pumpAndSettle();

      // Tap the item for sensor-interval
      await tester.tap(find.textContaining('High-Speed Sensor Interval').last);
      await tester.pumpAndSettle();

      // Find the TextField
      final valField = find.ancestor(
        of: find.text('New Value'),
        matching: find.byType(TextField),
      );
      expect(valField, findsOneWidget);

      // Input a valid nanoseconds value
      await tester.enterText(valField, '1200000000');
      await tester.pump();

      // Tap 'Update Value'
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully updated'), findsOneWidget);
      expect(find.textContaining('1200000000 (1.200 sec)'), findsWidgets);
    });

    testWidgets('Validation error shown on exceeding unit capability bound', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      // Reset service values
      final service = MockTimeDurationService();
      service.updateNodeValue('uptime-ticks', '360000');
      service.updateNodeValue('boot-timestamp', '120000');
      service.updateNodeValue('sensor-interval', '500000000');

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToTimeDuration(tester);

      // Select High-Speed Sensor Interval
      await tester.tap(find.byType(DropdownButtonFormField<YangTimeDurationReference>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('High-Speed Sensor Interval').last);
      await tester.pumpAndSettle();

      final valField = find.ancestor(
        of: find.text('New Value'),
        matching: find.byType(TextField),
      );

      // Input value exceeding 2 seconds (2.1 billion ns)
      await tester.enterText(valField, '2100000000');
      await tester.pump();

      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      expect(find.textContaining('exceeds unit-specific capability bound'), findsOneWidget);
    });

    testWidgets('Simulate Wrap button resets both timeticks and associated timestamp', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      // Reset service values
      final service = MockTimeDurationService();
      service.updateNodeValue('uptime-ticks', '360000');
      service.updateNodeValue('boot-timestamp', '120000');
      service.updateNodeValue('sensor-interval', '500000000');

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToTimeDuration(tester);

      // Initial state verify values in list
      expect(find.textContaining('360000'), findsWidgets);
      expect(find.textContaining('120000'), findsWidgets);

      // Select System Uptime Ticks
      await tester.tap(find.byType(DropdownButtonFormField<YangTimeDurationReference>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('System Uptime Ticks').last);
      await tester.pumpAndSettle();

      // Tap 'Simulate Wrap'
      await tester.tap(find.text('Simulate Wrap'));
      await tester.pumpAndSettle();

      // Check both uptime and boot timestamp values are updated to 0
      expect(find.textContaining('Successfully updated System Uptime Ticks to 0'), findsOneWidget);
      expect(find.textContaining('Value: 0 (0.00 sec)'), findsNWidgets(2)); // both reset
    });
  });
}
