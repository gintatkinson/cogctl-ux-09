class EquipmentRack {
  final String id;
  final String rackClass;
  final int height; // in mm
  final int width;  // in mm
  final int depth;  // in mm
  final DateTime timestamp;
  final DateTime validUntil;

  EquipmentRack({
    required this.id,
    required this.rackClass,
    required this.height,
    required this.width,
    required this.depth,
    required this.timestamp,
    required this.validUntil,
  });

  EquipmentRack copyWith({
    String? id,
    String? rackClass,
    int? height,
    int? width,
    int? depth,
    DateTime? timestamp,
    DateTime? validUntil,
  }) {
    return EquipmentRack(
      id: id ?? this.id,
      rackClass: rackClass ?? this.rackClass,
      height: height ?? this.height,
      width: width ?? this.width,
      depth: depth ?? this.depth,
      timestamp: timestamp ?? this.timestamp,
      validUntil: validUntil ?? this.validUntil,
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
  }
}
