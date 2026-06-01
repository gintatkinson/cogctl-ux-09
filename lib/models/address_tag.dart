enum YangAddressTagType {
  physAddress,
  macAddress,
  xpath10,
  hexString,
  uuid,
  dottedQuad,
  languageTag,
}

class YangAddressTagReference {
  final String id;
  final String name;
  final YangAddressTagType type;
  final String description;
  String value;

  YangAddressTagReference({
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

  factory YangAddressTagReference.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = YangAddressTagType.values.firstWhere((e) => e.name == typeName);
    return YangAddressTagReference(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      description: json['description'] as String,
      value: json['value'] as String,
    );
  }

  void updateValue(String newValue) {
    value = YangAddressTagValidator.validateAndNormalize(newValue, type);
  }
}

class YangAddressTagValidator {
  static final RegExp _physAddressRegExp = RegExp(r'^([0-9a-fA-F]{2}(:[0-9a-fA-F]{2})*)?$');
  static final RegExp _macAddressRegExp = RegExp(r'^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$');
  static final RegExp _uuidRegExp = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  static final RegExp _dottedQuadRegExp = RegExp(r'^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$');
  static final RegExp _languageTagRegExp = RegExp(r'^[a-zA-Z]{2,8}(-[a-zA-Z0-9]{1,8})*$');

  static String validateAndNormalize(String value, YangAddressTagType type) {
    final trimmed = value.trim();
    if (type != YangAddressTagType.physAddress && type != YangAddressTagType.hexString) {
      if (trimmed.isEmpty) {
        throw const FormatException("Value cannot be empty");
      }
    }

    switch (type) {
      case YangAddressTagType.physAddress:
      case YangAddressTagType.hexString:
        if (!_physAddressRegExp.hasMatch(trimmed)) {
          throw FormatException("Invalid hex-string/phys-address format: '$trimmed'. Must be colon-separated hex octets.");
        }
        return trimmed.toLowerCase();

      case YangAddressTagType.macAddress:
        if (!_macAddressRegExp.hasMatch(trimmed)) {
          throw FormatException("Invalid MAC address: '$trimmed'. Must be 6 octets of colon-separated hex characters.");
        }
        return trimmed.toLowerCase();

      case YangAddressTagType.uuid:
        if (!_uuidRegExp.hasMatch(trimmed)) {
          throw FormatException("Invalid UUID format: '$trimmed'. Must be 8-4-4-4-12 hex characters separated by hyphens.");
        }
        return trimmed.toLowerCase();

      case YangAddressTagType.dottedQuad:
        if (!_dottedQuadRegExp.hasMatch(trimmed)) {
          throw FormatException("Invalid dotted-quad format: '$trimmed'. Must be 4 octets separated by dots, each in range [0, 255].");
        }
        return trimmed;

      case YangAddressTagType.languageTag:
        if (!_languageTagRegExp.hasMatch(trimmed)) {
          throw FormatException("Invalid BCP 47 language tag: '$trimmed'.");
        }
        return trimmed.toLowerCase();

      case YangAddressTagType.xpath10:
        _validateXPathBrackets(trimmed);
        return trimmed;
    }
  }

  static void _validateXPathBrackets(String xpath) {
    int brackets = 0;
    int parens = 0;
    for (int i = 0; i < xpath.length; i++) {
      final char = xpath[i];
      if (char == '[') brackets++;
      if (char == ']') brackets--;
      if (char == '(') parens++;
      if (char == ')') parens--;
      if (brackets < 0) {
        throw const FormatException("Invalid XPath: Unbalanced square brackets (closing bracket before opening)");
      }
      if (parens < 0) {
        throw const FormatException("Invalid XPath: Unbalanced parentheses (closing parenthesis before opening)");
      }
    }
    if (brackets != 0) {
      throw const FormatException("Invalid XPath: Unbalanced square brackets");
    }
    if (parens != 0) {
      throw const FormatException("Invalid XPath: Unbalanced parentheses");
    }
  }
}
