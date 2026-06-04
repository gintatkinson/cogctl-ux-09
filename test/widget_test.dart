import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/main.dart';

void main() {
  setUpAll(() {
    initServiceLocator();
  });
  testWidgets('Dashboard launches and displays title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CogctlUxApp());

    // Verify that our dashboard shows the title
    expect(find.text('RFC 9179 Geo-Location Specs'), findsOneWidget);
  });

  testWidgets('Validation error for invalid astronomical body is displayed on submit', (WidgetTester tester) async {
    await tester.pumpWidget(const CogctlUxApp());

    // Find the TextField for Astronomical Body and enter invalid text
    final bodyField = find.ancestor(
      of: find.text('Astronomical Body (Default: earth)'),
      matching: find.byType(TextField),
    );
    expect(bodyField, findsOneWidget);
    await tester.enterText(bodyField, 'earth😀');
    await tester.pump();

    // Tap the submit button
    await tester.ensureVisible(find.text('SUBMIT REGISTER'));
    await tester.tap(find.text('SUBMIT REGISTER'));
    await tester.pumpAndSettle();

    // Verify error is displayed
    expect(find.textContaining('Only standard ASCII without control chars allowed'), findsAtLeastNWidgets(1));
  });

  testWidgets('Validation error for invalid alternate system is displayed on submit', (WidgetTester tester) async {
    await tester.pumpWidget(const CogctlUxApp());

    // Find the TextField for Alternate System and enter invalid text
    final altField = find.ancestor(
      of: find.text('Alternate System (Optional)'),
      matching: find.byType(TextField),
    );
    expect(altField, findsOneWidget);
    await tester.enterText(altField, 'ECEF😀');
    await tester.pump();

    // Tap the submit button
    await tester.ensureVisible(find.text('SUBMIT REGISTER'));
    await tester.tap(find.text('SUBMIT REGISTER'));
    await tester.pumpAndSettle();

    // Verify error is displayed
    expect(find.textContaining('Only standard ASCII without control chars allowed'), findsAtLeastNWidgets(1));
  });

  testWidgets('Entering velocity calculates speed and heading dynamically', (WidgetTester tester) async {
    await tester.pumpWidget(const CogctlUxApp());

    // Enter northward velocity
    final vNorthField = find.ancestor(
      of: find.text('Northward Velocity (v-north, m/s)'),
      matching: find.byType(TextField),
    );
    expect(vNorthField, findsOneWidget);
    await tester.enterText(vNorthField, '3.0');
    await tester.pumpAndSettle();

    // Enter eastward velocity
    final vEastField = find.ancestor(
      of: find.text('Eastward Velocity (v-east, m/s)'),
      matching: find.byType(TextField),
    );
    expect(vEastField, findsOneWidget);
    await tester.enterText(vEastField, '4.0');
    await tester.pumpAndSettle();

    // The horizontal speed should be sqrt(3^2 + 4^2) = 5.0, heading should be atan2(4, 3) * 180 / pi = 53.13
    expect(find.textContaining('Live Computed Horizontal Speed: 5.00 m/s'), findsOneWidget);
    expect(find.textContaining('Heading: 53.13°'), findsOneWidget);
  });
}
