import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';

abstract class ISoftwareManufacturerRepository {
  List<MockSoftwareManufacturerConfig> getConfigs();
  void addConfig(MockSoftwareManufacturerConfig config);
  void deleteConfig(String id);
  void updateConfig(MockSoftwareManufacturerConfig config);
  String validateConfig(MockSoftwareManufacturerConfig config);
  void resetToDefaults();
}
