import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';

abstract class ITypesReferencesRepository {
  List<MockInventoryTypeReference> getReferences();
  void addReference(MockInventoryTypeReference ref);
  void deleteReference(String id);
  String getComponentClass(String compId);
  void setComponentClass(String compId, String compClass);
  String validateReference(MockInventoryTypeReference ref);
  void resetToDefaults();
}
