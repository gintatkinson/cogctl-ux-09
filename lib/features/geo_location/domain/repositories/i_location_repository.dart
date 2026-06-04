import 'package:cogctl_ux/features/geo_location/domain/geo_location.dart';

abstract class ILocationRepository {
  List<GeoLocation> getLocations();
  void addLocation(GeoLocation location);
  void clearLocations();
}
