import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/models/geo_location.dart';

void main() {
  group('Reference Frame Validation Logic Tests', () {
    test('Default Astronomical Body and Geodetic Datum Normalization', () {
      expect(ReferenceFrameValidator.normalize('Earth '), 'earth');
      expect(ReferenceFrameValidator.normalize('WGS 84'), 'wgs-84');
      expect(ReferenceFrameValidator.normalize('   MARS   '), 'mars');
    });

    test('ASCII String Pattern Validation', () {
      expect(ReferenceFrameValidator.isValidStringPattern('earth-123'), true);
      expect(ReferenceFrameValidator.isValidStringPattern('earth_system'), true);
      expect(ReferenceFrameValidator.isValidStringPattern('earth😀'), false); // Emoji is outside ASCII 32-126
      expect(ReferenceFrameValidator.isValidStringPattern('earth\u0001'), false); // Control character is outside

      // Alternate System validation
      expect(() => ReferenceFrameValidator.validateAlternateSystem('ecef-system'), returnsNormally);
      expect(
        () => ReferenceFrameValidator.validateAlternateSystem('System😀'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('Only standard ASCII without control chars allowed'))),
      );
    });

    test('Coordinate/Height Accuracy Decimal Precision & Bounds Validation', () {
      // Valid precision (<= 6 decimals)
      expect(ReferenceFrameValidator.parseAccuracy('0.123456'), 0.123456);
      expect(ReferenceFrameValidator.parseAccuracy('1'), 1.0);
      expect(ReferenceFrameValidator.parseAccuracy('1.0'), 1.0);
      
      // Invalid precision (7 decimal places)
      expect(
        () => ReferenceFrameValidator.parseAccuracy('0.1234567'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('cannot exceed 6 decimal places'))),
      );
      
      // Negative value
      expect(
        () => ReferenceFrameValidator.parseAccuracy('-0.5'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('non-negative'))),
      );

      // Non-number format
      expect(
        () => ReferenceFrameValidator.parseAccuracy('abc'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('valid decimal number'))),
      );
    });

    test('Latitude Precision & Bounds Validation', () {
      expect(ReferenceFrameValidator.parseLatitude('45.12345678901234'), 45.12345678901234);
      expect(ReferenceFrameValidator.parseLatitude('-90.0'), -90.0);
      expect(ReferenceFrameValidator.parseLatitude('90.0'), 90.0);

      // Over bounds
      expect(
        () => ReferenceFrameValidator.parseLatitude('90.000001'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('must be between -90.0 and 90.0'))),
      );
      expect(
        () => ReferenceFrameValidator.parseLatitude('-91'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('must be between -90.0 and 90.0'))),
      );

      // Too many decimals (> 16 decimals)
      expect(
        () => ReferenceFrameValidator.parseLatitude('0.12345678901234567'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('cannot exceed 16 decimal places'))),
      );
    });

    test('Longitude Precision & Bounds Validation', () {
      expect(ReferenceFrameValidator.parseLongitude('135.12345678901234'), 135.12345678901234);
      expect(ReferenceFrameValidator.parseLongitude('-180.0'), -180.0);
      expect(ReferenceFrameValidator.parseLongitude('180.0'), 180.0);

      // Over bounds
      expect(
        () => ReferenceFrameValidator.parseLongitude('180.000001'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('must be between -180.0 and 180.0'))),
      );
      expect(
        () => ReferenceFrameValidator.parseLongitude('-181'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('must be between -180.0 and 180.0'))),
      );

      // Too many decimals (> 16 decimals)
      expect(
        () => ReferenceFrameValidator.parseLongitude('0.12345678901234567'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('cannot exceed 16 decimal places'))),
      );
    });

    test('Height Precision Validation', () {
      expect(ReferenceFrameValidator.parseHeight('120.123456'), 120.123456);
      expect(ReferenceFrameValidator.parseHeight('-10.5'), -10.5);

      // Too many decimals (> 6 decimals)
      expect(
        () => ReferenceFrameValidator.parseHeight('0.1234567'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('cannot exceed 6 decimal places'))),
      );
    });

    test('GeoLocation Serialization and Deserialization (RFC 7951 Flat JSON)', () {
      final location = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          alternateSystem: 'test-system',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.05,
            heightAccuracy: 0.1,
          ),
        ),
        networkDomain: 'Terrestrial Fiber (L0-L4)',
        location: EllipsoidCoordinate(
          latitude: 37.7749,
          longitude: -122.4194,
          height: 12.3,
        ),
      );

      final jsonMap = location.toJson();

      // Verify that coordinates are flattened directly into GeoLocation container (sibling to reference-frame)
      expect(jsonMap['reference-frame'], isNotNull);
      final refFrameMap = jsonMap['reference-frame'] as Map<String, dynamic>;
      
      expect(refFrameMap['astronomical-body'], 'earth');
      expect(jsonMap['latitude'], 37.7749);
      expect(jsonMap['longitude'], -122.4194);
      expect(jsonMap['height'], 12.3);

      // Re-parse
      final parsed = GeoLocation.fromJson(jsonMap);
      expect(parsed.location, isA<EllipsoidCoordinate>());
      final parsedCoord = parsed.location as EllipsoidCoordinate;
      expect(parsedCoord.latitude, 37.7749);
      expect(parsedCoord.longitude, -122.4194);
      expect(parsedCoord.height, 12.3);
    });

    test('Cartesian Coordinate Precision & Validation', () {
      expect(ReferenceFrameValidator.parseCartesianCoordinate('6378137.123456', 'X'), 6378137.123456);
      expect(ReferenceFrameValidator.parseCartesianCoordinate('-123.45', 'Y'), -123.45);
      
      // Empty value
      expect(
        () => ReferenceFrameValidator.parseCartesianCoordinate('', 'Z'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('Z coordinate is required in Cartesian mode'))),
      );

      // Too many decimals (> 6 decimals)
      expect(
        () => ReferenceFrameValidator.parseCartesianCoordinate('0.1234567', 'X'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('X coordinate precision cannot exceed 6 decimal places'))),
      );

      // Non-number format
      expect(
        () => ReferenceFrameValidator.parseCartesianCoordinate('xyz', 'Y'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('valid decimal number'))),
      );
    });

    test('GeoLocation Serialization and Deserialization with Cartesian Coordinate (RFC 7951 Flat JSON)', () {
      final location = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          alternateSystem: 'test-system',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.05,
            heightAccuracy: 0.1,
          ),
        ),
        networkDomain: 'Terrestrial Fiber (L0-L4)',
        location: CartesianCoordinate(
          x: 6378137.123456,
          y: 0.0,
          z: 0.0,
        ),
      );

      final jsonMap = location.toJson();

      // Verify that coordinates are flattened directly into GeoLocation container
      expect(jsonMap['reference-frame'], isNotNull);
      expect(jsonMap['x'], 6378137.123456);
      expect(jsonMap['y'], 0.0);
      expect(jsonMap['z'], 0.0);

      // Re-parse
      final parsed = GeoLocation.fromJson(jsonMap);
      expect(parsed.location, isA<CartesianCoordinate>());
      final parsedCoord = parsed.location as CartesianCoordinate;
      expect(parsedCoord.x, 6378137.123456);
      expect(parsedCoord.y, 0.0);
      expect(parsedCoord.z, 0.0);
    });

    test('Velocity Component Parsing and Validation', () {
      expect(ReferenceFrameValidator.parseVelocityComponent('12.123456789012', 'v-north'), 12.123456789012);
      expect(ReferenceFrameValidator.parseVelocityComponent('-5.5', 'v-east'), -5.5);
      expect(ReferenceFrameValidator.parseVelocityComponent('0.0', 'v-up'), 0.0);

      // Too many decimals (> 12 decimals)
      expect(
        () => ReferenceFrameValidator.parseVelocityComponent('0.1234567890123', 'v-north'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('cannot exceed 12 decimal places'))),
      );

      // Non-number format
      expect(
        () => ReferenceFrameValidator.parseVelocityComponent('abc', 'v-east'),
        throwsA(predicate((e) => e is FormatException && e.message.contains('valid decimal number'))),
      );
    });

    test('GeoLocation Serialization and Deserialization with Velocity (RFC 7951 JSON)', () {
      final location = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
          ),
        ),
        networkDomain: 'Terrestrial Fiber (L0-L4)',
        location: EllipsoidCoordinate(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        velocity: Velocity(
          vNorth: 12.345678901234, // gets clamped/parsed
          vEast: -1.2,
          vUp: 0.1,
        ),
      );

      final jsonMap = location.toJson();

      // Verify nested structure
      expect(jsonMap['velocity'], isNotNull);
      final velocityMap = jsonMap['velocity'] as Map<String, dynamic>;
      expect(velocityMap['v-north'], 12.345678901234);
      expect(velocityMap['v-east'], -1.2);
      expect(velocityMap['v-up'], 0.1);

      // Re-parse
      final parsed = GeoLocation.fromJson(jsonMap);
      expect(parsed.velocity, isNotNull);
      expect(parsed.velocity!.vNorth, 12.345678901234);
      expect(parsed.velocity!.vEast, -1.2);
      expect(parsed.velocity!.vUp, 0.1);
    });
  });
}
