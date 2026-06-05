import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/models/network_element.dart';
import 'package:cogctl_ux/services/mock_network_inventory_service.dart';

void main() {
  group('MockNetworkElement Model Tests', () {
    test('Constructor assigns fields correctly', () {
      final ne = MockNetworkElement(
        neId: 'ne-1',
        componentIds: ['comp-a', 'comp-b'],
      );
      expect(ne.neId, 'ne-1');
      expect(ne.componentIds, ['comp-a', 'comp-b']);
    });

    test('copyWith overrides neId only', () {
      final original = MockNetworkElement(
        neId: 'ne-1',
        componentIds: ['comp-a'],
      );
      final copy = original.copyWith(neId: 'ne-2');
      expect(copy.neId, 'ne-2');
      expect(copy.componentIds, ['comp-a']);
    });

    test('copyWith overrides componentIds only', () {
      final original = MockNetworkElement(
        neId: 'ne-1',
        componentIds: ['comp-a'],
      );
      final copy = original.copyWith(componentIds: ['comp-x', 'comp-y']);
      expect(copy.neId, 'ne-1');
      expect(copy.componentIds, ['comp-x', 'comp-y']);
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = MockNetworkElement(
        neId: 'ne-1',
        componentIds: ['comp-a', 'comp-b'],
      );
      final copy = original.copyWith();
      expect(copy.neId, original.neId);
      expect(copy.componentIds, original.componentIds);
    });

    test('copyWith overrides both fields', () {
      final original = MockNetworkElement(
        neId: 'ne-1',
        componentIds: ['comp-a'],
      );
      final copy = original.copyWith(neId: 'ne-new', componentIds: ['comp-z']);
      expect(copy.neId, 'ne-new');
      expect(copy.componentIds, ['comp-z']);
    });

    test('Empty componentIds list is preserved', () {
      final ne = MockNetworkElement(neId: 'ne-empty', componentIds: []);
      expect(ne.componentIds, isEmpty);
    });
  });

  group('MockNetworkInventoryService Tests', () {
    late MockNetworkInventoryService service;

    setUp(() {
      service = MockNetworkInventoryService();
      service.resetToDefaults();
    });

    test('getNetworkElements returns default elements', () {
      final elements = service.getNetworkElements();
      expect(elements.length, 2);
      expect(elements[0].neId, 'ne-A');
      expect(elements[0].componentIds, ['comp-1', 'comp-2']);
      expect(elements[1].neId, 'ne-B');
      expect(elements[1].componentIds, ['comp-3', 'comp-4']);
    });

    test('getNetworkElements returns unmodifiable list', () {
      final elements = service.getNetworkElements();
      expect(() => elements.add(MockNetworkElement(neId: 'x', componentIds: [])),
          throwsUnsupportedError);
    });

    test('getNetworkElement returns existing element', () {
      final ne = service.getNetworkElement('ne-A');
      expect(ne, isNotNull);
      expect(ne!.neId, 'ne-A');
    });

    test('getNetworkElement returns null for non-existent ID', () {
      final ne = service.getNetworkElement('ne-Z');
      expect(ne, isNull);
    });

    test('addNetworkElement adds successfully', () {
      service.addNetworkElement(
          MockNetworkElement(neId: 'ne-C', componentIds: ['comp-5']));
      final elements = service.getNetworkElements();
      expect(elements.length, 3);
      expect(elements.last.neId, 'ne-C');
    });

    test('addNetworkElement throws on duplicate ID', () {
      expect(
        () => service.addNetworkElement(
            MockNetworkElement(neId: 'ne-A', componentIds: [])),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('already exists'))),
      );
    });

    test('deleteNetworkElement removes element', () {
      service.deleteNetworkElement('ne-A');
      final elements = service.getNetworkElements();
      expect(elements.length, 1);
      expect(elements[0].neId, 'ne-B');
    });

    test('deleteNetworkElement with non-existent ID does nothing', () {
      service.deleteNetworkElement('ne-Z');
      expect(service.getNetworkElements().length, 2);
    });

    test('addComponent adds to existing element', () {
      service.addComponent('ne-A', 'comp-new');
      final ne = service.getNetworkElement('ne-A');
      expect(ne!.componentIds, contains('comp-new'));
      expect(ne.componentIds.length, 3);
    });

    test('addComponent throws for non-existent element', () {
      expect(
        () => service.addComponent('ne-Z', 'comp-1'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('not found'))),
      );
    });

    test('addComponent throws for duplicate component', () {
      expect(
        () => service.addComponent('ne-A', 'comp-1'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('already exists'))),
      );
    });

    test('deleteComponent removes from element', () {
      service.deleteComponent('ne-A', 'comp-1');
      final ne = service.getNetworkElement('ne-A');
      expect(ne!.componentIds, ['comp-2']);
    });

    test('deleteComponent for non-existent element does nothing', () {
      service.deleteComponent('ne-Z', 'comp-1');
      expect(service.getNetworkElements().length, 2);
    });

    test('clearAll empties the list', () {
      service.clearAll();
      expect(service.getNetworkElements(), isEmpty);
    });

    test('resetToDefaults restores initial state after modifications', () {
      service.clearAll();
      expect(service.getNetworkElements(), isEmpty);
      service.resetToDefaults();
      expect(service.getNetworkElements().length, 2);
    });
  });
}
