enum YangTimeDurationType {
  hours32,
  minutes32,
  seconds32,
  centiseconds32,
  milliseconds32,
  microseconds32,
  microseconds64,
  nanoseconds32,
  nanoseconds64,
  timeticks,
  timestamp,
}

class YangTimeDurationReference {
  final String id;
  final String name;
  final YangTimeDurationType type;
  final String description;
  String value;
  final String? associatedNodeId; // For linking timestamp -> timeticks

  YangTimeDurationReference({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.value,
    this.associatedNodeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'value': value,
        'associatedNodeId': associatedNodeId,
      };

  factory YangTimeDurationReference.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = YangTimeDurationType.values.firstWhere((e) => e.name == typeName);
    return YangTimeDurationReference(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      description: json['description'] as String,
      value: json['value'] as String,
      associatedNodeId: json['associatedNodeId'] as String?,
    );
  }

  void updateValue(String newValue) {
    YangTimeDurationValidator.validate(newValue, type);
    value = newValue.trim();
  }
}

class YangTimeDurationValidator {
  static void validate(String value, YangTimeDurationType type) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException("Value cannot be empty");
    }

    // Try to parse number
    final is64Bit = type == YangTimeDurationType.microseconds64 || type == YangTimeDurationType.nanoseconds64;
    
    if (is64Bit) {
      final parsed = BigInt.tryParse(trimmed);
      if (parsed == null) {
        throw FormatException("Value '$trimmed' is not a valid 64-bit integer");
      }
      final minInt64 = BigInt.parse("-9223372036854775808");
      final maxInt64 = BigInt.parse("9223372036854775807");
      if (parsed < minInt64 || parsed > maxInt64) {
        throw FormatException("Value '$trimmed' exceeds 64-bit signed integer range");
      }
    } else {
      final parsed = int.tryParse(trimmed);
      if (parsed == null) {
        throw FormatException("Value '$trimmed' is not a valid integer");
      }

      // Check bounds
      if (type == YangTimeDurationType.timeticks || type == YangTimeDurationType.timestamp) {
        if (parsed < 0 || parsed > 4294967295) {
          throw FormatException("Value '$trimmed' is outside of 32-bit unsigned range [0, 4294967295]");
        }
      } else {
        // signed int32
        if (parsed < -2147483648 || parsed > 2147483647) {
          throw FormatException("Value '$trimmed' exceeds 32-bit signed integer range");
        }
        
        // Unit-specific capability bounds check
        if (type == YangTimeDurationType.nanoseconds32) {
          if (parsed < -2000000000 || parsed > 2000000000) {
            throw FormatException("Value '$trimmed' exceeds unit-specific capability bound of 2 seconds (2,000,000,000 ns)");
          }
        }
      }
    }
  }
}
