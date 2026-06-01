import '../models/equipment_rack.dart';

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
      ),
    ]);
  }

  List<EquipmentRack> getRacks() => List.unmodifiable(_racks);

  void addRack(EquipmentRack rack, {Set<String> validLocationIds = const {}}) {
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
    );

    // Check for duplicate ID
    if (_racks.any((r) => r.id == rack.id)) {
      throw FormatException("Rack ID '${rack.id}' already exists");
    }

    _racks.add(rack);
  }

  void updateRack(String id, EquipmentRack updatedRack, {Set<String> validLocationIds = const {}}) {
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
    _racks.removeWhere((r) => r.id == id);
  }

  void reset() {
    _resetDefaults();
  }
}
