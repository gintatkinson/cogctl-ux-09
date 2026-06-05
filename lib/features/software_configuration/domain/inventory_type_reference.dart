class MockInventoryTypeReference {
  final String id;
  final String referenceType; // 'ne-ref', 'component-ref', 'port-ref'
  final String neRef;
  final String? targetRef; // component-id or port-id
  final String? customComponentClass; // to allow user to simulate class override

  MockInventoryTypeReference({
    required this.id,
    required this.referenceType,
    required this.neRef,
    this.targetRef,
    this.customComponentClass,
  });

  MockInventoryTypeReference copyWith({
    String? id,
    String? referenceType,
    String? neRef,
    String? targetRef,
    String? customComponentClass,
  }) {
    return MockInventoryTypeReference(
      id: id ?? this.id,
      referenceType: referenceType ?? this.referenceType,
      neRef: neRef ?? this.neRef,
      targetRef: targetRef ?? this.targetRef,
      customComponentClass: customComponentClass ?? this.customComponentClass,
    );
  }
}

class IetfInventoryIdentities {
  static const String nonHardwareComponentClass = 'non-hardware-component-class';
  static const String neType = 'ne-type';
  static const String nePhysical = 'ne-physical';
  static const String ianahwPort = 'ianahw:port';
  static const String ianahwChassis = 'ianahw:chassis';

  static bool isPortOrDerived(String componentClass) {
    // Exact or derived (e.g. if it contains ianahw:port or sub-class)
    return componentClass == ianahwPort || componentClass.startsWith('$ianahwPort:');
  }
}
