import 'package:cogctl_ux/features/software_configuration/data/mock_types_references_service.dart';
import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_types_references_repository.dart';

class TypesReferencesRepositoryImpl implements ITypesReferencesRepository {
  final MockTypesReferencesService _service;

  TypesReferencesRepositoryImpl(this._service);

  @override
  List<MockInventoryTypeReference> getReferences() => _service.getReferences();

  @override
  void addReference(MockInventoryTypeReference ref) => _service.addReference(ref);

  @override
  void deleteReference(String id) => _service.deleteReference(id);

  @override
  String getComponentClass(String compId) => _service.getComponentClass(compId);

  @override
  void setComponentClass(String compId, String compClass) {
    _service.setComponentClass(compId, compClass);
  }

  @override
  String validateReference(MockInventoryTypeReference ref) => _service.validateReference(ref);

  @override
  void resetToDefaults() => _service.resetToDefaults();
}
