class GeodeticSystem {
  final String geodeticDatum;
  final double? coordAccuracy;
  final double? heightAccuracy;

  GeodeticSystem({
    required this.geodeticDatum,
    this.coordAccuracy,
    this.heightAccuracy,
  });

  Map<String, dynamic> toJson() => {
        'geodetic-datum': geodeticDatum,
        if (coordAccuracy != null) 'coord-accuracy': coordAccuracy,
        if (heightAccuracy != null) 'height-accuracy': heightAccuracy,
      };

  factory GeodeticSystem.fromJson(Map<String, dynamic> json) {
    return GeodeticSystem(
      geodeticDatum: json['geodetic-datum'] as String? ?? 'wgs-84',
      coordAccuracy: json['coord-accuracy'] != null
          ? (json['coord-accuracy'] as num).toDouble()
          : null,
      heightAccuracy: json['height-accuracy'] != null
          ? (json['height-accuracy'] as num).toDouble()
          : null,
    );
  }
}

class ReferenceFrame {
  final String astronomicalBody;
  final String? alternateSystem;
  final GeodeticSystem geodeticSystem;

  ReferenceFrame({
    required this.astronomicalBody,
    this.alternateSystem,
    required this.geodeticSystem,
  });

  Map<String, dynamic> toJson() => {
        'astronomical-body': astronomicalBody,
        if (alternateSystem != null) 'alternate-system': alternateSystem,
        'geodetic-system': geodeticSystem.toJson(),
      };

  factory ReferenceFrame.fromJson(Map<String, dynamic> json) {
    return ReferenceFrame(
      astronomicalBody: json['astronomical-body'] as String? ?? 'earth',
      alternateSystem: json['alternate-system'] as String?,
      geodeticSystem: GeodeticSystem.fromJson(
          json['geodetic-system'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class GeoLocation {
  final ReferenceFrame referenceFrame;

  GeoLocation({
    required this.referenceFrame,
  });

  Map<String, dynamic> toJson() => {
        'reference-frame': referenceFrame.toJson(),
      };

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      referenceFrame: ReferenceFrame.fromJson(
          json['reference-frame'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class ReferenceFrameValidator {
  // Regex pattern matching space to @ (32-64) and [ to ~ (91-126)
  static final RegExp asciiPattern = RegExp(r'^[ -@\[-\^_-~]*$');

  static String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '-');
  }

  static bool isValidStringPattern(String value) {
    return asciiPattern.hasMatch(value);
  }

  static void validateAstronomicalBody(String value) {
    if (value.isNotEmpty && !isValidStringPattern(value)) {
      throw const FormatException(
          "Invalid characters in astronomical body. Only standard ASCII without control chars allowed.");
    }
  }

  static void validateGeodeticDatum(String value) {
    if (value.isNotEmpty && !isValidStringPattern(value)) {
      throw const FormatException(
          "Invalid characters in geodetic datum. Only standard ASCII without control chars allowed.");
    }
  }

  static double? parseAccuracy(String valString) {
    final trimmed = valString.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw const FormatException("Must be a valid decimal number");
    }
    if (parsed < 0) {
      throw const FormatException("Must be a non-negative decimal");
    }
    final parts = trimmed.split('.');
    if (parts.length >= 2 && parts[1].length > 6) {
      throw const FormatException("Accuracy cannot exceed 6 decimal places");
    }
    return parsed;
  }
}
