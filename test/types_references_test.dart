import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';
import 'package:cogctl_ux/features/software_configuration/data/mock_types_references_service.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    initServiceLocator();
  });
  group('IETF YANG Types and References Validation Logic Tests', () {
    late MockTypesReferencesService service;

    setUp(() {
      service = MockTypesReferencesService();
    });

    test('Seeded reference configurations validation states', () {
      final refs = service.getReferences();
      expect(refs.length, 3);

      // default-ne-ref: ne-ref to ne-01 -> Valid
      final neRef = refs.firstWhere((r) => r.id == 'default-ne-ref');
      expect(service.validateReference(neRef), 'Valid');

      // default-component-ref: component-ref to chassis-01 on ne-01 -> Valid
      final compRef = refs.firstWhere((r) => r.id == 'default-component-ref');
      expect(service.validateReference(compRef), 'Valid');

      // default-port-ref: port-ref to gigabit-port-01 on ne-01 -> Valid
      final portRef = refs.firstWhere((r) => r.id == 'default-port-ref');
      expect(service.validateReference(portRef), 'Valid');
    });

    test('Validation fails when target network element is unresolved (require-instance: false)', () {
      final unresolvedNe = MockInventoryTypeReference(
        id: 'unresolved-ne',
        referenceType: 'ne-ref',
        neRef: 'non-existent-ne',
      );
      // Under require-instance: false, unresolved references are flagged gracefully rather than breaking
      expect(service.validateReference(unresolvedNe), startsWith('Unresolved: Network Element non-existent-ne not found'));
    });

    test('Validation fails when target component is unresolved', () {
      final unresolvedComp = MockInventoryTypeReference(
        id: 'unresolved-comp',
        referenceType: 'component-ref',
        neRef: 'ne-01',
        targetRef: 'non-existent-comp',
      );
      expect(service.validateReference(unresolvedComp), startsWith('Unresolved: Component non-existent-comp not found'));
    });

    test('Validation enforces port class constraint (class derivation must resolve to ianahw:port)', () {
      // 1. Valid port class override
      final validPort = MockInventoryTypeReference(
        id: 'test-port-valid',
        referenceType: 'port-ref',
        neRef: 'ne-01',
        targetRef: 'chassis-01',
        customComponentClass: IetfInventoryIdentities.ianahwPort,
      );
      expect(service.validateReference(validPort), 'Valid');

      // 2. Invalid class override (chassis is not derived from ianahw:port)
      final invalidChassis = MockInventoryTypeReference(
        id: 'test-port-invalid-chassis',
        referenceType: 'port-ref',
        neRef: 'ne-01',
        targetRef: 'chassis-01',
        customComponentClass: IetfInventoryIdentities.ianahwChassis,
      );
      expect(service.validateReference(invalidChassis), startsWith('Invalid: Port class constraint violated'));

      // 3. Invalid class override (non-hardware component class is not derived from ianahw:port)
      final invalidNonHw = MockInventoryTypeReference(
        id: 'test-port-invalid-nonhw',
        referenceType: 'port-ref',
        neRef: 'ne-01',
        targetRef: 'chassis-01',
        customComponentClass: IetfInventoryIdentities.nonHardwareComponentClass,
      );
      expect(service.validateReference(invalidNonHw), startsWith('Invalid: Port class constraint violated'));
    });
  });

  group('IETF YANG Types and References Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToTypesReferences(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('YANG Types & References'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate to Types & References screen, view seeded configuration and counts', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToTypesReferences(tester);

      expect(find.text('YANG Types & References'), findsWidgets);
      expect(find.textContaining('Manage and validate references'), findsOneWidget);

      // Verify counts card displays seeded items
      expect(find.text('Total References'), findsOneWidget);
      expect(find.text('Valid References'), findsOneWidget);
      // Seeded contains 3 valid items: default-ne-ref, default-component-ref, default-port-ref
      expect(find.text('3'), findsWidgets); 
    });

    testWidgets('Can create a new valid reference and delete it', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToTypesReferences(tester);

      // Tap and input Config ID
      final idField = find.byKey(const ValueKey('types-ref-id-field'));
      expect(idField, findsOneWidget);
      await tester.enterText(idField, 'my-custom-ne-ref');
      await tester.pumpAndSettle();

      // Select ne-ref type (already default, but let's select it or verify dropdown exists)
      expect(find.byKey(const ValueKey('types-ref-type-dropdown')), findsOneWidget);

      // Select Referenced Network Element (should populate dropdown with ne-01 etc.)
      await tester.tap(find.byKey(const ValueKey('types-ref-ne-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ne-01').last);
      await tester.pumpAndSettle();

      // Tap Create Reference button
      await tester.tap(find.byKey(const ValueKey('create-reference-button')));
      await tester.pumpAndSettle();

      // Verify snackbar is shown and configuration appears in the list
      expect(find.textContaining('Successfully created reference configuration'), findsOneWidget);
      expect(find.textContaining('my-custom-ne-ref'), findsOneWidget);

      // Delete the created configuration
      final deleteButtons = find.byIcon(Icons.delete_outline);
      // The newly created one should be last
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Verify deletion message and item gone
      expect(find.textContaining('Successfully deleted reference configuration'), findsOneWidget);
      expect(find.textContaining('my-custom-ne-ref'), findsNothing);
    });

    testWidgets('Cannot create port-ref that violates class derivation constraint', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToTypesReferences(tester);

      // Tap and input Config ID
      final idField = find.byKey(const ValueKey('types-ref-id-field'));
      await tester.enterText(idField, 'invalid-port-reference');
      await tester.pumpAndSettle();

      // Change Reference Type to port-ref
      await tester.tap(find.byKey(const ValueKey('types-ref-type-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('port-ref (Port Component)').last);
      await tester.pumpAndSettle();

      // Select Referenced NE ne-01
      await tester.tap(find.byKey(const ValueKey('types-ref-ne-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ne-01').last);
      await tester.pumpAndSettle();

      // Select Target Component chassis-01 (which is a chassis class, not a port class)
      await tester.tap(find.byKey(const ValueKey('types-ref-target-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('chassis-01 (ianahw:chassis)').last);
      await tester.pumpAndSettle();

      // Tap Create Reference button
      await tester.tap(find.byKey(const ValueKey('create-reference-button')));
      await tester.pumpAndSettle();

      // Verify validation error constraint is shown on the form and creation did not succeed
      expect(find.textContaining('Port class constraint violated'), findsOneWidget);
      expect(find.textContaining('Successfully created reference configuration'), findsNothing);
    });
  });
}