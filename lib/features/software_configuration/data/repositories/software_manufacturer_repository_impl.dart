import 'package:cogctl_ux/features/software_configuration/data/mock_software_manufacturer_service.dart';
import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_software_manufacturer_repository.dart';

class SoftwareManufacturerRepositoryImpl implements ISoftwareManufacturerRepository {
  final MockSoftwareManufacturerService _service;

  SoftwareManufacturerRepositoryImpl(this._service);

  @override
  List<MockSoftwareManufacturerConfig> getConfigs() => _service.getConfigs();

  @override
  void addConfig(MockSoftwareManufacturerConfig config) => _service.addConfig(config);

  @override
  void deleteConfig(String id) => _service.deleteConfig(id);

  @override
  void updateConfig(MockSoftwareManufacturerConfig config) => _service.updateConfig(config);

  @override
  String validateConfig(MockSoftwareManufacturerConfig config) => _service.validateConfig(config);

  @override
  void resetToDefaults() => _service.resetToDefaults();
}
