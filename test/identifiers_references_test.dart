import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/models/identifiers_references.dart';

void main() {
  group('YANG Identifiers & OID Validation Logic Tests', () {
    String? getValidationError(YangIdentifierType type, String value) {
      try {
        YangIdentifierValidator.validate(value, type);
        return null;
      } catch (e) {
        return e.toString();
      }
    }

    test('Valid Object Identifier', () {
      final error = getValidationError(YangIdentifierType.objectIdentifier, '1.3.6.1.4.1.28281');
      expect(error, isNull);
    });

    test('Invalid OID: Root arc must be 0, 1, or 2', () {
      final error = getValidationError(YangIdentifierType.objectIdentifier, '3.1.2');
      expect(error, isNotNull);
      expect(error, contains('Root arc (first sub-identifier) must be 0, 1, or 2'));
    });

    test('Invalid OID: Second arc limit (root 0 or 1)', () {
      final error = getValidationError(YangIdentifierType.objectIdentifier, '1.40.1');
      expect(error, isNotNull);
      expect(error, contains('Second sub-identifier must be between 0 and 39'));
    });

    test('Valid OID under 128 elements limit', () {
      final subIdentifiers = List.generate(128, (i) => i == 0 ? '1' : (i == 1 ? '3' : '1')).join('.');
      final error = getValidationError(YangIdentifierType.objectIdentifier128, subIdentifiers);
      expect(error, isNull);
    });

    test('Invalid OID-128: Exceeds 128 limit', () {
      final subIdentifiers = List.generate(129, (i) => i == 0 ? '1' : (i == 1 ? '3' : '1')).join('.');
      final error = getValidationError(YangIdentifierType.objectIdentifier128, subIdentifiers);
      expect(error, isNotNull);
      expect(error, contains('cannot exceed 128 sub-identifiers'));
    });

    test('Valid YANG Identifier', () {
      final error = getValidationError(YangIdentifierType.yangIdentifier, 'valid_name.1-abc');
      expect(error, isNull);
    });

    test('Invalid YANG Identifier: Invalid start character', () {
      final error = getValidationError(YangIdentifierType.yangIdentifier, '1_invalid');
      expect(error, isNotNull);
      expect(error, contains('must start with a letter or'));
    });

    test('Invalid YANG Identifier: Starts with xml prefix case-insensitive', () {
      final error = getValidationError(YangIdentifierType.yangIdentifier, 'xml_node');
      expect(error, isNotNull);
      expect(error, contains('cannot start with \'xml\''));

      final errorCaps = getValidationError(YangIdentifierType.yangIdentifier, 'Xml_node');
      expect(errorCaps, isNotNull);
      expect(errorCaps, contains('cannot start with \'xml\''));
    });
  });

  group('YANG Identifiers & OID Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToIdentifiers(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Identifiers & Refs'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate, select node, and update value successfully', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());

      // Navigate to screen
      await navigateToIdentifiers(tester);

      expect(find.text('RFC 9911 Identifiers & Refs'), findsOneWidget);
      expect(find.text('Update Identifier String'), findsOneWidget);

      // Verify lists of nodes is rendered
      expect(find.textContaining('IANA Private Enterprise OID'), findsWidgets);

      // Find the TextField for value update
      final valField = find.ancestor(
        of: find.text('New Identifier Value'),
        matching: find.byType(TextField),
      );
      expect(valField, findsOneWidget);

      // Input a new valid OID value
      await tester.enterText(valField, '1.3.6.1.4.1.9.1.1');
      await tester.pump();

      await tester.tap(find.text('Update Identifier'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully updated'), findsOneWidget);
      expect(find.textContaining('1.3.6.1.4.1.9.1.1'), findsWidgets);
    });

    testWidgets('Validation error shown on invalid OID entry', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToIdentifiers(tester);

      final valField = find.ancestor(
        of: find.text('New Identifier Value'),
        matching: find.byType(TextField),
      );

      // Input invalid OID (starts with 3)
      await tester.enterText(valField, '3.1.2.3');
      await tester.pump();

      await tester.tap(find.text('Update Identifier'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Root arc (first sub-identifier) must be 0, 1, or 2'), findsOneWidget);
    });

    testWidgets('Validation error shown on invalid YANG identifier entry', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToIdentifiers(tester);

      // Select a yang-identifier type node
      await tester.tap(find.byType(DropdownButtonFormField<YangIdentifierReference>));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('YANG Interface Name').last);
      await tester.pumpAndSettle();

      final valField = find.ancestor(
        of: find.text('New Identifier Value'),
        matching: find.byType(TextField),
      );

      // Input invalid start name
      await tester.enterText(valField, '1invalid');
      await tester.pump();

      await tester.tap(find.text('Update Identifier'));
      await tester.pumpAndSettle();

      expect(find.textContaining('must start with a letter or'), findsOneWidget);
    });
  });
}
