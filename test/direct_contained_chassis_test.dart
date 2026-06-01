import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/models/inventory_location.dart';
import 'package:cogctl_ux/services/mock_inventory_location_service.dart';

void main() {
  group('Contained Chassis Validation Logic Tests', () {
    test('Validate uint32 bounds for chassisId', () {
      final valid = ContainedChassis(chassisId: 10, neRef: 'ne-1', componentRef: 'comp-1');
      expect(() => InventoryLocationValidator.validateContainedChassis(valid, []), returnsNormally);

      final maxUint32 = ContainedChassis(chassisId: 4294967295, neRef: 'ne-1', componentRef: 'comp-1');
      expect(() => InventoryLocationValidator.validateContainedChassis(maxUint32, []), returnsNormally);

      final negative = ContainedChassis(chassisId: -1, neRef: 'ne-1', componentRef: 'comp-1');
      expect(() => InventoryLocationValidator.validateContainedChassis(negative, []), throwsFormatException);
    });

    test('Validate chassisId uniqueness within location', () {
      final existing = [
        ContainedChassis(chassisId: 10, neRef: 'ne-1', componentRef: 'comp-1'),
        ContainedChassis(chassisId: 20, neRef: 'ne-1', componentRef: 'comp-2'),
      ];

      final duplicate = ContainedChassis(chassisId: 10, neRef: 'ne-2', componentRef: 'comp-1');
      expect(() => InventoryLocationValidator.validateContainedChassis(duplicate, existing), throwsFormatException);

      final unique = ContainedChassis(chassisId: 30, neRef: 'ne-1', componentRef: 'comp-1');
      expect(() => InventoryLocationValidator.validateContainedChassis(unique, existing), returnsNormally);
    });
  });

  group('Mock Inventory Location Service Tests with Contained Chassis', () {
    late MockInventoryLocationService locationService;

    setUp(() {
      locationService = MockInventoryLocationService();
    });

    test('Service retains and updates contained chassis collection', () {
      final loc = InventoryLocation(
        id: 'Loc-Chassis-Test',
        type: 'room',
        timestamp: DateTime(2026, 1, 1),
        containedChassis: [
          ContainedChassis(chassisId: 1, neRef: 'ne-A', componentRef: 'comp-1'),
        ],
      );

      locationService.addLocation(loc);
      final fetched = locationService.getLocations().firstWhere((l) => l.id == 'Loc-Chassis-Test');
      expect(fetched, isNotNull);
      expect(fetched.containedChassis.length, 1);
      expect(fetched.containedChassis.first.chassisId, 1);

      // Update location with new chassis list
      locationService.updateLocation(
        'Loc-Chassis-Test',
        type: 'room',
        timestamp: DateTime(2026, 1, 1),
        containedChassis: [
          ContainedChassis(chassisId: 1, neRef: 'ne-A', componentRef: 'comp-1'),
          ContainedChassis(chassisId: 2, neRef: 'ne-A', componentRef: 'comp-2'),
        ],
      );

      final fetchedUpdated = locationService.getLocations().firstWhere((l) => l.id == 'Loc-Chassis-Test');
      expect(fetchedUpdated.containedChassis.length, 2);
      expect(fetchedUpdated.containedChassis[1].chassisId, 2);
    });
  });

  group('Contained Chassis Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToInventoryLocations(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inventory Locations'));
      await tester.pumpAndSettle();
    }

    testWidgets('Displays contained chassis and handles add/delete and dangling reference warning', (WidgetTester tester) async {
      // Reset service to clean default state to clear leftovers from previous unit tests
      MockInventoryLocationService().reset();

      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await tester.pumpAndSettle();

      // Navigate to Inventory Locations screen
      await navigateToInventoryLocations(tester);

      // 1. Verify default contained chassis renders in the list
      expect(find.textContaining('Chassis #1'), findsWidgets);

      // 2. Select loc-london-hq for editing
      final loc1Row = find.ancestor(
        of: find.text('loc-london-hq'),
        matching: find.byType(Padding),
      ).first;
      final editBtn = find.descendant(
        of: loc1Row,
        matching: find.byIcon(Icons.edit),
      );
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Find formCard for precise targeting
      final formCard = find.ancestor(
        of: find.text('Add Contained Chassis Instance'),
        matching: find.byType(Card),
      );
      expect(formCard, findsOneWidget);

      // 3. Add a new contained chassis
      // Fill in Chassis ID
      final chassisIdField = find.descendant(
        of: formCard,
        matching: find.ancestor(
          of: find.text('Chassis ID'),
          matching: find.byType(TextFormField),
        ),
      );
      await tester.enterText(chassisIdField, '2');
      await tester.pump();

      // Select Network Element Ref dropdown
      final neDropdown = find.byKey(const ValueKey('neRefDropdown_none'));
      expect(neDropdown, findsOneWidget);
      await tester.tap(neDropdown);
      await tester.pumpAndSettle();

      // Select 'ne-A'
      final neOption = find.text('ne-A').last;
      await tester.tap(neOption);
      await tester.pumpAndSettle();

      // Select Component Ref dropdown
      final compDropdown = find.byKey(const ValueKey('compRefDropdown_none_ne_ne-A'));
      expect(compDropdown, findsOneWidget);
      await tester.tap(compDropdown);
      await tester.pumpAndSettle();

      // Select 'comp-2'
      final compOption = find.text('comp-2').last;
      await tester.tap(compOption);
      await tester.pumpAndSettle();

      // Click "Add to Location" button
      final addToLocBtn = find.widgetWithText(ElevatedButton, 'Add to Location');
      await tester.tap(addToLocBtn);
      await tester.pumpAndSettle();

      // Verify the new chassis is listed in the edit subform list
      expect(find.descendant(
        of: formCard,
        matching: find.textContaining('Chassis #2 (NE: ne-A, Component: comp-2)'),
      ), findsOneWidget);

      // 4. Test validation: Add duplicate ID 2, should show error
      await tester.enterText(chassisIdField, '2');
      await tester.pump();
      await tester.tap(neDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ne-A').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('compRefDropdown_none_ne_ne-A')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('comp-2').last);
      await tester.pumpAndSettle();
      await tester.tap(addToLocBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('already in use'), findsOneWidget);

      // 5. Delete chassis 1 from the list inside formCard
      final chassis1Row = find.descendant(
        of: formCard,
        matching: find.ancestor(
          of: find.text('Chassis #1 (NE: ne-A, Component: comp-1)'),
          matching: find.byType(Row),
        ),
      );
      final deleteBtnFor1 = find.descendant(
        of: chassis1Row,
        matching: find.byIcon(Icons.delete),
      );
      await tester.tap(deleteBtnFor1);
      await tester.pumpAndSettle();

      // Save/Submit the form
      final saveBtn = find.widgetWithText(ElevatedButton, 'Update Location');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify success snackbar and updated tree lists
      expect(find.textContaining('Successfully updated'), findsOneWidget);
      expect(find.textContaining('Chassis #2'), findsWidgets);
      expect(find.textContaining('Chassis #1 (NE:'), findsNothing);

      // 6. Test Relational Integrity (Dangling Pointer) Dynamic Warning
      // Expand NE/Component manager
      final neManagerHeader = find.widgetWithText(ExpansionTile, 'Network Inventory Manager (YANG Data Source)');
      expect(neManagerHeader, findsOneWidget);
      await tester.tap(neManagerHeader);
      await tester.pumpAndSettle();

      // Delete Component 'comp-2' from 'ne-A'
      final compChip = find.descendant(
        of: find.widgetWithText(Card, 'ne-A'),
        matching: find.byType(Chip),
      ).at(1); // 'comp-2' chip
      final deleteCompBtn = find.descendant(
        of: compChip,
        matching: find.byIcon(Icons.cancel),
      );
      await tester.tap(deleteCompBtn);
      await tester.pumpAndSettle();

      // Verify warning indicator/badge for Dangling Pointer appears under loc-london-hq
      expect(find.textContaining('⚠️ Dangling Pointer'), findsOneWidget);
    });
  });
}
