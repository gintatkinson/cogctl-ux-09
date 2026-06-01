import '../models/geo_location.dart';

class MockLocationService {
  static final MockLocationService _instance = MockLocationService._internal();
  factory MockLocationService() => _instance;

  final List<GeoLocation> _locations = [];

  MockLocationService._internal() {
    // Populate with default mock database records as required by the vertical slice
    _locations.addAll([
      GeoLocation(
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
