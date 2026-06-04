import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';

abstract class IInventoryLocationRepository {
  List<InventoryLocation> getLocations();
  void addLocation(InventoryLocation location);
  void updateLocation(
    String id, {
    required String type,
    String? parent,
    required DateTime timestamp,
    DateTime? validUntil,
    PhysicalAddress? physicalAddress,
    List<ContainedChassis>? containedChassis,
  });
  void clearAll();
  void reset();
}
