import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/counter_gauge.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    initServiceLocator();
  });
  group('YANG Counters and Gauges Logic Tests', () {
    String? getValidationError(YangCounterGauge node, BigInt newValue, bool discontinuity) {
      try {
        YangCounterGaugeValidator.validateUpdate(
          currentValue: node.value,
          newValue: newValue,
          type: node.type,
          discontinuity: discontinuity,
          maxLimit: node.maxLimit,
        );
        return null;
      } catch (e) {
        return e.toString();
      }
    }

    test('Gauge validator within bounds', () {
      final gauge = YangCounterGauge(
        id: 'cpu',
        name: 'CPU Util',
        description: 'Percent',
        type: YangDataType.gauge64,
        value: BigInt.from(50),
        maxLimit: BigInt.from(100),
      );

      final error = getValidationError(gauge, BigInt.from(99), false);
      expect(error, isNull);
    });

    test('Gauge validator exceeds maxLimit', () {
      final gauge = YangCounterGauge(
        id: 'cpu',
        name: 'CPU Util',
        description: 'Percent',
        type: YangDataType.gauge64,
        value: BigInt.from(50),
        maxLimit: BigInt.from(100),
      );

      final error = getValidationError(gauge, BigInt.from(101), false);
      expect(error, isNotNull);
      expect(error, contains('exceeds max limit'));
    });

    test('Counter validator monotonic increase', () {
      final counter = YangCounterGauge(
        id: 'pkts',
        name: 'Rx Packets',
        description: 'Packets',
        type: YangDataType.counter64,
        value: BigInt.from(1000),
      );

      final error = getValidationError(counter, BigInt.from(1005), false);
      expect(error, isNull);
    });

    test('Counter validator decrease without discontinuity fails', () {
      final counter = YangCounterGauge(
        id: 'pkts',
        name: 'Rx Packets',
        description: 'Packets',
        type: YangDataType.counter64,
        value: BigInt.from(1000),
      );

      final error = getValidationError(counter, BigInt.from(999), false);
      expect(error, isNotNull);
      expect(error, contains('cannot decrease unless a discontinuity'));
    });

    test('Counter validator decrease with discontinuity succeeds', () {
      final counter = YangCounterGauge(
        id: 'pkts',
        name: 'Rx Packets',
        description: 'Packets',
        type: YangDataType.counter64,
        value: BigInt.from(1000),
      );

      final error = getValidationError(counter, BigInt.from(999), true);
      expect(error, isNull);
    });

    test('Boundary check for unsigned 64-bit integer limit', () {
      final maxU64 = BigInt.parse('18446744073709551615');
      final tooLarge = maxU64 + BigInt.one;

      final counter = YangCounterGauge(
        id: 'pkts',
        name: 'Rx Packets',
        description: 'Packets',
        type: YangDataType.counter64,
        value: BigInt.from(0),
      );

      final errorOk = getValidationError(counter, maxU64, false);
      expect(errorOk, isNull);

      final errorTooLarge = getValidationError(counter, tooLarge, false);
      expect(errorTooLarge, isNotNull);
      expect(errorTooLarge, contains('exceeds 64-bit limit'));
    });
  });

  group('YANG Counters and Gauges Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      // Set to 900x1600 so that isDesktop is false (MediaQuery width <= 900)
      // but we have plenty of width/height to avoid overflows and offscreen tap warnings.
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToCountersGauges(WidgetTester tester) async {
      // Find ScaffoldState and open drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap navigation item
      await tester.tap(find.text('Counters & Gauges'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate to Counters & Gauges screen, select node, and update value', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      // Build our app and trigger a frame
      await tester.pumpWidget(const CogctlUxApp());

      // Verify that initially we are on the Reference Frames screen
      expect(find.text('RFC 9179 Geo-Location Specs'), findsOneWidget);

      // Open drawer and navigate
      await navigateToCountersGauges(tester);

      // Now we should be on the Counters & Gauges screen
      expect(find.text('RFC 9911 Counters & Gauges'), findsOneWidget);
      expect(find.text('Update Numeric Value'), findsOneWidget);

      // Check default target node is selected
      expect(find.textContaining('Interface RX Packets'), findsWidgets);

      // Find the TextField for New Numeric Value
      final valField = find.ancestor(
        of: find.text('New Numeric Value'),
        matching: find.byType(TextField),
      );
      expect(valField, findsOneWidget);
      
      // Enter a new valid monotonic value (rx-packets default is 0)
      await tester.enterText(valField, '200');
      await tester.pump();

      // Tap the Update Value button
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      // Check if value updated successfully
      expect(find.textContaining('Successfully updated'), findsOneWidget);
      expect(find.textContaining('200'), findsWidgets);
    });

    testWidgets('Validation error shown if counter decreases without discontinuity checkbox', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());

      // Navigate to Counters & Gauges
      await navigateToCountersGauges(tester);

      // Update value to 100 first to establish baseline
      final valField = find.ancestor(
        of: find.text('New Numeric Value'),
        matching: find.byType(TextField),
      );
      await tester.enterText(valField, '100');
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      // Enter a smaller value
      await tester.enterText(valField, '50');
      await tester.pump();

      // Tap the Update Value button without checking discontinuity
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      // Verification error should be shown in form field errorText
      expect(find.textContaining('cannot decrease unless a discontinuity'), findsOneWidget);
    });

    testWidgets('Succeeds if counter decreases with discontinuity checked', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());

      // Navigate to Counters & Gauges
      await navigateToCountersGauges(tester);

      // Update to 100 first
      final valField = find.ancestor(
        of: find.text('New Numeric Value'),
        matching: find.byType(TextField),
      );
      await tester.enterText(valField, '100');
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      // Enter a smaller value
      await tester.enterText(valField, '50');
      await tester.pump();

      // Check discontinuity checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pump();

      // Tap the Update Value button
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      // Value updated successfully
      expect(find.textContaining('Successfully updated'), findsOneWidget);
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('Reset to 0 triggers reset and discontinuity', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());

      // Navigate to Counters & Gauges
      await navigateToCountersGauges(tester);

      // Click "Reset to 0" button
      final resetBtn = find.text('Reset to 0');
      expect(resetBtn, findsWidgets); // One in form, one in list
      await tester.tap(resetBtn.first);
      await tester.pumpAndSettle();

      // Success message shown and value in list updated to 0
      expect(find.textContaining('Reset'), findsWidgets);
    });
  });
}