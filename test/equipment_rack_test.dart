import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/models/equipment_rack.dart';
import 'package:cogctl_ux/services/mock_equipment_rack_service.dart';

void main() {
  group('Equipment Rack Validation Logic Tests', () {
    test('Valid equipment rack details should validate successfully', () {
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-Valid-1',
          rackClass: 'rack-standard',
          height: 1866,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        returnsNormally,
      );

      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-Valid-2',
          rackClass: 'rack-secure-high',
          height: 2133,
          width: 800,
          depth: 1200,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2026, 6, 1, 12, 1),
        ),
        returnsNormally,
      );
    });

    test('Empty ID should throw FormatException', () {
      expect(
        () => EquipmentRackValidator.validate(
          id: '  ',
          rackClass: 'rack-standard',
          height: 1866,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack ID cannot be empty'))),
      );
    });

    test('Invalid rack class should throw FormatException', () {
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'invalid-class',
          height: 1866,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('is not a valid descendant of rack-class-type'))),
      );
    });

    test('Invalid dimensions (height, width, depth) should throw FormatException', () {
      // Height out of bounds (< 1)
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'rack-standard',
          height: 0,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack height must be a positive integer between 1 and 65535 mm'))),
      );

      // Height out of bounds (> 65535)
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'rack-standard',
          height: 65536,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack height must be a positive integer between 1 and 65535 mm'))),
      );

      // Width out of bounds (< 1)
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'rack-standard',
          height: 1866,
          width: -10,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack width must be a positive integer between 1 and 65535 mm'))),
      );

      // Depth out of bounds (> 65535)
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'rack-standard',
          height: 1866,
          width: 600,
          depth: 70000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2027, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack depth must be a positive integer between 1 and 65535 mm'))),
      );
    });

    test('Temporal constraints validation', () {
      // validUntil before timestamp
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'rack-standard',
          height: 1866,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2026, 5, 31, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack valid-until timestamp must be after recording timestamp'))),
      );

      // validUntil equals timestamp
      expect(
        () => EquipmentRackValidator.validate(
          id: 'Rack-1',
          rackClass: 'rack-standard',
          height: 1866,
          width: 600,
          depth: 1000,
          timestamp: DateTime(2026, 6, 1, 12, 0),
          validUntil: DateTime(2026, 6, 1, 12, 0),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Rack valid-until timestamp must be after recording timestamp'))),
      );
    });
  });

  group('Equipment Racks Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToEquipmentRacks(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Equipment Racks'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate to Equipment Racks dashboard and display racks', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockEquipmentRackService();
      service.reset();

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToEquipmentRacks(tester);

      expect(find.text('Equipment Racks & Bounds'), findsOneWidget);
      expect(find.text('Equipment Racks Specs'), findsOneWidget);

      // Verify defaults are present
      expect(find.text('Rack-Standard-42U'), findsWidgets);
      expect(find.text('Rack-Secure-High-48U'), findsWidgets);

      // Verify metrics
      expect(find.text('TOTAL RACKS'), findsOneWidget);
      expect(find.text('STANDARD GENERAL'), findsOneWidget);
    });

    testWidgets('Can add a new equipment rack via form', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockEquipmentRackService();
      service.reset();

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToEquipmentRacks(tester);

      // Enter Rack ID
      final idField = find.ancestor(
        of: find.text('Rack ID'),
        matching: find.byType(TextField),
      ).first;
      await tester.enterText(idField, 'Rack-Test-32U');

      // Enter Height
      final heightField = find.ancestor(
        of: find.text('Height (mm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(heightField, '1400');

      // Enter Width
      final widthField = find.ancestor(
        of: find.text('Width (mm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(widthField, '600');

      // Enter Depth
      final depthField = find.ancestor(
        of: find.text('Depth (mm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(depthField, '1000');

      // Enter Timestamp
      final timestampField = find.ancestor(
        of: find.text('Recording Timestamp (ISO 8601)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(timestampField, '2026-06-01T12:00:00Z');

      // Enter Expiration
      final validUntilField = find.ancestor(
        of: find.text('Expiration Timestamp (ISO 8601)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(validUntilField, '2027-06-01T12:00:00Z');

      await tester.pump();

      // Tap PROVISION RACK
      final provisionBtn = find.widgetWithText(ElevatedButton, 'PROVISION RACK');
      await tester.tap(provisionBtn);
      await tester.pumpAndSettle();

      // Verify successful snackbar message
      expect(find.textContaining('Successfully added rack Rack-Test-32U'), findsOneWidget);

      // Verify new rack is in the list
      expect(find.text('Rack-Test-32U'), findsWidgets);
    });

    testWidgets('Entering invalid identityref triggers form validation failure', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockEquipmentRackService();
      service.reset();

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToEquipmentRacks(tester);

      // Enter Rack ID
      final idField = find.ancestor(
        of: find.text('Rack ID'),
        matching: find.byType(TextField),
      ).first;
      await tester.enterText(idField, 'Rack-Invalid-Class');

      // Enter Height
      final heightField = find.ancestor(
        of: find.text('Height (mm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(heightField, '1400');

      // Enter Width
      final widthField = find.ancestor(
        of: find.text('Width (mm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(widthField, '600');

      // Enter Depth
      final depthField = find.ancestor(
        of: find.text('Depth (mm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(depthField, '1000');

      // Select invalid class
      await tester.tap(find.text('rack-standard (Standard, Unsecured)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('non-descendant (INVALID CLASS HIERARCHY)').last);
      await tester.pumpAndSettle();

      // Enter Timestamps
      final timestampField = find.ancestor(
        of: find.text('Recording Timestamp (ISO 8601)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(timestampField, '2026-06-01T12:00:00Z');

      final validUntilField = find.ancestor(
        of: find.text('Expiration Timestamp (ISO 8601)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(validUntilField, '2027-06-01T12:00:00Z');

      await tester.pump();

      // Tap PROVISION RACK
      final provisionBtn = find.widgetWithText(ElevatedButton, 'PROVISION RACK');
      await tester.tap(provisionBtn);
      await tester.pumpAndSettle();

      // Verify validation error is displayed
      expect(find.textContaining('is not a valid descendant of rack-class-type'), findsOneWidget);
    });
  });
}
