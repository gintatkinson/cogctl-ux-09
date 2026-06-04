import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';

abstract class INetworkInventoryRepository {
  List<MockNetworkElement> getNetworkElements();
  MockNetworkElement? getNetworkElement(String neId);
  void addNetworkElement(MockNetworkElement ne);
  void deleteNetworkElement(String neId);
  void addComponent(String neId, String componentId);
  void deleteComponent(String neId, String componentId);
  void clearAll();
  void resetToDefaults();
}
