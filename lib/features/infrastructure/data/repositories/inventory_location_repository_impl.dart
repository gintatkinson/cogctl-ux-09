import 'package:cogctl_ux/features/infrastructure/data/mock_inventory_location_service.dart';
import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_inventory_location_repository.dart';

class InventoryLocationRepositoryImpl implements IInventoryLocationRepository {
  final MockInventoryLocationService _service;

  InventoryLocationRepositoryImpl(this._service);

  @override
  List<InventoryLocation> getLocations() => _service.getLocations();

  @override
  void addLocation(InventoryLocation location) => _service.addLocation(location);

  @override
  void updateLocation(
    String id, {
    required String type,
    String? parent,
    required DateTime timestamp,
    DateTime? validUntil,
    PhysicalAddress? physicalAddress,
    List<ContainedChassis>? containedChassis,
  }) {
    _service.updateLocation(
      id,
      type: type,
      parent: parent,
      timestamp: timestamp,
      validUntil: validUntil,
      physicalAddress: physicalAddress,
      containedChassis: containedChassis,
    );
  }

  @override
  void clearAll() => _service.clearAll();

  @override
  void reset() => _service.reset();
}
