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
  group('Physical Address Logical Tests', () {
    test('toPostalLabel formats address components correctly', () {
      final addr = PhysicalAddress(
        address: '100 Main St',
        city: 'Seattle',
        state: 'WA',
        postalCode: '98101',
        countryCode: 'US',
      );
      expect(addr.toPostalLabel(), '100 Main St, Seattle, WA 98101, US');
    });

    test('toMapSearchQuery generates valid URL query', () {
      final addr = PhysicalAddress(
        address: '100 Main St',
        city: 'Seattle',
        state: 'WA',
        postalCode: '98101',
        countryCode: 'US',
      );
      expect(
        addr.toMapSearchQuery(),
        'https://www.google.com/maps/search/?api=1&query=100%20Main%20St%2C%20Seattle%2C%20WA%2098101%2C%20US',
      );
    });

    test('Country code validation logic', () {
      // Valid ISO codes
      expect(() => InventoryLocationValidator.validateCountryCode('US'), returnsNormally);
      expect(() => InventoryLocationValidator.validateCountryCode('IT'), returnsNormally);
      expect(() => InventoryLocationValidator.validateCountryCode('GB'), returnsNormally);

      // Invalid ISO codes
      expect(() => InventoryLocationValidator.validateCountryCode('USA'), throwsFormatException);
      expect(() => InventoryLocationValidator.validateCountryCode('us'), throwsFormatException);
      expect(() => InventoryLocationValidator.validateCountryCode('U1'), throwsFormatException);
      expect(() => InventoryLocationValidator.validateCountryCode(''), throwsFormatException);
    });
  });

  group('Physical Address Widget UI Tests', () {
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

    testWidgets('Displays physical address and triggers View Map snackbar', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockInventoryLocationService();
      service.clearAll();

      service.addLocation(InventoryLocation(
        id: 'Seattle-HQ',
        type: 'site',
        timestamp: DateTime(2026, 1, 1),
        physicalAddress: PhysicalAddress(
          address: '100 Main St',
          city: 'Seattle',
          state: 'WA',
          postalCode: '98101',
          countryCode: 'US',
        ),
      ));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToInventoryLocations(tester);

      // Check text is rendered
      expect(find.textContaining('100 Main St, Seattle, WA 98101, US'), findsOneWidget);

      // Click "View Map"
      await tester.ensureVisible(find.text('View Map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Map'));
      await tester.pumpAndSettle();

      // Check that SnackBar with maps link is shown
      expect(
        find.textContaining('https://www.google.com/maps/search/?api=1&query=100%20Main%20St'),
        findsOneWidget,
      );
    });

    testWidgets('Country code validation errors and successful update flow', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockInventoryLocationService();
      service.clearAll();

      service.addLocation(InventoryLocation(
        id: 'Milan-Site',
        type: 'site',
        timestamp: DateTime(2026, 1, 1),
      ));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToInventoryLocations(tester);

      // Open Edit Form
      final nodeRow = find.ancestor(
        of: find.text('Milan-Site'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Row && widget.children.any((c) => c is IconButton),
        ),
      ).first;

      final editBtn = find.descendant(
        of: nodeRow,
        matching: find.byIcon(Icons.edit),
      );
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Fill in Address fields
      final streetField = find.ancestor(
        of: find.text('Street Address'),
        matching: find.byType(TextField),
      );
      final cityField = find.ancestor(
        of: find.text('City'),
        matching: find.byType(TextField),
      );
      final countryField = find.ancestor(
        of: find.text('Country Code (ISO-2)'),
        matching: find.byType(TextField),
      );

      await tester.enterText(streetField, 'Via Dante 10');
      await tester.enterText(cityField, 'Milan');
      await tester.enterText(countryField, 'it'); // Invalid: lowercase
      await tester.pumpAndSettle();

      final updateBtn = find.widgetWithText(ElevatedButton, 'Update Location');
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Verify that validation error message is displayed
      expect(find.textContaining('Country code must be a valid ISO 3166-1 Alpha-2'), findsWidgets);

      // Fix country code to 'IT' (uppercase)
      await tester.enterText(countryField, 'IT');
      await tester.pumpAndSettle();

      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar success
      expect(find.textContaining('Successfully updated'), findsOneWidget);

      // Verify updated address appears in list
      expect(find.textContaining('Via Dante 10, Milan,  , IT'), findsOneWidget);
    });
  });
}