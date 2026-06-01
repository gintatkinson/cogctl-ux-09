import '../models/inventory_location.dart';

class MockInventoryLocationService {
  static final MockInventoryLocationService _instance =
      MockInventoryLocationService._internal();

  factory MockInventoryLocationService() => _instance;

  final List<InventoryLocation> _locations = [];

  MockInventoryLocationService._internal() {
    _resetDefaults();
  }

  void _resetDefaults() {
    _locations.clear();
    final now = DateTime.now();
    _locations.addAll([
      InventoryLocation(
        id: 'loc-london-hq',
        type: 'site',
        parent: null,
        timestamp: now.subtract(const Duration(days: 10)),
        validUntil: now.add(const Duration(days: 30)),
        physicalAddress: PhysicalAddress(
          address: '100 Victoria Embankment',
          city: 'London',
          state: 'Greater London',
          postalCode: 'EC4Y 0DY',
          countryCode: 'GB',
        ),
        containedChassis: [
          ContainedChassis(
            chassisId: 1,
            neRef: 'ne-A',
            componentRef: 'comp-1',
          ),
        ],
      ),
      InventoryLocation(
        id: 'loc-building-a',
        type: 'building',
        parent: 'loc-london-hq',
        timestamp: now.subtract(const Duration(days: 5)),
        validUntil: now.add(const Duration(days: 15)),
      ),
      InventoryLocation(
        id: 'loc-floor-1',
        type: 'floor',
        parent: 'loc-building-a',
        timestamp: now.subtract(const Duration(days: 4)),
        validUntil: now.add(const Duration(days: 10)),
      ),
      InventoryLocation(
        id: 'loc-server-room-101',
        type: 'room',
        parent: 'loc-floor-1',
        timestamp: now.subtract(const Duration(days: 3)),
        validUntil: now.add(const Duration(days: 5)),
      ),
      InventoryLocation(
        id: 'loc-rackspace-alpha',
        type: 'rackspace',
        parent: 'loc-server-room-101',
        timestamp: now.subtract(const Duration(days: 2)),
        validUntil: now.subtract(const Duration(days: 1)), // Expired
      ),
      InventoryLocation(
        id: 'loc-pole-x',
        type: 'pole',
        parent: null,
        timestamp: now.subtract(const Duration(days: 1)),
        validUntil: null, // Never expires
      ),
    ]);
  }

  List<InventoryLocation> getLocations() => List.unmodifiable(_locations);

  void addLocation(InventoryLocation location) {
    // Check uniqueness
    if (_locations.any((loc) => loc.id == location.id)) {
      throw FormatException("Location ID '${location.id}' already exists in the registry.");
    }

    // Run validations
    if (location.parent != null) {
      // Parent must exist
      if (!_locations.any((loc) => loc.id == location.parent)) {
        throw FormatException("Parent location '${location.parent}' does not exist.");
      }
      InventoryLocationValidator.detectCircularLoop(location.id, location.parent, _locations);
    }
    InventoryLocationValidator.validateTemporalBounds(location.timestamp, location.validUntil);
    if (location.physicalAddress != null) {
      InventoryLocationValidator.validateCountryCode(location.physicalAddress!.countryCode);
    }
    for (final chassis in location.containedChassis) {
      final others = location.containedChassis.where((c) => c != chassis).toList();
      InventoryLocationValidator.validateContainedChassis(chassis, others);
    }

    _locations.add(location);
  }

  void updateLocation(
    String id, {
    required String type,
    String? parent,
    required DateTime timestamp,
    DateTime? validUntil,
    PhysicalAddress? physicalAddress,
    List<ContainedChassis>? containedChassis,
  }) {
    final index = _locations.indexWhere((loc) => loc.id == id);
    if (index == -1) {
      throw FormatException("Location '$id' not found in registry.");
    }

    // Check circular dependencies against current registry BEFORE updating
    if (parent != null) {
      // Parent must exist
      if (!_locations.any((loc) => loc.id == parent)) {
        throw FormatException("Parent location '$parent' does not exist.");
      }
      InventoryLocationValidator.detectCircularLoop(id, parent, _locations);
    }
    InventoryLocationValidator.validateTemporalBounds(timestamp, validUntil);
    if (physicalAddress != null) {
      InventoryLocationValidator.validateCountryCode(physicalAddress.countryCode);
    }
    final chassisList = containedChassis ?? [];
    for (final chassis in chassisList) {
      final others = chassisList.where((c) => c != chassis).toList();
      InventoryLocationValidator.validateContainedChassis(chassis, others);
    }

    _locations[index] = InventoryLocation(
      id: id,
      type: type,
      parent: parent,
      timestamp: timestamp,
      validUntil: validUntil,
      physicalAddress: physicalAddress,
      containedChassis: chassisList,
    );
  }

  void clearAll() {
    _locations.clear();
  }

  void reset() {
    _resetDefaults();
  }
}
