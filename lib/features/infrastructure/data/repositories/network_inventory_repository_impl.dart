import 'package:cogctl_ux/features/infrastructure/data/mock_network_inventory_service.dart';
import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_network_inventory_repository.dart';

class NetworkInventoryRepositoryImpl implements INetworkInventoryRepository {
  final MockNetworkInventoryService _service;

  NetworkInventoryRepositoryImpl(this._service);

  @override
  List<MockNetworkElement> getNetworkElements() => _service.getNetworkElements();

  @override
  MockNetworkElement? getNetworkElement(String neId) => _service.getNetworkElement(neId);

  @override
  void addNetworkElement(MockNetworkElement ne) => _service.addNetworkElement(ne);

  @override
  void deleteNetworkElement(String neId) => _service.deleteNetworkElement(neId);

  @override
  void addComponent(String neId, String componentId) {
    _service.addComponent(neId, componentId);
  }

  @override
  void deleteComponent(String neId, String componentId) {
    _service.deleteComponent(neId, componentId);
  }

  @override
  void clearAll() => _service.clearAll();

  @override
  void resetToDefaults() => _service.resetToDefaults();
}
