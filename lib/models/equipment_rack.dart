class RackLocation {
  final String locationRef;
  final int? rowNumber;
  final int? columnNumber;

  RackLocation({
    required this.locationRef,
    this.rowNumber,
    this.columnNumber,
  });

  RackLocation copyWith({
    String? locationRef,
    int? rowNumber,
    int? columnNumber,
  }) {
    return RackLocation(
      locationRef: locationRef ?? this.locationRef,
      rowNumber: rowNumber ?? this.rowNumber,
      columnNumber: columnNumber ?? this.columnNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'location-ref': locationRef,
        'row-number': rowNumber,
        'column-number': columnNumber,
      };

  factory RackLocation.fromJson(Map<String, dynamic> json) {
    return RackLocation(
      locationRef: json['location-ref'] as String,
      rowNumber: json['row-number'] as int?,
      columnNumber: json['column-number'] as int?,
    );
  }
}

class RackContainedChassis {
  final int relativePosition; // uint8
  final String neRef;
  final String componentRef;
  final int powerConsumption; // in Watts

  RackContainedChassis({
    required this.relativePosition,
    required this.neRef,
    required this.componentRef,
    required this.powerConsumption,
  });

  RackContainedChassis copyWith({
    int? relativePosition,
    String? neRef,
    String? componentRef,
    int? powerConsumption,
  }) {
    return RackContainedChassis(
      relativePosition: relativePosition ?? this.relativePosition,
      neRef: neRef ?? this.neRef,
      componentRef: componentRef ?? this.componentRef,
      powerConsumption: powerConsumption ?? this.powerConsumption,
    );
  }

  Map<String, dynamic> toJson() => {
        'relative-position': relativePosition,
        'ne-ref': neRef,
        'component-ref': componentRef,
        'power-consumption': powerConsumption,
      };

  factory RackContainedChassis.fromJson(Map<String, dynamic> json) {
    return RackContainedChassis(
      relativePosition: json['relative-position'] as int,
      neRef: json['ne-ref'] as String,
      componentRef: json['component-ref'] as String,
      powerConsumption: json['power-consumption'] as int,
    );
  }
}

class EquipmentRack {
  final String id;
  final String rackClass;
  final int height; // in mm
  final int width;  // in mm
  final int depth;  // in mm
  final DateTime timestamp;
  final DateTime validUntil;
  final RackLocation? rackLocation;
  final int maxVoltage; // in Volts (uint16)
  final int maxAllocatedPower; // in Watts (uint16)
  final List<RackContainedChassis> containedChassis;

  EquipmentRack({
    required this.id,
    required this.rackClass,
    required this.height,
    required this.width,
    required this.depth,
    required this.timestamp,
    required this.validUntil,
    this.rackLocation,
    this.maxVoltage = 0,
    this.maxAllocatedPower = 0,
    this.containedChassis = const [],
  });

  EquipmentRack copyWith({
    String? id,
    String? rackClass,
    int? height,
    int? width,
    int? depth,
    DateTime? timestamp,
    DateTime? validUntil,
    RackLocation? Function()? rackLocation,
    int? maxVoltage,
    int? maxAllocatedPower,
    List<RackContainedChassis>? containedChassis,
  }) {
    return EquipmentRack(
      id: id ?? this.id,
      rackClass: rackClass ?? this.rackClass,
      height: height ?? this.height,
      width: width ?? this.width,
      depth: depth ?? this.depth,
      timestamp: timestamp ?? this.timestamp,
      validUntil: validUntil ?? this.validUntil,
      rackLocation: rackLocation != null ? rackLocation() : this.rackLocation,
      maxVoltage: maxVoltage ?? this.maxVoltage,
      maxAllocatedPower: maxAllocatedPower ?? this.maxAllocatedPower,
      containedChassis: containedChassis ?? this.containedChassis,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rack-class': rackClass,
        'height': height,
        'width': width,
        'depth': depth,
        'timestamp': timestamp.toIso8601String(),
        'valid-until': validUntil.toIso8601String(),
        if (rackLocation != null) 'rack-location': rackLocation!.toJson(),
        'max-voltage': maxVoltage,
        'max-allocated-power': maxAllocatedPower,
        'contained-chassis': containedChassis.map((c) => c.toJson()).toList(),
      };

  factory EquipmentRack.fromJson(Map<String, dynamic> json) {
    return EquipmentRack(
      id: json['id'] as String,
      rackClass: json['rack-class'] as String,
      height: json['height'] as int,
      width: json['width'] as int,
      depth: json['depth'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      validUntil: DateTime.parse(json['valid-until'] as String),
      rackLocation: json['rack-location'] != null
          ? RackLocation.fromJson(json['rack-location'] as Map<String, dynamic>)
          : null,
      maxVoltage: json['max-voltage'] as int? ?? 0,
      maxAllocatedPower: json['max-allocated-power'] as int? ?? 0,
      containedChassis: (json['contained-chassis'] as List<dynamic>?)
              ?.map((c) => RackContainedChassis.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class EquipmentRackValidator {
  static const List<String> validRackClasses = [
    'rack-standard',
    'rack-secure-baseline',
    'rack-secure-medium',
    'rack-secure-high',
  ];

  static void validate({
    required String id,
    required String rackClass,
    required int height,
    required int width,
    required int depth,
    required DateTime timestamp,
    required DateTime validUntil,
    RackLocation? rackLocation,
    Set<String> validLocationIds = const {},
    int maxVoltage = 0,
    int maxAllocatedPower = 0,
    List<RackContainedChassis> containedChassis = const [],
    Map<String, List<String>> validNeComponents = const {},
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw const FormatException("Rack ID cannot be empty");
    }

    if (!validRackClasses.contains(rackClass)) {
      throw FormatException(
        "Rack class '$rackClass' is not a valid descendant of rack-class-type",
      );
    }

    if (height <= 0 || height > 65535) {
      throw FormatException("Rack height must be a positive integer between 1 and 65535 mm");
    }

    if (width <= 0 || width > 65535) {
      throw FormatException("Rack width must be a positive integer between 1 and 65535 mm");
    }

    if (depth <= 0 || depth > 65535) {
      throw FormatException("Rack depth must be a positive integer between 1 and 65535 mm");
    }

    if (!validUntil.isAfter(timestamp)) {
      throw const FormatException("Rack valid-until timestamp must be after recording timestamp");
    }

    if (maxVoltage < 0 || maxVoltage > 65535) {
      throw const FormatException("Max voltage must be a uint16 integer (0-65535)");
    }

    if (maxAllocatedPower < 0 || maxAllocatedPower > 65535) {
      throw const FormatException("Max allocated power must be a uint16 integer (0-65535)");
    }

    // Validate contained chassis
    final Set<int> positions = {};
    int totalPower = 0;
    for (final chassis in containedChassis) {
      if (chassis.relativePosition < 1 || chassis.relativePosition > 255) {
        throw FormatException("Chassis relative position must be a uint8 integer (1-255)");
      }

      if (positions.contains(chassis.relativePosition)) {
        throw FormatException("Chassis slot conflict at U-slot position ${chassis.relativePosition}");
      }
      positions.add(chassis.relativePosition);

      totalPower += chassis.powerConsumption;

      // Validate referential integrity
      if (validNeComponents.isNotEmpty) {
        if (!validNeComponents.containsKey(chassis.neRef)) {
          throw FormatException("Network Element '${chassis.neRef}' does not exist in inventory");
        }
        final components = validNeComponents[chassis.neRef] ?? [];
        if (!components.contains(chassis.componentRef)) {
          throw FormatException(
              "Component '${chassis.componentRef}' does not exist in Network Element '${chassis.neRef}'");
        }
      }
    }

    if (totalPower > maxAllocatedPower) {
      throw FormatException(
          "Total power consumption ($totalPower W) exceeds rack max allocated power ($maxAllocatedPower W)");
    }

    if (rackLocation != null) {
      final locRef = rackLocation.locationRef.trim();
      if (locRef.isEmpty) {
        throw const FormatException("Location reference cannot be empty");
      }
      if (validLocationIds.isNotEmpty && !validLocationIds.contains(locRef)) {
        throw FormatException("Location reference '$locRef' does not exist in the registry");
      }
      if (rackLocation.rowNumber != null) {
        if (rackLocation.rowNumber! <= 0 || rackLocation.rowNumber! > 4294967295) {
          throw const FormatException("Row number must be a positive uint32 integer (>= 1)");
        }
      }
      if (rackLocation.columnNumber != null) {
        if (rackLocation.columnNumber! <= 0 || rackLocation.columnNumber! > 4294967295) {
          throw const FormatException("Column number must be a positive uint32 integer (>= 1)");
        }
      }
    }
  }
}
