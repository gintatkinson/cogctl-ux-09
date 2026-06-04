import 'package:cogctl_ux/features/infrastructure/data/mock_equipment_rack_service.dart';
import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_equipment_rack_repository.dart';

class EquipmentRackRepositoryImpl implements IEquipmentRackRepository {
  final MockEquipmentRackService _service;

  EquipmentRackRepositoryImpl(this._service);

  @override
  List<EquipmentRack> getRacks() => _service.getRacks();

  @override
  void addRack(EquipmentRack rack, {Set<String> validLocationIds = const {}}) {
    _service.addRack(rack, validLocationIds: validLocationIds);
  }

  @override
  void updateRack(String id, EquipmentRack updatedRack, {Set<String> validLocationIds = const {}}) {
    _service.updateRack(id, updatedRack, validLocationIds: validLocationIds);
  }

  @override
  void deleteRack(String id) => _service.deleteRack(id);

  @override
  void reset() => _service.reset();
}
