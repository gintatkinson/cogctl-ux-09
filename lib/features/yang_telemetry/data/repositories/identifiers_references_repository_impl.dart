import 'package:cogctl_ux/features/yang_telemetry/data/mock_identifiers_references_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/identifiers_references.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_identifiers_references_repository.dart';

class IdentifiersReferencesRepositoryImpl implements IIdentifiersReferencesRepository {
  final MockIdentifiersReferencesService _service;

  IdentifiersReferencesRepositoryImpl(this._service);

  @override
  List<YangIdentifierReference> getNodes() => _service.getNodes();

  @override
  void updateNodeValue(String id, String newValue) {
    _service.updateNodeValue(id, newValue);
  }

  @override
  void addNode(YangIdentifierReference node) => _service.addNode(node);

  @override
  void clearAll() => _service.clearAll();
}
