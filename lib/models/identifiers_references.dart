enum YangIdentifierType {
  objectIdentifier,
  objectIdentifier128,
  yangIdentifier,
}

class YangIdentifierReference {
  final String id;
  final String name;
  final YangIdentifierType type;
  final String description;
  String value;

  YangIdentifierReference({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'value': value,
      };

  factory YangIdentifierReference.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = YangIdentifierType.values.firstWhere((e) => e.name == typeName);
    return YangIdentifierReference(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      description: json['description'] as String,
      value: json['value'] as String,
    );
  }

  void updateValue(String newValue) {
    YangIdentifierValidator.validate(newValue, type);
    value = newValue;
  }
}

class YangIdentifierValidator {
  // Regex pattern matching RFC 9911 object-identifier type.
  // First arc: 0 or 1 followed by .[0-39] (which is represented by [1-3]?[0-9]) OR 2 followed by .[any number without leading zero].
  // Subsequent arcs: .[any number without leading zero].
  static final RegExp _oidRegExp = RegExp(
    r'^(([0-1](\.[1-3]?[0-9]))|(2\.(0|([1-9][0-9]*))))(\.(0|([1-9][0-9]*)))*$',
  );

  static void validate(String value, YangIdentifierType type) {
    switch (type) {
      case YangIdentifierType.objectIdentifier:
        validateObjectIdentifier(value);
        break;
      case YangIdentifierType.objectIdentifier128:
        validateObjectIdentifier128(value);
        break;
      case YangIdentifierType.yangIdentifier:
        validateYangIdentifier(value);
        break;
    }
  }

  static void validateObjectIdentifier(String value) {
    if (value.isEmpty) {
      throw const FormatException("Object identifier cannot be empty");
    }

    // Give friendly messages for obvious validation failures
    final firstDotIdx = value.indexOf('.');
    if (firstDotIdx == -1) {
      throw const FormatException("Object identifier must contain at least two arcs separated by '.'");
    }

    final firstArcStr = value.substring(0, firstDotIdx);
    final firstArc = int.tryParse(firstArcStr);
    if (firstArc == null || firstArc < 0 || firstArc > 2) {
      throw const FormatException("Root arc (first sub-identifier) must be 0, 1, or 2");
    }

    // Find the second arc
    final secondDotIdx = value.indexOf('.', firstDotIdx + 1);
    final secondArcStr = secondDotIdx == -1
        ? value.substring(firstDotIdx + 1)
        : value.substring(firstDotIdx + 1, secondDotIdx);
    final secondArc = int.tryParse(secondArcStr);
    if (secondArc == null) {
      throw const FormatException("Invalid second sub-identifier");
    }

    if ((firstArc == 0 || firstArc == 1) && (secondArc < 0 || secondArc > 39)) {
      throw const FormatException("Second sub-identifier must be between 0 and 39 when root arc is 0 or 1");
    }

    // General pattern check
    if (!_oidRegExp.hasMatch(value)) {
      // Check for leading zero issue in any segment
      final segments = value.split('.');
      for (final seg in segments) {
        if (seg.isEmpty) {
          throw const FormatException("Sub-identifier segments cannot be empty");
        }
        if (seg.length > 1 && seg.startsWith('0')) {
          throw const FormatException("Sub-identifiers cannot have leading zeros (except '0' itself)");
        }
        if (int.tryParse(seg) == null) {
          throw const FormatException("Sub-identifiers must be valid non-negative integers");
        }
      }
      throw const FormatException("Object identifier format is invalid");
    }
  }

  static void validateObjectIdentifier128(String value) {
    // Must satisfy general object-identifier rules
    validateObjectIdentifier(value);

    // Must have at most 128 sub-identifiers
    final segments = value.split('.');
    if (segments.length > 128) {
      throw FormatException(
        "Object identifier-128 cannot exceed 128 sub-identifiers (found ${segments.length})",
      );
    }
  }

  static void validateYangIdentifier(String value) {
    if (value.isEmpty) {
      throw const FormatException("YANG identifier cannot be empty");
    }

    if (value.toLowerCase().startsWith('xml')) {
      throw const FormatException("YANG identifier cannot start with 'xml' (case-insensitive)");
    }

    final regExp = RegExp(r'^[a-zA-Z_][a-zA-Z0-9\-_.]*$');
    if (!regExp.hasMatch(value)) {
      if (value.startsWith('-')) {
        throw const FormatException("YANG identifier cannot start with '-'");
      }
      throw const FormatException(
        "YANG identifier contains invalid characters (only alphanumeric, '-', '_', '.' allowed, and must start with a letter or '_')",
      );
    }
  }
}
