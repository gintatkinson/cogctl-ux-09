import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/geo_location/domain/geo_location.dart';

enum GeoLocationStatus { initial, success, failure }

class GeoLocationState extends Equatable {
  final List<GeoLocation> records;
  final String coordinateMode;
  final bool alternateSystemsEnabled;
  final String selectedNetworkDomain;
  final GeoLocationStatus status;
  final String? generalError;
  final String? bodyError;
  final String? altSystemError;
  final String? datumError;
  final String? coordAccError;
  final String? heightAccError;
  final String? latError;
  final String? lonError;
  final String? heightError;
  final String? xError;
  final String? yError;
  final String? zError;
  final String? vNorthError;
  final String? vEastError;
  final String? vUpError;
  final String? timestampError;
  final String? validUntilError;
  final double? computedSpeed;
  final double? computedHeading;

  const GeoLocationState({
    required this.records,
    this.coordinateMode = 'Ellipsoidal',
    this.alternateSystemsEnabled = true,
    this.selectedNetworkDomain = 'Terrestrial Fiber (L0-L4)',
    this.status = GeoLocationStatus.initial,
    this.generalError,
    this.bodyError,
    this.altSystemError,
    this.datumError,
    this.coordAccError,
    this.heightAccError,
    this.latError,
    this.lonError,
    this.heightError,
    this.xError,
    this.yError,
    this.zError,
    this.vNorthError,
    this.vEastError,
    this.vUpError,
    this.timestampError,
    this.validUntilError,
    this.computedSpeed,
    this.computedHeading,
  });

  @override
  List<Object?> get props => [
        records,
        coordinateMode,
        alternateSystemsEnabled,
        selectedNetworkDomain,
        status,
        generalError,
        bodyError,
        altSystemError,
        datumError,
        coordAccError,
        heightAccError,
        latError,
        lonError,
        heightError,
        xError,
        yError,
        zError,
        vNorthError,
        vEastError,
        vUpError,
        timestampError,
        validUntilError,
        computedSpeed,
        computedHeading,
      ];

  GeoLocationState copyWith({
    List<GeoLocation>? records,
    String? coordinateMode,
    bool? alternateSystemsEnabled,
    String? selectedNetworkDomain,
    GeoLocationStatus? status,
    String? Function()? generalError,
    String? Function()? bodyError,
    String? Function()? altSystemError,
    String? Function()? datumError,
    String? Function()? coordAccError,
    String? Function()? heightAccError,
    String? Function()? latError,
    String? Function()? lonError,
    String? Function()? heightError,
    String? Function()? xError,
    String? Function()? yError,
    String? Function()? zError,
    String? Function()? vNorthError,
    String? Function()? vEastError,
    String? Function()? vUpError,
    String? Function()? timestampError,
    String? Function()? validUntilError,
    double? Function()? computedSpeed,
    double? Function()? computedHeading,
  }) {
    return GeoLocationState(
      records: records ?? this.records,
      coordinateMode: coordinateMode ?? this.coordinateMode,
      alternateSystemsEnabled: alternateSystemsEnabled ?? this.alternateSystemsEnabled,
      selectedNetworkDomain: selectedNetworkDomain ?? this.selectedNetworkDomain,
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
      bodyError: bodyError != null ? bodyError() : this.bodyError,
      altSystemError: altSystemError != null ? altSystemError() : this.altSystemError,
      datumError: datumError != null ? datumError() : this.datumError,
      coordAccError: coordAccError != null ? coordAccError() : this.coordAccError,
      heightAccError: heightAccError != null ? heightAccError() : this.heightAccError,
      latError: latError != null ? latError() : this.latError,
      lonError: lonError != null ? lonError() : this.lonError,
      heightError: heightError != null ? heightError() : this.heightError,
      xError: xError != null ? xError() : this.xError,
      yError: yError != null ? yError() : this.yError,
      zError: zError != null ? zError() : this.zError,
      vNorthError: vNorthError != null ? vNorthError() : this.vNorthError,
      vEastError: vEastError != null ? vEastError() : this.vEastError,
      vUpError: vUpError != null ? vUpError() : this.vUpError,
      timestampError: timestampError != null ? timestampError() : this.timestampError,
      validUntilError: validUntilError != null ? validUntilError() : this.validUntilError,
      computedSpeed: computedSpeed != null ? computedSpeed() : this.computedSpeed,
      computedHeading: computedHeading != null ? computedHeading() : this.computedHeading,
    );
  }
}
