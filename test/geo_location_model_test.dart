import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/models/geo_location.dart';

void main() {
  group('GeodeticSystem Tests', () {
    test('toJson includes all fields when present', () {
      final gs = GeodeticSystem(
        geodeticDatum: 'wgs-84',
        coordAccuracy: 0.001,
        heightAccuracy: 0.01,
      );
      final json = gs.toJson();
      expect(json['geodetic-datum'], 'wgs-84');
      expect(json['coord-accuracy'], 0.001);
      expect(json['height-accuracy'], 0.01);
    });

    test('toJson omits null optional fields', () {
      final gs = GeodeticSystem(geodeticDatum: 'wgs-84');
      final json = gs.toJson();
      expect(json.containsKey('coord-accuracy'), isFalse);
      expect(json.containsKey('height-accuracy'), isFalse);
    });

    test('fromJson parses all fields', () {
      final gs = GeodeticSystem.fromJson({
        'geodetic-datum': 'nad-83',
        'coord-accuracy': 0.5,
        'height-accuracy': 1.0,
      });
      expect(gs.geodeticDatum, 'nad-83');
      expect(gs.coordAccuracy, 0.5);
      expect(gs.heightAccuracy, 1.0);
    });

    test('fromJson defaults to wgs-84 when datum missing', () {
      final gs = GeodeticSystem.fromJson({});
      expect(gs.geodeticDatum, 'wgs-84');
      expect(gs.coordAccuracy, isNull);
      expect(gs.heightAccuracy, isNull);
    });

    test('roundtrip serialization', () {
      final original = GeodeticSystem(
        geodeticDatum: 'itrf-2014',
        coordAccuracy: 0.0001,
        heightAccuracy: 0.005,
      );
      final restored = GeodeticSystem.fromJson(original.toJson());
      expect(restored.geodeticDatum, original.geodeticDatum);
      expect(restored.coordAccuracy, original.coordAccuracy);
      expect(restored.heightAccuracy, original.heightAccuracy);
    });
  });

  group('ReferenceFrame Tests', () {
    test('toJson includes all fields', () {
      final rf = ReferenceFrame(
        astronomicalBody: 'earth',
        alternateSystem: 'ecef',
        geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
      );
      final json = rf.toJson();
      expect(json['astronomical-body'], 'earth');
      expect(json['alternate-system'], 'ecef');
      expect(json['geodetic-system'], isA<Map<String, dynamic>>());
    });

    test('toJson omits null alternateSystem', () {
      final rf = ReferenceFrame(
        astronomicalBody: 'mars',
        geodeticSystem: GeodeticSystem(geodeticDatum: 'areocentric'),
      );
      final json = rf.toJson();
      expect(json.containsKey('alternate-system'), isFalse);
    });

    test('fromJson parses all fields', () {
      final rf = ReferenceFrame.fromJson({
        'astronomical-body': 'mars',
        'alternate-system': 'iau-2015',
        'geodetic-system': {'geodetic-datum': 'areocentric-2015'},
      });
      expect(rf.astronomicalBody, 'mars');
      expect(rf.alternateSystem, 'iau-2015');
      expect(rf.geodeticSystem.geodeticDatum, 'areocentric-2015');
    });

    test('fromJson defaults when fields missing', () {
      final rf = ReferenceFrame.fromJson({});
      expect(rf.astronomicalBody, 'earth');
      expect(rf.alternateSystem, isNull);
      expect(rf.geodeticSystem.geodeticDatum, 'wgs-84');
    });

    test('roundtrip serialization', () {
      final original = ReferenceFrame(
        astronomicalBody: 'earth',
        alternateSystem: 'ecef',
        geodeticSystem: GeodeticSystem(
          geodeticDatum: 'wgs-84',
          coordAccuracy: 0.01,
        ),
      );
      final restored = ReferenceFrame.fromJson(original.toJson());
      expect(restored.astronomicalBody, original.astronomicalBody);
      expect(restored.alternateSystem, original.alternateSystem);
      expect(restored.geodeticSystem.geodeticDatum,
          original.geodeticSystem.geodeticDatum);
    });
  });

  group('EllipsoidCoordinate Tests', () {
    test('toJson includes all fields when present', () {
      final ec = EllipsoidCoordinate(
        latitude: 37.7749,
        longitude: -122.4194,
        height: 10.0,
      );
      final json = ec.toJson();
      expect(json['latitude'], 37.7749);
      expect(json['longitude'], -122.4194);
      expect(json['height'], 10.0);
    });

    test('toJson omits null height', () {
      final ec = EllipsoidCoordinate(latitude: 0.0, longitude: 0.0);
      final json = ec.toJson();
      expect(json.containsKey('height'), isFalse);
    });

    test('fromJson parses all fields', () {
      final ec = EllipsoidCoordinate.fromJson({
        'latitude': -22.3792,
        'longitude': 136.2751,
        'height': 150.0,
      });
      expect(ec.latitude, -22.3792);
      expect(ec.longitude, 136.2751);
      expect(ec.height, 150.0);
    });

    test('fromJson with null height', () {
      final ec = EllipsoidCoordinate.fromJson({
        'latitude': 45.0,
        'longitude': 90.0,
      });
      expect(ec.height, isNull);
    });

    test('roundtrip serialization', () {
      final original = EllipsoidCoordinate(
        latitude: -33.8688,
        longitude: 151.2093,
        height: 58.0,
      );
      final restored = EllipsoidCoordinate.fromJson(original.toJson());
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.height, original.height);
    });
  });

  group('CartesianCoordinate Tests', () {
    test('toJson includes all fields', () {
      final cc = CartesianCoordinate(x: 1.0, y: 2.0, z: 3.0);
      final json = cc.toJson();
      expect(json['x'], 1.0);
      expect(json['y'], 2.0);
      expect(json['z'], 3.0);
    });

    test('fromJson parses all fields', () {
      final cc = CartesianCoordinate.fromJson({'x': -5.5, 'y': 10.0, 'z': 0.0});
      expect(cc.x, -5.5);
      expect(cc.y, 10.0);
      expect(cc.z, 0.0);
    });

    test('roundtrip serialization', () {
      final original = CartesianCoordinate(x: 100.5, y: -200.3, z: 300.1);
      final restored = CartesianCoordinate.fromJson(original.toJson());
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.z, original.z);
    });
  });

  group('Velocity Tests', () {
    test('toJson includes all non-null fields', () {
      final v = Velocity(vNorth: 7500.0, vEast: 500.0, vUp: 0.0);
      final json = v.toJson();
      expect(json['v-north'], 7500.0);
      expect(json['v-east'], 500.0);
      expect(json['v-up'], 0.0);
    });

    test('toJson omits null fields', () {
      final v = Velocity(vNorth: 1.0);
      final json = v.toJson();
      expect(json.containsKey('v-north'), isTrue);
      expect(json.containsKey('v-east'), isFalse);
      expect(json.containsKey('v-up'), isFalse);
    });

    test('fromJson parses all fields', () {
      final v = Velocity.fromJson({
        'v-north': -12000.0,
        'v-east': 8500.0,
        'v-up': -150.0,
      });
      expect(v.vNorth, -12000.0);
      expect(v.vEast, 8500.0);
      expect(v.vUp, -150.0);
    });

    test('fromJson with missing fields returns null values', () {
      final v = Velocity.fromJson({});
      expect(v.vNorth, isNull);
      expect(v.vEast, isNull);
      expect(v.vUp, isNull);
    });

    test('isEmpty returns true when all null', () {
      final v = Velocity();
      expect(v.isEmpty, isTrue);
    });

    test('isEmpty returns false when any value is set', () {
      expect(Velocity(vNorth: 1.0).isEmpty, isFalse);
      expect(Velocity(vEast: 0.0).isEmpty, isFalse);
      expect(Velocity(vUp: -1.0).isEmpty, isFalse);
    });

    test('roundtrip serialization', () {
      final original = Velocity(vNorth: 100.0, vEast: 200.0, vUp: 50.0);
      final restored = Velocity.fromJson(original.toJson());
      expect(restored.vNorth, original.vNorth);
      expect(restored.vEast, original.vEast);
      expect(restored.vUp, original.vUp);
    });
  });

  group('GeoLocation Tests', () {
    test('toJson with ellipsoid coordinate (flat JSON per RFC 7951)', () {
      final loc = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        networkDomain: 'Terrestrial Fiber',
        location: EllipsoidCoordinate(
          latitude: 37.7749,
          longitude: -122.4194,
          height: 10.0,
        ),
        timestamp: DateTime.utc(2026, 6, 1, 12, 0, 0),
        validUntil: DateTime.utc(2026, 7, 1, 12, 0, 0),
      );
      final json = loc.toJson();
      expect(json['reference-frame'], isA<Map>());
      expect(json['network-domain'], 'Terrestrial Fiber');
      expect(json['latitude'], 37.7749);
      expect(json['longitude'], -122.4194);
      expect(json['height'], 10.0);
      expect(json['timestamp'], '2026-06-01T12:00:00.000Z');
      expect(json['valid-until'], '2026-07-01T12:00:00.000Z');
    });

    test('toJson with cartesian coordinate', () {
      final loc = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          alternateSystem: 'ecef',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        location: CartesianCoordinate(x: 1.0, y: 2.0, z: 3.0),
      );
      final json = loc.toJson();
      expect(json['x'], 1.0);
      expect(json['y'], 2.0);
      expect(json['z'], 3.0);
    });

    test('toJson omits empty velocity', () {
      final loc = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        velocity: Velocity(),
      );
      final json = loc.toJson();
      expect(json.containsKey('velocity'), isFalse);
    });

    test('toJson includes non-empty velocity', () {
      final loc = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
        velocity: Velocity(vNorth: 100.0),
      );
      final json = loc.toJson();
      expect(json.containsKey('velocity'), isTrue);
    });

    test('toJson omits null optional fields', () {
      final loc = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          geodeticSystem: GeodeticSystem(geodeticDatum: 'wgs-84'),
        ),
      );
      final json = loc.toJson();
      expect(json.containsKey('network-domain'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
      expect(json.containsKey('valid-until'), isFalse);
    });

    test('fromJson with ellipsoid coordinate', () {
      final loc = GeoLocation.fromJson({
        'reference-frame': {
          'astronomical-body': 'earth',
          'geodetic-system': {'geodetic-datum': 'wgs-84'},
        },
        'network-domain': 'Fiber',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'height': 10.0,
        'timestamp': '2026-06-01T12:00:00.000Z',
        'valid-until': '2026-07-01T12:00:00.000Z',
      });
      expect(loc.referenceFrame.astronomicalBody, 'earth');
      expect(loc.networkDomain, 'Fiber');
      expect(loc.location, isA<EllipsoidCoordinate>());
      final coord = loc.location as EllipsoidCoordinate;
      expect(coord.latitude, 37.7749);
      expect(coord.longitude, -122.4194);
      expect(coord.height, 10.0);
      expect(loc.timestamp, isNotNull);
      expect(loc.validUntil, isNotNull);
    });

    test('fromJson with cartesian coordinate', () {
      final loc = GeoLocation.fromJson({
        'reference-frame': {
          'astronomical-body': 'earth',
          'geodetic-system': {'geodetic-datum': 'wgs-84'},
        },
        'x': 1.0,
        'y': 2.0,
        'z': 3.0,
      });
      expect(loc.location, isA<CartesianCoordinate>());
      final coord = loc.location as CartesianCoordinate;
      expect(coord.x, 1.0);
      expect(coord.y, 2.0);
      expect(coord.z, 3.0);
    });

    test('fromJson with no coordinate data', () {
      final loc = GeoLocation.fromJson({
        'reference-frame': {
          'astronomical-body': 'earth',
          'geodetic-system': {'geodetic-datum': 'wgs-84'},
        },
      });
      expect(loc.location, isNull);
    });

    test('fromJson with velocity', () {
      final loc = GeoLocation.fromJson({
        'reference-frame': {
          'astronomical-body': 'earth',
          'geodetic-system': {'geodetic-datum': 'wgs-84'},
        },
        'velocity': {'v-north': 100.0, 'v-east': 200.0},
      });
      expect(loc.velocity, isNotNull);
      expect(loc.velocity!.vNorth, 100.0);
      expect(loc.velocity!.vEast, 200.0);
    });

    test('fromJson with no velocity', () {
      final loc = GeoLocation.fromJson({
        'reference-frame': {
          'astronomical-body': 'earth',
          'geodetic-system': {'geodetic-datum': 'wgs-84'},
        },
      });
      expect(loc.velocity, isNull);
    });

    test('fromJson defaults when reference-frame is missing', () {
      final loc = GeoLocation.fromJson({});
      expect(loc.referenceFrame.astronomicalBody, 'earth');
      expect(loc.referenceFrame.geodeticSystem.geodeticDatum, 'wgs-84');
    });

    test('roundtrip serialization with ellipsoid coordinate', () {
      final original = GeoLocation(
        referenceFrame: ReferenceFrame(
          astronomicalBody: 'earth',
          alternateSystem: 'test',
          geodeticSystem: GeodeticSystem(
            geodeticDatum: 'wgs-84',
            coordAccuracy: 0.001,
            heightAccuracy: 0.01,
          ),
        ),
        networkDomain: 'Fiber',
        location: EllipsoidCoordinate(
          latitude: 37.7749,
          longitude: -122.4194,
          height: 10.0,
        ),
        velocity: Velocity(vNorth: 100.0, vEast: 200.0, vUp: 50.0),
        timestamp: DateTime.utc(2026, 6, 1, 12, 0, 0),
        validUntil: DateTime.utc(2026, 7, 1, 12, 0, 0),
      );
      final restored = GeoLocation.fromJson(original.toJson());
      expect(restored.referenceFrame.astronomicalBody,
          original.referenceFrame.astronomicalBody);
      expect(restored.networkDomain, original.networkDomain);
      expect(restored.location, isA<EllipsoidCoordinate>());
      final origCoord = original.location as EllipsoidCoordinate;
      final restCoord = restored.location as EllipsoidCoordinate;
      expect(restCoord.latitude, origCoord.latitude);
      expect(restCoord.longitude, origCoord.longitude);
      expect(restCoord.height, origCoord.height);
      expect(restored.velocity!.vNorth, original.velocity!.vNorth);
    });
  });

  group('ReferenceFrameValidator Additional Tests', () {
    test('validateAstronomicalBody accepts empty string', () {
      expect(
          () => ReferenceFrameValidator.validateAstronomicalBody(''),
          returnsNormally);
    });

    test('validateGeodeticDatum accepts valid ASCII', () {
      expect(
          () => ReferenceFrameValidator.validateGeodeticDatum('wgs-84'),
          returnsNormally);
    });

    test('validateGeodeticDatum rejects non-ASCII', () {
      expect(
        () => ReferenceFrameValidator.validateGeodeticDatum('datum\u0001'),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseCartesianCoordinate valid values', () {
      expect(ReferenceFrameValidator.parseCartesianCoordinate('100.5', 'X'),
          100.5);
      expect(ReferenceFrameValidator.parseCartesianCoordinate('-200', 'Y'),
          -200.0);
    });

    test('parseCartesianCoordinate rejects empty value', () {
      expect(
        () => ReferenceFrameValidator.parseCartesianCoordinate('', 'X'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('required'))),
      );
    });

    test('parseCartesianCoordinate rejects too many decimal places', () {
      expect(
        () => ReferenceFrameValidator.parseCartesianCoordinate(
            '1.1234567', 'X'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('precision'))),
      );
    });

    test('parseVelocityComponent valid values', () {
      expect(ReferenceFrameValidator.parseVelocityComponent('100.5', 'vNorth'),
          100.5);
    });

    test('parseVelocityComponent returns null for empty', () {
      expect(
          ReferenceFrameValidator.parseVelocityComponent('', 'vNorth'), isNull);
    });

    test('parseVelocityComponent rejects non-number', () {
      expect(
        () => ReferenceFrameValidator.parseVelocityComponent('abc', 'vNorth'),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseVelocityComponent rejects too many decimal places', () {
      expect(
        () => ReferenceFrameValidator.parseVelocityComponent(
            '1.1234567890123', 'vNorth'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('precision'))),
      );
    });

    test('validateTemporalValidity accepts valid range', () {
      expect(
        () => ReferenceFrameValidator.validateTemporalValidity(
          DateTime(2026, 1, 1),
          DateTime(2026, 6, 1),
        ),
        returnsNormally,
      );
    });

    test('validateTemporalValidity rejects equal timestamps', () {
      final dt = DateTime(2026, 1, 1);
      expect(
        () => ReferenceFrameValidator.validateTemporalValidity(dt, dt),
        throwsA(isA<FormatException>()),
      );
    });

    test('validateTemporalValidity rejects validUntil before timestamp', () {
      expect(
        () => ReferenceFrameValidator.validateTemporalValidity(
          DateTime(2026, 6, 1),
          DateTime(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('validateTemporalValidity accepts null values', () {
      expect(
          () => ReferenceFrameValidator.validateTemporalValidity(null, null),
          returnsNormally);
      expect(
        () => ReferenceFrameValidator.validateTemporalValidity(
            DateTime(2026, 1, 1), null),
        returnsNormally,
      );
    });

    test('parseDateTime valid UTC string', () {
      final dt =
          ReferenceFrameValidator.parseDateTime('2026-06-01T12:00:00Z', 'ts');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
    });

    test('parseDateTime returns null for empty', () {
      expect(
          ReferenceFrameValidator.parseDateTime('', 'ts'), isNull);
    });

    test('parseDateTime rejects non-UTC string', () {
      expect(
        () => ReferenceFrameValidator.parseDateTime(
            '2026-06-01T12:00:00', 'ts'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('UTC'))),
      );
    });

    test('parseDateTime rejects invalid format', () {
      expect(
        () => ReferenceFrameValidator.parseDateTime('not-a-date+00:00', 'ts'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
