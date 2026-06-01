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

abstract class LocationCoordinate {
  Map<String, dynamic> toJson();
}

class EllipsoidCoordinate extends LocationCoordinate {
  final double latitude;
  final double longitude;
  final double? height;

  EllipsoidCoordinate({
    required this.latitude,
    required this.longitude,
    this.height,
  });

  @override
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (height != null) 'height': height,
      };

  factory EllipsoidCoordinate.fromJson(Map<String, dynamic> json) {
    return EllipsoidCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }
}

class CartesianCoordinate extends LocationCoordinate {
  final double x;
  final double y;
  final double z;

  CartesianCoordinate({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
      };

  factory CartesianCoordinate.fromJson(Map<String, dynamic> json) {
    return CartesianCoordinate(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }
}

class Velocity {
  final double? vNorth;
  final double? vEast;
  final double? vUp;

  Velocity({this.vNorth, this.vEast, this.vUp});

  Map<String, dynamic> toJson() => {
        if (vNorth != null) 'v-north': vNorth,
        if (vEast != null) 'v-east': vEast,
        if (vUp != null) 'v-up': vUp,
      };

  factory Velocity.fromJson(Map<String, dynamic> json) {
    return Velocity(
      vNorth: json['v-north'] != null ? (json['v-north'] as num).toDouble() : null,
      vEast: json['v-east'] != null ? (json['v-east'] as num).toDouble() : null,
      vUp: json['v-up'] != null ? (json['v-up'] as num).toDouble() : null,
    );
  }

  bool get isEmpty => vNorth == null && vEast == null && vUp == null;
}

class GeoLocation {
  final ReferenceFrame referenceFrame;
  final String? networkDomain;
  final LocationCoordinate? location;
  final Velocity? velocity;

  GeoLocation({
    required this.referenceFrame,
    this.networkDomain,
    this.location,
    this.velocity,
  });

  Map<String, dynamic> toJson() => {
        'reference-frame': referenceFrame.toJson(),
        if (networkDomain != null) 'network-domain': networkDomain,
        if (location != null) ...location!.toJson(),
        if (velocity != null && !velocity!.isEmpty) 'velocity': velocity!.toJson(),
      };

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    LocationCoordinate? location;
    if (json.containsKey('latitude') && json.containsKey('longitude')) {
      location = EllipsoidCoordinate.fromJson(json);
    } else if (json.containsKey('x') && json.containsKey('y') && json.containsKey('z')) {
      location = CartesianCoordinate.fromJson(json);
    }
    return GeoLocation(
      referenceFrame: ReferenceFrame.fromJson(
          json['reference-frame'] as Map<String, dynamic>? ?? {}),
      networkDomain: json['network-domain'] as String?,
      location: location,
      velocity: json['velocity'] != null
          ? Velocity.fromJson(json['velocity'] as Map<String, dynamic>)
          : null,
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

  static void validateAlternateSystem(String value) {
    if (value.isNotEmpty && !isValidStringPattern(value)) {
      throw const FormatException(
          "Invalid characters in alternate system. Only standard ASCII without control chars allowed.");
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

  static double parseLatitude(String valString) {
    final trimmed = valString.trim();
    if (trimmed.isEmpty) {
      throw const FormatException("Latitude is required");
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw const FormatException("Must be a valid decimal number");
    }
    if (parsed < -90.0 || parsed > 90.0) {
      throw const FormatException("Latitude must be between -90.0 and 90.0 degrees");
    }
    final parts = trimmed.split('.');
    if (parts.length >= 2 && parts[1].length > 16) {
      throw const FormatException("Latitude precision cannot exceed 16 decimal places");
    }
    return parsed;
  }

  static double parseLongitude(String valString) {
    final trimmed = valString.trim();
    if (trimmed.isEmpty) {
      throw const FormatException("Longitude is required");
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw const FormatException("Must be a valid decimal number");
    }
    if (parsed < -180.0 || parsed > 180.0) {
      throw const FormatException("Longitude must be between -180.0 and 180.0 degrees");
    }
    final parts = trimmed.split('.');
    if (parts.length >= 2 && parts[1].length > 16) {
      throw const FormatException("Longitude precision cannot exceed 16 decimal places");
    }
    return parsed;
  }

  static double? parseHeight(String valString) {
    final trimmed = valString.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw const FormatException("Must be a valid decimal number");
    }
    final parts = trimmed.split('.');
    if (parts.length >= 2 && parts[1].length > 6) {
      throw const FormatException("Height precision cannot exceed 6 decimal places");
    }
    return parsed;
  }

  static double parseCartesianCoordinate(String valString, String axisName) {
    final trimmed = valString.trim();
    if (trimmed.isEmpty) {
      throw FormatException("$axisName coordinate is required in Cartesian mode");
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw const FormatException("Must be a valid decimal number");
    }
    final parts = trimmed.split('.');
    if (parts.length >= 2 && parts[1].length > 6) {
      throw FormatException("$axisName coordinate precision cannot exceed 6 decimal places");
    }
    return parsed;
  }

  static double? parseVelocityComponent(String valString, String componentName) {
    final trimmed = valString.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw const FormatException("Must be a valid decimal number");
    }
    const double limit = 9.223372036854775807e18;
    if (parsed < -limit || parsed > limit) {
      throw FormatException("$componentName exceeds the physical limits of decimal64");
    }
    final parts = trimmed.split('.');
    if (parts.length >= 2 && parts[1].length > 12) {
      throw FormatException("$componentName precision cannot exceed 12 decimal places");
    }
    return parsed;
  }
}
