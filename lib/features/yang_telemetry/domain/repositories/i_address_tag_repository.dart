import 'package:cogctl_ux/features/yang_telemetry/domain/address_tag.dart';

abstract class IAddressTagRepository {
  List<YangAddressTagReference> getNodes();
  void updateNodeValue(String id, String newValue);
  void addNode(YangAddressTagReference node);
  void clearAll();
}
