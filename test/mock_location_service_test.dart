import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/models/geo_location.dart';
import 'package:cogctl_ux/services/mock_location_service.dart';

void main() {
  // MockLocationService is a singleton; tests that read pre-populated state
  // must run before tests that mutate the internal list.

  group('MockLocationService Pre-populated State Tests', () {
    final service = MockLocationService();

    test('getLocations returns pre-populated list', () {
      final locations = service.getLocations();
      expect(locations, isNotEmpty);
      expect(locations.length, greaterThanOrEqualTo(5));
    });

    test('getLocations returns unmodifiable list', () {
      final locations = service.getLocations();
      expect(
        () => locations.add(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
          ),
        )),
        throwsUnsupportedError,
      );
    });

    test('pre-populated locations contain expected network domains', () {
      final locations = service.getLocations();
      final domains = locations
          .where((l) => l.networkDomain != null)
          .map((l) => l.networkDomain!)
          .toList();
      expect(domains, contains('Terrestrial Fiber (L0-L4)'));
      expect(domains, contains('Submarine Cable (Subsea)'));
      expect(domains, contains('Non-Terrestrial Network (NTN)'));
      expect(domains, contains('Deep Space Network (DSN)'));
      expect(domains, contains('Quantum Key Distribution (QKD)'));
    });

    test('pre-populated Mars location uses areocentric datum', () {
      final locations = service.getLocations();
      final marsLoc = locations.firstWhere(
        (l) => l.referenceFrame.astronomicalBody == 'mars',
      );
      expect(marsLoc.referenceFrame.geodeticSystem.geodeticDatum,
          'areocentric-2015');
      expect(marsLoc.referenceFrame.alternateSystem, 'iau-2015');
    });

    test('pre-populated NTN location has velocity data', () {
      final locations = service.getLocations();
      final ntnLoc = locations.firstWhere(
        (l) => l.networkDomain == 'Non-Terrestrial Network (NTN)',
      );
      expect(ntnLoc.velocity, isNotNull);
      expect(ntnLoc.velocity!.vNorth, 7500.0);
      expect(ntnLoc.velocity!.vEast, 500.0);
      expect(ntnLoc.velocity!.vUp, 0.0);
    });

    test('pre-populated locations have correct coordinate types', () {
      final locations = service.getLocations();
      for (final loc in locations) {
        if (loc.location != null) {
          expect(loc.location, isA<EllipsoidCoordinate>());
        }
      }
    });
  });

  group('MockLocationService addLocation Validation Tests', () {
    final service = MockLocationService();

    test('addLocation adds a valid ellipsoid location', () {
      final initialCount = service.getLocations().length;
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        networkDomain: 'Test Domain',
        location: EllipsoidCoordinate(
          latitude: 40.7128,
          longitude: -74.0060,
          height: 5.0,
        ),
        timestamp: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 1)),
      ));
      expect(service.getLocations().length, initialCount + 1);
    });

    test('addLocation adds a location with cartesian coordinates', () {
      final initialCount = service.getLocations().length;
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          alternateSystem: 'ecef',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        location: CartesianCoordinate(x: 1000.0, y: 2000.0, z: 3000.0),
        timestamp: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 1)),
      ));
      expect(service.getLocations().length, initialCount + 1);
    });

    test('addLocation adds a location with no coordinates', () {
      final initialCount = service.getLocations().length;
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        timestamp: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 1)),
      ));
      expect(service.getLocations().length, initialCount + 1);
    });

    test('addLocation rejects invalid astronomical body characters', () {
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth\u0001',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
          ),
        )),
        throwsA(isA<FormatException>()),
      );
    });

    test('addLocation rejects invalid geodetic datum characters', () {
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'datum\u0007'),
          ),
        )),
        throwsA(isA<FormatException>()),
      );
    });

    test('addLocation rejects negative coordinate accuracy', () {
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(
              geodeticDatum: 'wgs-84',
              coordAccuracy: -0.5,
            ),
          ),
        )),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message',
                contains('Coordinate accuracy must be non-negative'))),
      );
    });

    test('addLocation rejects negative height accuracy', () {
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(
              geodeticDatum: 'wgs-84',
              heightAccuracy: -1.0,
            ),
          ),
        )),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message',
                contains('Height accuracy must be non-negative'))),
      );
    });

    test('addLocation rejects latitude out of bounds', () {
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
          ),
          location: EllipsoidCoordinate(latitude: 91.0, longitude: 0.0),
        )),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message',
                contains('Latitude must be between -90.0 and 90.0'))),
      );
    });

    test('addLocation rejects longitude out of bounds', () {
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
          ),
          location: EllipsoidCoordinate(latitude: 0.0, longitude: 181.0),
        )),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message',
                contains('Longitude must be between -180.0 and 180.0'))),
      );
    });

    test('addLocation rejects validUntil before timestamp', () {
      final now = DateTime.now();
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
          ),
          timestamp: now,
          validUntil: now.subtract(const Duration(hours: 1)),
        )),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message',
                contains('valid-until must be chronologically after'))),
      );
    });

    test('addLocation rejects validUntil equal to timestamp', () {
      final now = DateTime.now();
      expect(
        () => service.addLocation(GeoLocation(
          referenceFrame: ReferenceFrame(
            astronomicalBody: 'earth',
            geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
          ),
          timestamp: now,
          validUntil: now,
        )),
        throwsA(isA<FormatException>()),
      );
    });

    test('addLocation accepts boundary latitude values', () {
      final initialCount = service.getLocations().length;
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        location: EllipsoidCoordinate(latitude: 90.0, longitude: 0.0),
      ));
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        location: EllipsoidCoordinate(latitude: -90.0, longitude: 0.0),
      ));
      expect(service.getLocations().length, initialCount + 2);
    });

    test('addLocation accepts boundary longitude values', () {
      final initialCount = service.getLocations().length;
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        location: EllipsoidCoordinate(latitude: 0.0, longitude: 180.0),
      ));
      service.addLocation(GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        location: EllipsoidCoordinate(latitude: 0.0, longitude: -180.0),
      ));
      expect(service.getLocations().length, initialCount + 2);
    });
  });

  group('MockLocationService clearLocations Tests', () {
    test('clearLocations empties the list', () {
      final service = MockLocationService();
      service.clearLocations();
      expect(service.getLocations(), isEmpty);
    });
  });
}
