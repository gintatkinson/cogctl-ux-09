import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';
import 'package:cogctl_ux/features/infrastructure/data/mock_inventory_location_service.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    initServiceLocator();
  });
  group('Inventory Location Validation Logic Tests', () {
    test('Detect circular loop correctly', () {
      final list = [
        InventoryLocation(
          id: 'A',
          type: 'site',
          timestamp: DateTime(2026, 1, 1),
        ),
        InventoryLocation(
          id: 'B',
          type: 'building',
          parent: 'A',
          timestamp: DateTime(2026, 1, 1),
        ),
        InventoryLocation(
          id: 'C',
          type: 'room',
          parent: 'B',
          timestamp: DateTime(2026, 1, 1),
        ),
      ];

      // A -> B -> C. Setting parent of A to C is circular.
      expect(
        () => InventoryLocationValidator.detectCircularLoop('A', 'C', list),
        throwsFormatException,
      );

      // A -> B -> C. Setting parent of B to C is circular.
      expect(
        () => InventoryLocationValidator.detectCircularLoop('B', 'C', list),
        throwsFormatException,
      );

      // A -> B -> C. Setting parent of A to A (self loop) is circular.
      expect(
        () => InventoryLocationValidator.detectCircularLoop('A', 'A', list),
        throwsFormatException,
      );

      // A -> B -> C. Setting parent of C to A is fine (non-circular, just moves node in tree).
      expect(
        () => InventoryLocationValidator.detectCircularLoop('C', 'A', list),
        returnsNormally,
      );

      // A -> B -> C. Setting parent of A to null is fine.
      expect(
        () => InventoryLocationValidator.detectCircularLoop('A', null, list),
        returnsNormally,
      );
    });

    test('Temporal validity boundaries verification', () {
      final loc = InventoryLocation(
        id: 'site-a',
        type: 'site',
        timestamp: DateTime(2026, 1, 1, 10, 0, 0),
        validUntil: DateTime(2026, 1, 1, 12, 0, 0),
      );

      // Before start
      expect(loc.isValidAt(DateTime(2026, 1, 1, 9, 59, 59)), isFalse);

      // Exactly start
      expect(loc.isValidAt(DateTime(2026, 1, 1, 10, 0, 0)), isTrue);

      // Midpoint
      expect(loc.isValidAt(DateTime(2026, 1, 1, 11, 0, 0)), isTrue);

      // Exactly end (inclusive boundary)
      expect(loc.isValidAt(DateTime(2026, 1, 1, 12, 0, 0)), isTrue);

      // After end
      expect(loc.isValidAt(DateTime(2026, 1, 1, 12, 0, 1)), isFalse);
    });
  });

  group('Inventory Location Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
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

    testWidgets('Can navigate, display locations list and add a new node', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockInventoryLocationService();
      service.clearAll();

      service.addLocation(InventoryLocation(
        id: 'US-West-Site',
        type: 'site',
        timestamp: DateTime(2026, 1, 1),
      ));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToInventoryLocations(tester);

      expect(find.text('Inventory Locations Dashboard'), findsOneWidget);
      expect(find.text('IETF NI-Location Specs'), findsOneWidget);

      // Verify default node shows up in list
      expect(find.text('US-West-Site'), findsWidgets);

      // Create new node
      final idField = find.ancestor(
        of: find.text('Location ID (Unique)'),
        matching: find.byType(TextField),
      );
      final typeField = find.ancestor(
        of: find.text('Type (e.g. site, room, floor)'),
        matching: find.byType(TextField),
      );
      final timestampField = find.ancestor(
        of: find.text('Record Timestamp'),
        matching: find.byType(TextField),
      );

      await tester.enterText(idField, 'US-West-Building-1');
      await tester.enterText(typeField, 'building');
      await tester.enterText(timestampField, '2026-06-01 12:00:00');
      await tester.pump();

      // Tap dropdown to select US-West-Site as parent
      await tester.tap(find.byKey(const Key('parentLocationDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('US-West-Site (site)').last);
      await tester.pumpAndSettle();

      final createBtn = find.widgetWithText(ElevatedButton, 'Create Location');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully added'), findsOneWidget);
      expect(find.text('US-West-Building-1'), findsWidgets);
    });

    testWidgets('Editing node and setting circular dependency triggers validation warning', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockInventoryLocationService();
      service.clearAll();

      // A -> B
      final locA = InventoryLocation(
        id: 'Node-A',
        type: 'site',
        timestamp: DateTime(2026, 1, 1),
      );
      final locB = InventoryLocation(
        id: 'Node-B',
        type: 'building',
        parent: 'Node-A',
        timestamp: DateTime(2026, 1, 1),
      );

      service.addLocation(locA);
      service.addLocation(locB);

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToInventoryLocations(tester);

      // Find the outer Row for Node-A using widget predicate
      final nodeRow = find.ancestor(
        of: find.text('Node-A'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Row && widget.children.any((c) => c is IconButton),
        ),
      ).first;

      final editBtn = find.descendant(
        of: nodeRow,
        matching: find.byIcon(Icons.edit),
      );
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Try setting Parent of Node-A to Node-B (creates circular loop A -> B -> A)
      await tester.tap(find.byKey(const Key('parentLocationDropdown')));
      await tester.pumpAndSettle();

      // Node-B should not be selectable since we filter potential parents in the Dropdown items
      expect(find.text('Node-B (building)'), findsNothing);
    });
  });
}