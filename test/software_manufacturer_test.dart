import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';
import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';
import 'package:cogctl_ux/features/software_configuration/data/mock_software_manufacturer_service.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    initServiceLocator();
  });
  group('Software & Manufacturer Validation Logic Tests', () {
    late MockSoftwareManufacturerService service;

    setUp(() {
      service = MockSoftwareManufacturerService();
      service.resetToDefaults();
    });

    test('Validates config successfully with valid input', () {
      final config = MockSoftwareManufacturerConfig(
        id: 'cfg-test-01',
        targetType: 'Network Element',
        targetId: 'ne-01',
        uuid: '123e4567-e89b-12d3-a456-426614174000',
        name: 'test-config',
        alias: 'tc-1',
        description: 'Test description',
        mfgName: 'Juniper',
        productName: 'MX-960',
        softwareRevisions: [
          MockSoftwareRevision(
            name: 'Junos-OS',
            revision: '21.4R1',
            patches: [
              MockSoftwarePatch(revision: 'p1'),
            ],
          ),
        ],
      );

      final result = service.validateConfig(config);
      expect(result, 'Valid');
    });

    test('Returns invalid if manufacturer name is empty', () {
      final config = MockSoftwareManufacturerConfig(
        id: 'cfg-test-01',
        targetType: 'Network Element',
        targetId: 'ne-01',
        uuid: '',
        name: '',
        alias: '',
        description: '',
        mfgName: '  ',
        productName: 'MX-960',
        softwareRevisions: [],
      );

      final result = service.validateConfig(config);
      expect(result, contains('Manufacturer name cannot be empty'));
    });

    test('Returns invalid if UUID format is invalid', () {
      final config = MockSoftwareManufacturerConfig(
        id: 'cfg-test-01',
        targetType: 'Network Element',
        targetId: 'ne-01',
        uuid: 'invalid-uuid-format',
        name: '',
        alias: '',
        description: '',
        mfgName: 'Juniper',
        productName: 'MX-960',
        softwareRevisions: [],
      );

      final result = service.validateConfig(config);
      expect(result, contains('UUID format is invalid'));
    });

    test('Returns invalid on duplicate software module names', () {
      final config = MockSoftwareManufacturerConfig(
        id: 'cfg-test-01',
        targetType: 'Network Element',
        targetId: 'ne-01',
        uuid: '',
        name: '',
        alias: '',
        description: '',
        mfgName: 'Juniper',
        productName: 'MX-960',
        softwareRevisions: [
          MockSoftwareRevision(name: 'ModA', revision: '1.0', patches: []),
          MockSoftwareRevision(name: 'ModA', revision: '2.0', patches: []),
        ],
      );

      final result = service.validateConfig(config);
      expect(result, contains('Duplicate software module name "ModA"'));
    });

    test('Returns unresolved if target network element does not exist', () {
      final config = MockSoftwareManufacturerConfig(
        id: 'cfg-test-01',
        targetType: 'Network Element',
        targetId: 'non-existent-ne',
        uuid: '',
        name: '',
        alias: '',
        description: '',
        mfgName: 'Juniper',
        productName: 'MX-960',
        softwareRevisions: [],
      );

      final result = service.validateConfig(config);
      expect(result, contains('not found'));
    });
  });

  group('Software & Manufacturer Dashboard UI Widget Tests', () {
    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
    }

    void resetViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    Future<void> navigateToSoftwareMfg(WidgetTester tester) async {
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Software & Mfg'));
      await tester.pumpAndSettle();
    }

    testWidgets('Can navigate to Software & Mfg and display default info', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToSoftwareMfg(tester);

      expect(find.text('Software & Manufacturer Specs'), findsWidgets);
      expect(find.text('Configured Software & Mfg Attributes'), findsOneWidget);

      // Verify that seed config (cfg-ne-01) is displayed in list pane
      expect(find.textContaining('cfg-ne-01'), findsWidgets);
      expect(find.textContaining('NCS-5501'), findsWidgets);
    });

    testWidgets('Form validation error displayed on empty manufacturer', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToSoftwareMfg(tester);

      // Clear Manufacturer field (since cfg-ne-01 is loaded by default)
      final mfgField = find.ancestor(
        of: find.text('Manufacturer Name (mfg-name)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(mfgField, '');

      // Tap Save Attributes
      await tester.tap(find.text('Save Attributes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Manufacturer name is required'), findsOneWidget);
    });

    testWidgets('Adding software revision update form works', (WidgetTester tester) async {
      setupMobileViewport(tester);
      addTearDown(() => resetViewport(tester));

      await tester.pumpWidget(const CogctlUxApp());
      await navigateToSoftwareMfg(tester);

      // Add a software module revision
      final nameField = find.ancestor(
        of: find.text('Module Name (name - key)'),
        matching: find.byType(TextField),
      );
      final revField = find.ancestor(
        of: find.text('Version Revision (revision)'),
        matching: find.byType(TextField),
      );

      await tester.enterText(nameField, 'TestMod');
      await tester.enterText(revField, '1.2.3');
      await tester.pump();

      await tester.tap(find.text('Add Software Revision'));
      await tester.pumpAndSettle();

      // TestMod should be listed in the revisions list
      expect(find.textContaining('TestMod'), findsWidgets);
      expect(find.textContaining('1.2.3'), findsWidgets);
    });
  });
}