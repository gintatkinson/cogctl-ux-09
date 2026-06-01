import '../models/geo_location.dart';

class MockLocationService {
  static final MockLocationService _instance = MockLocationService._internal();
  factory MockLocationService() => _instance;

  final List<GeoLocation> _locations = [];

  MockLocationService._internal() {
    // Populate with SDN Multi-Domain Network Reference Frames
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

    _locations.add(location);
  }

  void clearLocations() {
    _locations.clear();
  }
}
