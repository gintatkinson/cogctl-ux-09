import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';

class MockNetworkInventoryService {
  static final MockNetworkInventoryService _instance = MockNetworkInventoryService._internal();

  factory MockNetworkInventoryService() {
    return _instance;
  }

  MockNetworkInventoryService._internal() {
    _resetDefaults();
  }

  final List<MockNetworkElement> _elements = [];

  void _resetDefaults() {
    _elements.clear();
    _elements.add(MockNetworkElement(
      neId: 'ne-A',
      componentIds: ['comp-1', 'comp-2'],
    ));
    _elements.add(MockNetworkElement(
      neId: 'ne-B',
      componentIds: ['comp-3', 'comp-4'],
    ));
  }

  void resetToDefaults() {
    _resetDefaults();
  }

  List<MockNetworkElement> getNetworkElements() {
    return List.unmodifiable(_elements);
  }

  MockNetworkElement? getNetworkElement(String neId) {
    try {
      return _elements.firstWhere((e) => e.neId == neId);
    } catch (_) {
      return null;
    }
  }

  void addNetworkElement(MockNetworkElement ne) {
    if (_elements.any((e) => e.neId == ne.neId)) {
      throw FormatException("Network Element ID '${ne.neId}' already exists.");
    }
    _elements.add(ne);
  }

  void deleteNetworkElement(String neId) {
    _elements.removeWhere((e) => e.neId == neId);
  }

  void addComponent(String neId, String componentId) {
    final index = _elements.indexWhere((e) => e.neId == neId);
    if (index == -1) {
      throw FormatException("Network Element '$neId' not found.");
    }
    final ne = _elements[index];
    if (ne.componentIds.contains(componentId)) {
      throw FormatException("Component '$componentId' already exists in Network Element '$neId'.");
    }
    final updatedList = List<String>.from(ne.componentIds)..add(componentId);
    _elements[index] = ne.copyWith(componentIds: updatedList);
  }

  void deleteComponent(String neId, String componentId) {
    final index = _elements.indexWhere((e) => e.neId == neId);
    if (index == -1) return;
    final ne = _elements[index];
    final updatedList = List<String>.from(ne.componentIds)..remove(componentId);
    _elements[index] = ne.copyWith(componentIds: updatedList);
  }

  void clearAll() {
    _elements.clear();
  }
}
