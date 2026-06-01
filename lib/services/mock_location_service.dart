import '../models/geo_location.dart';

class MockLocationService {
  static final MockLocationService _instance = MockLocationService._internal();
  factory MockLocationService() => _instance;

  final List<GeoLocation> _locations = [];

  MockLocationService._internal() {
    final now = DateTime.now();
    // Populate with SDN Multi-Domain Network Reference Frames & coordinates
    _locations.addAll([
      GeoLocation(
        networkDomain: 'Terrestrial Fiber (L0-L4)',
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.001,
            heightAccuracy: 0.01,
          ),
        ),
        location: EllipsoidCoordinate(
          latitude: 37.7749,
          longitude: -122.4194,
          height: 10.0,
        ),
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      GeoLocation(
        networkDomain: 'Submarine Cable (Subsea)',
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.002,
            heightAccuracy: 0.05,
          ),
        ),
        location: EllipsoidCoordinate(
          latitude: 20.2606,
          longitude: -121.7251,
          height: -4500.0,
        ),
        timestamp: now.subtract(const Duration(hours: 2)),
        validUntil: now.add(const Duration(days: 10)),
      ),
      GeoLocation(
        networkDomain: 'Non-Terrestrial Network (NTN)',
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          alternateSystem: 'ecef',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.01,
            heightAccuracy: 0.1,
          ),
        ),
        location: EllipsoidCoordinate(
          latitude: 0.0,
          longitude: -75.0,
          height: 35786000.0,
        ),
        velocity: Velocity(
          vNorth: 7500.0,
          vEast: 500.0,
          vUp: 0.0,
        ),
        timestamp: now.subtract(const Duration(days: 5)),
        validUntil: now.subtract(const Duration(days: 2)), // Expired
      ),
      GeoLocation(
        networkDomain: 'Deep Space Network (DSN)',
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'mars',
          alternateSystem: 'iau-2015',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'areocentric-2015',
            coordAccuracy: 0.05,
            heightAccuracy: 0.1,
          ),
        ),
        location: EllipsoidCoordinate(
          latitude: -22.3792,
          longitude: 136.2751,
          height: 150.0,
        ),
        velocity: Velocity(
          vNorth: -12000.0,
          vEast: 8500.0,
          vUp: -150.0,
        ),
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      GeoLocation(
        networkDomain: 'Quantum Key Distribution (QKD)',
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.0001,
            heightAccuracy: 0.001,
          ),
        ),
        location: EllipsoidCoordinate(
          latitude: 35.6762,
          longitude: 139.6503,
          height: 25.0,
        ),
        timestamp: now,
        validUntil: now.add(const Duration(days: 30)),
      ),
    ]);
  }

  List<GeoLocation> getLocations() => List.unmodifiable(_locations);

  void addLocation(GeoLocation location) {
    // Basic validation checks before saving to mock DB
    final frame = location.referenceFrame;
    ReferenceFrameValidator.validateAstronomicalBody(frame.astronomicalBody);
    ReferenceFrameValidator.validateGeodeticDatum(frame.geodeticSystem.geodeticDatum);
    
    if (frame.geodeticSystem.coordAccuracy != null && frame.geodeticSystem.coordAccuracy! < 0) {
      throw const FormatException("Coordinate accuracy must be non-negative");
    }
    if (frame.geodeticSystem.heightAccuracy != null && frame.geodeticSystem.heightAccuracy! < 0) {
      throw const FormatException("Height accuracy must be non-negative");
    }

    final loc = location.location;
    if (loc != null && loc is EllipsoidCoordinate) {
      if (loc.latitude < -90.0 || loc.latitude > 90.0) {
        throw const FormatException("Latitude must be between -90.0 and 90.0");
      }
      if (loc.longitude < -180.0 || loc.longitude > 180.0) {
        throw const FormatException("Longitude must be between -180.0 and 180.0");
      }
    }

    ReferenceFrameValidator.validateTemporalValidity(location.timestamp, location.validUntil);

    _locations.add(location);
  }

  void clearLocations() {
    _locations.clear();
  }
}
