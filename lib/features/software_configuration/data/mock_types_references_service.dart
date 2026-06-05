import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';
import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';
import 'package:cogctl_ux/features/infrastructure/data/mock_network_inventory_service.dart';

class MockTypesReferencesService {
  static final MockTypesReferencesService _instance = MockTypesReferencesService._internal();

  factory MockTypesReferencesService() {
    return _instance;
  }

  MockTypesReferencesService._internal() {
    _resetDefaults();
  }

  final List<MockInventoryTypeReference> _references = [];
  final Map<String, String> _componentClasses = {};

  final MockNetworkInventoryService _networkInventoryService = MockNetworkInventoryService();

  void _resetDefaults() {
    _references.clear();
    _componentClasses.clear();

    // Seed default component classes
    _componentClasses['comp-1'] = IetfInventoryIdentities.ianahwPort;
    _componentClasses['comp-2'] = IetfInventoryIdentities.ianahwChassis;
    _componentClasses['comp-3'] = IetfInventoryIdentities.ianahwPort;
    _componentClasses['comp-4'] = IetfInventoryIdentities.nonHardwareComponentClass;
    _componentClasses['chassis-01'] = IetfInventoryIdentities.ianahwChassis;
    _componentClasses['gigabit-port-01'] = IetfInventoryIdentities.ianahwPort;

    // Ensure ne-01 is present in the network inventory service
    try {
      if (_networkInventoryService.getNetworkElement('ne-01') == null) {
        _networkInventoryService.addNetworkElement(MockNetworkElement(
          neId: 'ne-01',
          componentIds: ['chassis-01', 'gigabit-port-01'],
        ));
      }
    } on FormatException catch (_) {}

    // Seed default reference configurations
    _references.add(MockInventoryTypeReference(
      id: 'default-ne-ref',
      referenceType: 'ne-ref',
      neRef: 'ne-01',
    ));
    _references.add(MockInventoryTypeReference(
      id: 'default-component-ref',
      referenceType: 'component-ref',
      neRef: 'ne-01',
      targetRef: 'chassis-01',
    ));
    _references.add(MockInventoryTypeReference(
      id: 'default-port-ref',
      referenceType: 'port-ref',
      neRef: 'ne-01',
      targetRef: 'gigabit-port-01',
    ));
  }

  void resetToDefaults() {
    _resetDefaults();
  }

  List<MockInventoryTypeReference> getReferences() {
    return List.unmodifiable(_references);
  }

  void addReference(MockInventoryTypeReference ref) {
    if (_references.any((r) => r.id == ref.id)) {
      throw FormatException("Reference configuration ID '${ref.id}' already exists.");
    }
    _references.add(ref);
  }

  void deleteReference(String id) {
    _references.removeWhere((r) => r.id == id);
  }

  String getComponentClass(String compId) {
    return _componentClasses[compId] ?? IetfInventoryIdentities.nonHardwareComponentClass;
  }

  void setComponentClass(String compId, String compClass) {
    _componentClasses[compId] = compClass;
  }

  String validateReference(MockInventoryTypeReference ref) {
    final ne = _networkInventoryService.getNetworkElement(ref.neRef);
    
    // Check if network element exists
    if (ne == null) {
      // Under require-instance: false, it is technically syntactically valid in YANG but structurally unresolved.
      return 'Unresolved: Network Element ${ref.neRef} not found';
    }

    if (ref.referenceType == 'ne-ref') {
      return 'Valid';
    }

    // Check targetRef
    final target = ref.targetRef;
    if (target == null || target.isEmpty) {
      return 'Invalid: Target component/port is not specified.';
    }

    // Check if component exists in that network element
    if (!ne.componentIds.contains(target)) {
      return 'Unresolved: Component $target not found';
    }

    // Determine the component class
    final compClass = ref.customComponentClass ?? getComponentClass(target);

    if (ref.referenceType == 'port-ref') {
      if (!IetfInventoryIdentities.isPortOrDerived(compClass)) {
        return 'Invalid: Port class constraint violated. Component class is "$compClass" instead of "${IetfInventoryIdentities.ianahwPort}".';
      }
    }

    return 'Valid';
  }
}
