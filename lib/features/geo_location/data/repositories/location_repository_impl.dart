import 'package:cogctl_ux/features/geo_location/data/mock_location_service.dart';
import 'package:cogctl_ux/features/geo_location/domain/geo_location.dart';
import 'package:cogctl_ux/features/geo_location/domain/repositories/i_location_repository.dart';

class LocationRepositoryImpl implements ILocationRepository {
  final MockLocationService _service;

  LocationRepositoryImpl(this._service);

  @override
  List<GeoLocation> getLocations() => _service.getLocations();

  @override
  void addLocation(GeoLocation location) => _service.addLocation(location);

  @override
  void clearLocations() => _service.clearLocations();
}
