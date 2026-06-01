import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/models/address_tag.dart';
import 'package:cogctl_ux/services/mock_address_tag_service.dart';

void main() {
  group('YANG Address and Tag Validation Logic Tests', () {
    String? getValidationError(YangAddressTagType type, String value) {
      try {
        YangAddressTagValidator.validateAndNormalize(value, type);
        return null;
      } catch (e) {
        return e.toString();
      }
    }

    test('Valid and invalid MAC address values', () {
      expect(getValidationError(YangAddressTagType.macAddress, '00:1a:2b:3c:4d:5e'), isNull);
      expect(getValidationError(YangAddressTagType.macAddress, '00:1A:2B:3C:4D:5E'), isNull); // case insensitive validation
      
      expect(getValidationError(YangAddressTagType.macAddress, '00:1a:2b:3c:4d'), isNotNull); // too short
      expect(getValidationError(YangAddressTagType.macAddress, '00:1a:2b:3c:4d:5e:6f'), isNotNull); // too long
      expect(getValidationError(YangAddressTagType.macAddress, '00-1a-2b-3c-4d-5e'), isNotNull); // invalid separator
    });

    test('MAC Address case normalization to lowercase', () {
      final normalized = YangAddressTagValidator.validateAndNormalize('00:1A:2B:3C:4D:5E', YangAddressTagType.macAddress);
      expect(normalized, '00:1a:2b:3c:4d:5e');
    });

    test('Valid and invalid Dotted-Quad IP values', () {
      expect(getValidationError(YangAddressTagType.dottedQuad, '192.168.1.1'), isNull);
      expect(getValidationError(YangAddressTagType.dottedQuad, '0.0.0.0'), isNull);
      expect(getValidationError(YangAddressTagType.dottedQuad, '255.255.255.255'), isNull);

      expect(getValidationError(YangAddressTagType.dottedQuad, '256.0.0.1'), isNotNull); // octet > 255
      expect(getValidationError(YangAddressTagType.dottedQuad, '192.168.1'), isNotNull); // not enough octets
      expect(getValidationError(YangAddressTagType.dottedQuad, '192.168.1.1.1'), isNotNull); // too many octets
    });

    test('Valid and invalid UUID values', () {
      expect(getValidationError(YangAddressTagType.uuid, 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6'), isNull);
      expect(getValidationError(YangAddressTagType.uuid, 'F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6'), isNull);

      expect(getValidationError(YangAddressTagType.uuid, 'f81d4fae7dec11d0a76500a0c91e6bf6'), isNotNull); // missing hyphens
    });

    test('UUID case normalization to lowercase', () {
      final normalized = YangAddressTagValidator.validateAndNormalize('F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6', YangAddressTagType.uuid);
      expect(normalized, 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
    });

    test('Valid and invalid BCP 47 Language Tags', () {
      expect(getValidationError(YangAddressTagType.languageTag, 'en'), isNull);
      expect(getValidationError(YangAddressTagType.languageTag, 'en-US'), isNull);
      expect(getValidationError(YangAddressTagType.languageTag, 'zh-Hant-TW'), isNull);

      expect(getValidationError(YangAddressTagType.languageTag, 'e'), isNotNull); // too short primary tag
    });

    test('Language Tag case normalization to lowercase', () {
      final normalized = YangAddressTagValidator.validateAndNormalize('en-US', YangAddressTagType.languageTag);
      expect(normalized, 'en-us');
    });

    test('Valid and invalid XPath 1.0 expressions', () {
      expect(getValidationError(YangAddressTagType.xpath10, "/ietf-network:networks/network[network-id='primary']"), isNull);
      
      expect(getValidationError(YangAddressTagType.xpath10, "/ietf-network:networks/network[network-id='primary'"), isNotNull); // unbalanced bracket
      expect(getValidationError(YangAddressTagType.xpath10, "/ietf-network:networks/network(network-id='primary'"), isNotNull); // unbalanced paren
    });
  });

  group('YANG Address and Tag Widget UI Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToAddressTag(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Addresses & Tags'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate, select node, and update value successfully with normalization', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      // Reset service values
      final service = MockAddressTagService();
      service.clearAll();
      // Repopulate default service nodes
      service.addNode(YangAddressTagReference(
        id: 'active-controller-uuid',
        name: 'Active Controller UUID',
        type: YangAddressTagType.uuid,
        description: 'Test UUID',
        value: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      ));
      service.addNode(YangAddressTagReference(
        id: 'switch-mac-address',
        name: 'SDN Switch MAC Address',
        type: YangAddressTagType.macAddress,
        description: 'Test MAC',
        value: '00:1a:2b:3c:4d:5e',
      ));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToAddressTag(tester);

      expect(find.text('Addresses & Tags Dashboard'), findsOneWidget);
      expect(find.text('RFC 9911 Address Specs'), findsOneWidget);

      // Verify list contains Switch MAC Address
      expect(find.textContaining('SDN Switch MAC Address'), findsWidgets);

      // Select Target Node dropdown (should have active-controller-uuid by default)
      // Tap dropdown to expand
      await tester.tap(find.byType(DropdownButtonFormField<YangAddressTagReference>));
      await tester.pumpAndSettle();

      // Tap the item for Switch MAC Address
      await tester.tap(find.textContaining('SDN Switch MAC Address').last);
      await tester.pumpAndSettle();

      // Find the TextField
      final valField = find.ancestor(
        of: find.text('New Value'),
        matching: find.byType(TextField),
      );
      expect(valField, findsOneWidget);

      // Input a MAC address containing uppercase characters
      await tester.enterText(valField, 'AA:BB:CC:DD:EE:FF');
      await tester.pump();

      // Tap 'Update Value'
      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully updated'), findsOneWidget);
      // Normalized lowercase MAC should be shown in list
      expect(find.textContaining('aa:bb:cc:dd:ee:ff'), findsWidgets);
    });

    testWidgets('Validation error shown on invalid dotted-quad', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      final service = MockAddressTagService();
      service.clearAll();
      service.addNode(YangAddressTagReference(
        id: 'mgmt-dotted-quad',
        name: 'Management Interface Dotted-Quad',
        type: YangAddressTagType.dottedQuad,
        description: 'Test IP',
        value: '192.168.1.1',
      ));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToAddressTag(tester);

      // Select Dotted-Quad
      await tester.tap(find.byType(DropdownButtonFormField<YangAddressTagReference>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Management Interface Dotted-Quad').last);
      await tester.pumpAndSettle();

      final valField = find.ancestor(
        of: find.text('New Value'),
        matching: find.byType(TextField),
      );

      // Input value with octet > 255
      await tester.enterText(valField, '192.168.1.300');
      await tester.pump();

      await tester.tap(find.text('Update Value'));
      await tester.pumpAndSettle();

      expect(find.textContaining('range [0, 255]'), findsOneWidget);
    });
  });
}
