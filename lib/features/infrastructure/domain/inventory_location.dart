class PhysicalAddress {
  final String address;
  final String postalCode;
  final String state;
  final String city;
  final String countryCode;

  PhysicalAddress({
    required this.address,
    required this.postalCode,
    required this.state,
    required this.city,
    required this.countryCode,
  });

  String toPostalLabel() {
    return "$address, $city, $state $postalCode, $countryCode";
  }

  String toMapSearchQuery() {
    return "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$address, $city, $state $postalCode, $countryCode')}";
  }
}

class ContainedChassis {
  final int chassisId;
  final String neRef;
  final String componentRef;

  ContainedChassis({
    required this.chassisId,
    required this.neRef,
    required this.componentRef,
  });

  ContainedChassis copyWith({
    int? chassisId,
    String? neRef,
    String? componentRef,
  }) {
    return ContainedChassis(
      chassisId: chassisId ?? this.chassisId,
      neRef: neRef ?? this.neRef,
      componentRef: componentRef ?? this.componentRef,
    );
  }
}

class InventoryLocation {
  final String id;
  final String type;
  final String? parent;
  final DateTime timestamp;
  final DateTime? validUntil;
  final PhysicalAddress? physicalAddress;
  final List<ContainedChassis> containedChassis;

  InventoryLocation({
    required this.id,
    required this.type,
    this.parent,
    required this.timestamp,
    this.validUntil,
    this.physicalAddress,
    this.containedChassis = const [],
  });

  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().toUtc().isAfter(validUntil!);
  }

  bool isValidAt(DateTime time) {
    if (time.isBefore(timestamp)) return false;
    if (validUntil == null) return true;
    return !time.isAfter(validUntil!);
  }

  InventoryLocation copyWith({
    String? id,
    String? type,
    String? parent,
    DateTime? timestamp,
    DateTime? validUntil,
    PhysicalAddress? Function()? physicalAddress,
    List<ContainedChassis>? containedChassis,
  }) {
    return InventoryLocation(
      id: id ?? this.id,
      type: type ?? this.type,
      parent: parent ?? this.parent,
      timestamp: timestamp ?? this.timestamp,
      validUntil: validUntil ?? this.validUntil,
      physicalAddress: physicalAddress != null ? physicalAddress() : this.physicalAddress,
      containedChassis: containedChassis ?? this.containedChassis,
    );
  }
}

class InventoryLocationValidator {
  /// Detects circular dependency loop by recursively traversing up the parent chain.
  /// If [id] is found in the path starting from [proposedParentId], a circular dependency exists.
  static void detectCircularLoop(
    String id,
    String? proposedParentId,
    List<InventoryLocation> allLocations,
  ) {
    if (proposedParentId == null) return;
    
    // Prevent self-referential parent
    if (id == proposedParentId) {
      throw FormatException(
        "Circular dependency loop detected: location '$id' cannot be its own parent."
      );
    }

    final visited = <String>{id};
    String? currentParentId = proposedParentId;

    while (currentParentId != null) {
      if (visited.contains(currentParentId)) {
        throw FormatException(
          "Circular dependency loop detected: setting '$proposedParentId' as parent of '$id' creates a closed loop."
        );
      }
      visited.add(currentParentId);

      // Find the parent node in the registry
      final parentNode = allLocations.firstWhere(
        (loc) => loc.id == currentParentId,
        orElse: () => throw FormatException(
          "Parent location '$currentParentId' does not exist in the registry."
        ),
      );

      currentParentId = parentNode.parent;
    }
  }

  /// Checks validity parameters and raises a FormatException if invalid.
  static void validateTemporalBounds(DateTime timestamp, DateTime? validUntil) {
    if (validUntil != null && validUntil.isBefore(timestamp)) {
      throw const FormatException(
        "Expiration timestamp ('valid-until') must not be earlier than the recording timestamp ('timestamp')."
      );
    }
  }

  /// Validates ISO 3166-1 Alpha-2 country code.
  static void validateCountryCode(String code) {
    final reg = RegExp(r'^[A-Z]{2}$');
    if (!reg.hasMatch(code)) {
      throw const FormatException(
        "Country code must be a valid ISO 3166-1 Alpha-2 uppercase 2-letter code (e.g. 'US')."
      );
    }
  }

  /// Validates a ContainedChassis instance
  static void validateContainedChassis(ContainedChassis chassis, List<ContainedChassis> existingChassis) {
    if (chassis.chassisId < 0 || chassis.chassisId > 4294967295) {
      throw const FormatException("Chassis ID must be a valid uint32 (0 to 4294967295).");
    }
    if (existingChassis.any((c) => c.chassisId == chassis.chassisId)) {
      throw FormatException("Chassis ID ${chassis.chassisId} is already in use at this location.");
    }
  }
}
