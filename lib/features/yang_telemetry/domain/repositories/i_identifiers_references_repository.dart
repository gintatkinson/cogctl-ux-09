import 'package:cogctl_ux/features/yang_telemetry/domain/identifiers_references.dart';

abstract class IIdentifiersReferencesRepository {
  List<YangIdentifierReference> getNodes();
  void updateNodeValue(String id, String newValue);
  void addNode(YangIdentifierReference node);
  void clearAll();
}
