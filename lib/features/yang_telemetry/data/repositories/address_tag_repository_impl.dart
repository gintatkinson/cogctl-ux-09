import 'package:cogctl_ux/features/yang_telemetry/data/mock_address_tag_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/address_tag.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_address_tag_repository.dart';

class AddressTagRepositoryImpl implements IAddressTagRepository {
  final MockAddressTagService _service;

  AddressTagRepositoryImpl(this._service);

  @override
  List<YangAddressTagReference> getNodes() => _service.getNodes();

  @override
  void updateNodeValue(String id, String newValue) {
    _service.updateNodeValue(id, newValue);
  }

  @override
  void addNode(YangAddressTagReference node) => _service.addNode(node);

  @override
  void clearAll() => _service.clearAll();
}
