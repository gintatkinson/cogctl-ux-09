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
  });
}
