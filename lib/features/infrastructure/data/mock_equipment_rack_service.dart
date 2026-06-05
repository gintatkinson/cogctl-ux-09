import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';
import 'mock_network_inventory_service.dart';

class MockEquipmentRackService {
  static final MockEquipmentRackService _instance = MockEquipmentRackService._internal();

  factory MockEquipmentRackService() => _instance;

  final List<EquipmentRack> _racks = [];

  MockEquipmentRackService._internal() {
    _resetDefaults();
  }

  void _resetDefaults() {
    _racks.clear();
    _racks.addAll([
      EquipmentRack(
        id: 'Rack-Standard-42U',
        rackClass: 'rack-standard',
        height: 1866,
        width: 600,
        depth: 1000,
        timestamp: DateTime(2026, 6, 1, 12, 0),
        validUntil: DateTime(2027, 6, 1, 12, 0),
        rackLocation: RackLocation(
          locationRef: 'loc-london-hq',
          rowNumber: 2,
          columnNumber: 3,
        ),
        maxVoltage: 240,
        maxAllocatedPower: 6000,
        containedChassis: [
          RackContainedChassis(
            relativePosition: 10,
            neRef: 'ne-A',
            componentRef: 'comp-1',
            powerConsumption: 1200,
          ),
          RackContainedChassis(
            relativePosition: 12,
            neRef: 'ne-A',
            componentRef: 'comp-2',
            powerConsumption: 1500,
          ),
        ],
      ),
      EquipmentRack(
        id: 'Rack-Secure-High-48U',
        rackClass: 'rack-secure-high',
        height: 2133,
        width: 800,
        depth: 1200,
        timestamp: DateTime(2026, 6, 1, 12, 0),
        validUntil: DateTime(2027, 6, 1, 12, 0),
        rackLocation: RackLocation(
          locationRef: 'loc-london-hq',
          rowNumber: 4,
          columnNumber: 5,
        ),
        maxVoltage: 480,
        maxAllocatedPower: 12000,
        containedChassis: [],
      ),
    ]);
  }

  List<EquipmentRack> getRacks() => List.unmodifiable(_racks);

  void addRack(EquipmentRack rack, {Set<String> validLocationIds = const {}}) {
    final netService = MockNetworkInventoryService();
    final Map<String, List<String>> neCompMap = {
      for (var ne in netService.getNetworkElements()) ne.neId: ne.componentIds
    };

    EquipmentRackValidator.validate(
      id: rack.id,
      rackClass: rack.rackClass,
      height: rack.height,
      width: rack.width,
      depth: rack.depth,
      timestamp: rack.timestamp,
      validUntil: rack.validUntil,
      rackLocation: rack.rackLocation,
      validLocationIds: validLocationIds,
      maxVoltage: rack.maxVoltage,
      maxAllocatedPower: rack.maxAllocatedPower,
      containedChassis: rack.containedChassis,
      validNeComponents: neCompMap,
    );

    // Check for duplicate ID
    if (_racks.any((r) => r.id == rack.id)) {
      throw FormatException("Rack ID '${rack.id}' already exists");
    }

    _racks.add(rack);
  }

  void updateRack(String id, EquipmentRack updatedRack, {Set<String> validLocationIds = const {}}) {
    final netService = MockNetworkInventoryService();
    final Map<String, List<String>> neCompMap = {
      for (var ne in netService.getNetworkElements()) ne.neId: ne.componentIds
    };

    EquipmentRackValidator.validate(
      id: updatedRack.id,
      rackClass: updatedRack.rackClass,
      height: updatedRack.height,
      width: updatedRack.width,
      depth: updatedRack.depth,
      timestamp: updatedRack.timestamp,
      validUntil: updatedRack.validUntil,
      rackLocation: updatedRack.rackLocation,
      validLocationIds: validLocationIds,
      maxVoltage: updatedRack.maxVoltage,
      maxAllocatedPower: updatedRack.maxAllocatedPower,
      containedChassis: updatedRack.containedChassis,
      validNeComponents: neCompMap,
    );

    // Ensure we are not changing ID to another existing ID
    if (id != updatedRack.id && _racks.any((r) => r.id == updatedRack.id)) {
      throw FormatException("Rack ID '${updatedRack.id}' already exists");
    }

    final index = _racks.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw FormatException("Rack with ID '$id' not found");
    }

    _racks[index] = updatedRack;
  }

  void deleteRack(String id) {
    final index = _racks.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw FormatException("Rack with ID '$id' not found");
    }
    _racks.removeAt(index);
  }

  void reset() {
    _resetDefaults();
  }
}
