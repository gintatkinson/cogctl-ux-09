import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';

abstract class IEquipmentRackRepository {
  List<EquipmentRack> getRacks();
  void addRack(EquipmentRack rack, {Set<String> validLocationIds = const {}});
  void updateRack(String id, EquipmentRack updatedRack, {Set<String> validLocationIds = const {}});
  void deleteRack(String id);
  void reset();
}
