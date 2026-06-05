import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:cogctl_ux/core/utils/format_error.dart';
import 'package:cogctl_ux/features/geo_location/domain/geo_location.dart';
import 'package:cogctl_ux/features/geo_location/domain/repositories/i_location_repository.dart';
import 'geo_location_state.dart';

class GeoLocationCubit extends Cubit<GeoLocationState> {
  final ILocationRepository _repository;

  GeoLocationCubit(this._repository)
      : super(const GeoLocationState(records: [])) {
    loadRecords();
  }

  void loadRecords() {
    try {
      final records = _repository.getLocations();
      emit(state.copyWith(
        records: List.of(records),
        status: GeoLocationStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GeoLocationStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void setCoordinateMode(String mode) {
    emit(state.copyWith(coordinateMode: mode));
    _clearErrors();
  }

  void setAlternateSystemsEnabled(bool enabled) {
    emit(state.copyWith(alternateSystemsEnabled: enabled));
  }

  void setSelectedNetworkDomain(String domain) {
    emit(state.copyWith(selectedNetworkDomain: domain));
  }

  void updateComputedVelocity({String? vNorthRaw, String? vEastRaw, String? vUpRaw}) {
    double? vNorth;
    double? vEast;

    try {
      if (vNorthRaw != null && vNorthRaw.trim().isNotEmpty) {
        vNorth = ReferenceFrameValidator.parseVelocityComponent(vNorthRaw, 'v-north');
      }
      if (vEastRaw != null && vEastRaw.trim().isNotEmpty) {
        vEast = ReferenceFrameValidator.parseVelocityComponent(vEastRaw, 'v-east');
      }

      if (vNorth != null && vEast != null) {
        final speed = sqrt(vNorth * vNorth + vEast * vEast);
        double heading = atan2(vEast, vNorth) * (180.0 / pi);
        if (heading < 0) {
          heading += 360.0;
        }
        emit(state.copyWith(
          computedSpeed: () => speed,
          computedHeading: () => heading,
        ));
      } else {
        emit(state.copyWith(
          computedSpeed: () => null,
          computedHeading: () => null,
        ));
      }
    } on FormatException {
      emit(state.copyWith(
        computedSpeed: () => null,
        computedHeading: () => null,
      ));
    }
  }

  void validateField(String field, String value) {
    final trimmed = value.trim();
    switch (field) {
      case 'body':
        if (trimmed.isEmpty) {
          emit(state.copyWith(bodyError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.validateAstronomicalBody(ReferenceFrameValidator.normalize(trimmed));
          emit(state.copyWith(bodyError: () => null));
        } catch (e) {
          emit(state.copyWith(bodyError: () => formatError(e)));
        }
        break;
      case 'altSystem':
        if (trimmed.isEmpty) {
          emit(state.copyWith(altSystemError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.validateAlternateSystem(ReferenceFrameValidator.normalize(trimmed));
          emit(state.copyWith(altSystemError: () => null));
        } catch (e) {
          emit(state.copyWith(altSystemError: () => formatError(e)));
        }
        break;
      case 'datum':
        if (trimmed.isEmpty) {
          emit(state.copyWith(datumError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.validateGeodeticDatum(ReferenceFrameValidator.normalize(trimmed));
          emit(state.copyWith(datumError: () => null));
        } catch (e) {
          emit(state.copyWith(datumError: () => formatError(e)));
        }
        break;
      case 'coordAcc':
        if (trimmed.isEmpty) {
          emit(state.copyWith(coordAccError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseAccuracy(trimmed);
          emit(state.copyWith(coordAccError: () => null));
        } catch (e) {
          emit(state.copyWith(coordAccError: () => formatError(e)));
        }
        break;
      case 'heightAcc':
        if (trimmed.isEmpty) {
          emit(state.copyWith(heightAccError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseAccuracy(trimmed);
          emit(state.copyWith(heightAccError: () => null));
        } catch (e) {
          emit(state.copyWith(heightAccError: () => formatError(e)));
        }
        break;
      case 'lat':
        if (trimmed.isEmpty) {
          emit(state.copyWith(latError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseLatitude(trimmed);
          emit(state.copyWith(latError: () => null));
        } catch (e) {
          emit(state.copyWith(latError: () => formatError(e)));
        }
        break;
      case 'lon':
        if (trimmed.isEmpty) {
          emit(state.copyWith(lonError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseLongitude(trimmed);
          emit(state.copyWith(lonError: () => null));
        } catch (e) {
          emit(state.copyWith(lonError: () => formatError(e)));
        }
        break;
      case 'height':
        if (trimmed.isEmpty) {
          emit(state.copyWith(heightError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseHeight(trimmed);
          emit(state.copyWith(heightError: () => null));
        } catch (e) {
          emit(state.copyWith(heightError: () => formatError(e)));
        }
        break;
      case 'x':
        if (trimmed.isEmpty) {
          emit(state.copyWith(xError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseCartesianCoordinate(trimmed, 'X');
          emit(state.copyWith(xError: () => null));
        } catch (e) {
          emit(state.copyWith(xError: () => formatError(e)));
        }
        break;
      case 'y':
        if (trimmed.isEmpty) {
          emit(state.copyWith(yError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseCartesianCoordinate(trimmed, 'Y');
          emit(state.copyWith(yError: () => null));
        } catch (e) {
          emit(state.copyWith(yError: () => formatError(e)));
        }
        break;
      case 'z':
        if (trimmed.isEmpty) {
          emit(state.copyWith(zError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseCartesianCoordinate(trimmed, 'Z');
          emit(state.copyWith(zError: () => null));
        } catch (e) {
          emit(state.copyWith(zError: () => formatError(e)));
        }
        break;
      case 'vNorth':
        if (trimmed.isEmpty) {
          emit(state.copyWith(vNorthError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseVelocityComponent(trimmed, 'v-north');
          emit(state.copyWith(vNorthError: () => null));
        } catch (e) {
          emit(state.copyWith(vNorthError: () => formatError(e)));
        }
        break;
      case 'vEast':
        if (trimmed.isEmpty) {
          emit(state.copyWith(vEastError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseVelocityComponent(trimmed, 'v-east');
          emit(state.copyWith(vEastError: () => null));
        } catch (e) {
          emit(state.copyWith(vEastError: () => formatError(e)));
        }
        break;
      case 'vUp':
        if (trimmed.isEmpty) {
          emit(state.copyWith(vUpError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseVelocityComponent(trimmed, 'v-up');
          emit(state.copyWith(vUpError: () => null));
        } catch (e) {
          emit(state.copyWith(vUpError: () => formatError(e)));
        }
        break;
      case 'timestamp':
        if (trimmed.isEmpty) {
          emit(state.copyWith(timestampError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseDateTime(trimmed, 'timestamp');
          emit(state.copyWith(timestampError: () => null));
        } catch (e) {
          emit(state.copyWith(timestampError: () => formatError(e)));
        }
        break;
      case 'validUntil':
        if (trimmed.isEmpty) {
          emit(state.copyWith(validUntilError: () => null));
          break;
        }
        try {
          ReferenceFrameValidator.parseDateTime(trimmed, 'valid-until');
          emit(state.copyWith(validUntilError: () => null));
        } catch (e) {
          emit(state.copyWith(validUntilError: () => formatError(e)));
        }
        break;
    }
  }

  void addRecord({
    required String rawBody,
    required String rawDatum,
    required String rawAlt,
    required String rawCoord,
    required String rawHeightAcc,
    required String rawLat,
    required String rawLon,
    required String rawHeightVal,
    required String rawX,
    required String rawY,
    required String rawZ,
    required String rawVNorth,
    required String rawVEast,
    required String rawVUp,
    required String rawTimestamp,
    required String rawValidUntil,
  }) {
    emit(state.copyWith(generalError: () => null));
    try {
      String astronomicalBody = rawBody.isEmpty ? 'earth' : ReferenceFrameValidator.normalize(rawBody);
      String geodeticDatum = rawDatum.isEmpty ? 'wgs-84' : ReferenceFrameValidator.normalize(rawDatum);

      ReferenceFrameValidator.validateAstronomicalBody(astronomicalBody);

      String? alternateSystem;
      if (state.alternateSystemsEnabled) {
        alternateSystem = rawAlt.isEmpty ? 'wgs-84' : ReferenceFrameValidator.normalize(rawAlt);
        ReferenceFrameValidator.validateAlternateSystem(alternateSystem);
      }

      ReferenceFrameValidator.validateGeodeticDatum(geodeticDatum);

      double? coordAccuracy;
      if (rawCoord.trim().isNotEmpty) {
        coordAccuracy = ReferenceFrameValidator.parseAccuracy(rawCoord);
      }

      double? heightAccuracy;
      if (rawHeightAcc.trim().isNotEmpty) {
        heightAccuracy = ReferenceFrameValidator.parseAccuracy(rawHeightAcc);
      }

      final geodeticSystem = GeodeticSystem(
        geodeticDatum: geodeticDatum,
        coordAccuracy: coordAccuracy,
        heightAccuracy: heightAccuracy,
      );

      LocationCoordinate? location;
      if (state.coordinateMode == 'Ellipsoidal') {
        final double latitude = ReferenceFrameValidator.parseLatitude(rawLat);
        final double longitude = ReferenceFrameValidator.parseLongitude(rawLon);
        final double? height = rawHeightVal.trim().isNotEmpty
            ? ReferenceFrameValidator.parseHeight(rawHeightVal)
            : null;

        location = EllipsoidCoordinate(
          latitude: latitude,
          longitude: longitude,
          height: height,
        );
      } else {
        final double xVal = ReferenceFrameValidator.parseCartesianCoordinate(rawX, 'X');
        final double yVal = ReferenceFrameValidator.parseCartesianCoordinate(rawY, 'Y');
        final double zVal = ReferenceFrameValidator.parseCartesianCoordinate(rawZ, 'Z');

        location = CartesianCoordinate(
          x: xVal,
          y: yVal,
          z: zVal,
        );
      }

      Velocity? velocity;
      if (rawVNorth.trim().isNotEmpty || rawVEast.trim().isNotEmpty || rawVUp.trim().isNotEmpty) {
        final double? vNorth = ReferenceFrameValidator.parseVelocityComponent(rawVNorth, 'v-north');
        final double? vEast = ReferenceFrameValidator.parseVelocityComponent(rawVEast, 'v-east');
        final double? vUp = rawVUp.trim().isNotEmpty
            ? ReferenceFrameValidator.parseVelocityComponent(rawVUp, 'v-up')
            : 0.0;

        velocity = Velocity(
          vNorth: vNorth,
          vEast: vEast,
          vUp: vUp,
        );
      }

      DateTime? timestampVal;
      if (rawTimestamp.trim().isNotEmpty) {
        timestampVal = ReferenceFrameValidator.parseDateTime(rawTimestamp, 'timestamp');
      }

      DateTime? validUntilVal;
      if (rawValidUntil.trim().isNotEmpty) {
        validUntilVal = ReferenceFrameValidator.parseDateTime(rawValidUntil, 'valid-until');
      }

      if (timestampVal != null && validUntilVal != null) {
        ReferenceFrameValidator.validateTemporalValidity(timestampVal, validUntilVal);
      }

      final frame = ReferenceFrame(
        astronomicalBody: astronomicalBody,
        alternateSystem: alternateSystem,
        geodeticSystem: geodeticSystem,
      );

      final newRecord = GeoLocation(
        networkDomain: state.selectedNetworkDomain,
        referenceFrame: frame,
        location: location,
        velocity: velocity,
        timestamp: timestampVal,
        validUntil: validUntilVal,
      );

      _repository.addLocation(newRecord);
      loadRecords();
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
    }
  }

  void clearRecords() {
    try {
      _repository.clearLocations();
      loadRecords();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }

  void _clearErrors() {
    emit(state.copyWith(
      generalError: () => null,
      bodyError: () => null,
      altSystemError: () => null,
      datumError: () => null,
      coordAccError: () => null,
      heightAccError: () => null,
      latError: () => null,
      lonError: () => null,
      heightError: () => null,
      xError: () => null,
      yError: () => null,
      zError: () => null,
      vNorthError: () => null,
      vEastError: () => null,
      vUpError: () => null,
      timestampError: () => null,
      validUntilError: () => null,
    ));
  }
}
