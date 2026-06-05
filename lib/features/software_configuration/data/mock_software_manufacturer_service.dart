import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';
import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';
import 'package:cogctl_ux/features/infrastructure/data/mock_network_inventory_service.dart';

class MockSoftwareManufacturerService {
  static final MockSoftwareManufacturerService _instance = MockSoftwareManufacturerService._internal();

  factory MockSoftwareManufacturerService() {
    return _instance;
  }

  MockSoftwareManufacturerService._internal() {
    _resetDefaults();
  }

  final List<MockSoftwareManufacturerConfig> _configs = [];

  void _resetDefaults() {
    _configs.clear();

    final netService = MockNetworkInventoryService();
    try {
      if (netService.getNetworkElement('ne-01') == null) {
        netService.addNetworkElement(MockNetworkElement(
          neId: 'ne-01',
          componentIds: ['chassis-01', 'gigabit-port-01'],
        ));
      }
    } on FormatException {
      // NE already exists due to initialization ordering — safe to ignore.
    }

    // Seed default configuration 1: Network Element ne-01
    _configs.add(MockSoftwareManufacturerConfig(
      id: 'cfg-ne-01',
      targetType: 'Network Element',
      targetId: 'ne-01',
      uuid: '8f0b784a-d34e-4f18-bb71-8bc6a99264fa',
      name: 'ne-01-core',
      alias: 'ne-core-1',
      description: 'Main Core router',
      mfgName: 'Cisco',
      productName: 'NCS-5501',
      softwareRevisions: [
        MockSoftwareRevision(
          name: 'XR-Core',
          revision: '7.3.2',
          patches: [
            MockSoftwarePatch(revision: 'patch-1'),
            MockSoftwarePatch(revision: 'patch-2'),
          ],
        ),
      ],
    ));

    // Seed default configuration 2: Component chassis-01
    _configs.add(MockSoftwareManufacturerConfig(
      id: 'cfg-comp-01',
      targetType: 'Component',
      targetId: 'chassis-01',
      uuid: '9d47ac6a-2d4e-4a4a-9b4f-4d924d67362a',
      name: 'chassis-01-element',
      alias: 'chassis-1',
      description: 'Main Chassis unit',
      mfgName: 'Cisco',
      productName: 'NCS-Chassis-5500',
      softwareRevisions: [
        MockSoftwareRevision(
          name: 'Chassis-Firmware',
          revision: '2.1.0',
          patches: [],
        ),
      ],
    ));
  }

  void resetToDefaults() {
    _resetDefaults();
  }

  List<MockSoftwareManufacturerConfig> getConfigs() {
    return List.unmodifiable(_configs);
  }

  void addConfig(MockSoftwareManufacturerConfig config) {
    if (_configs.any((c) => c.id == config.id)) {
      throw FormatException("Configuration ID '${config.id}' already exists.");
    }
    _configs.add(config);
  }

  void deleteConfig(String id) {
    _configs.removeWhere((c) => c.id == id);
  }

  void updateConfig(MockSoftwareManufacturerConfig config) {
    final idx = _configs.indexWhere((c) => c.id == config.id);
    if (idx != -1) {
      _configs[idx] = config;
    }
  }

  String validateConfig(MockSoftwareManufacturerConfig config) {
    if (config.mfgName.trim().isEmpty) {
      return 'Invalid: Manufacturer name cannot be empty.';
    }
    if (config.productName.trim().isEmpty) {
      return 'Invalid: Product name cannot be empty.';
    }
    if (config.uuid.trim().isNotEmpty) {
      final uuidRegExp = RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$');
      if (!uuidRegExp.hasMatch(config.uuid.trim())) {
        return 'Invalid: UUID format is invalid.';
      }
    }
    
    final moduleNames = <String>{};
    for (final rev in config.softwareRevisions) {
      if (rev.name.trim().isEmpty) {
        return 'Invalid: Software module name cannot be empty.';
      }
      if (moduleNames.contains(rev.name)) {
        return 'Invalid: Duplicate software module name "${rev.name}".';
      }
      moduleNames.add(rev.name);

      if (rev.revision.trim().isEmpty) {
        return 'Invalid: Software revision is required for module "${rev.name}".';
      }

      final patchRevisions = <String>{};
      for (final patch in rev.patches) {
        if (patch.revision.trim().isEmpty) {
          return 'Invalid: Patch revision cannot be empty in module "${rev.name}".';
        }
        if (patchRevisions.contains(patch.revision)) {
          return 'Invalid: Duplicate patch revision "${patch.revision}" in module "${rev.name}".';
        }
        patchRevisions.add(patch.revision);
      }
    }

    // Check if target entity exists
    final netService = MockNetworkInventoryService();
    if (config.targetType == 'Network Element') {
      final ne = netService.getNetworkElement(config.targetId);
      if (ne == null) {
        return 'Unresolved: Network Element "${config.targetId}" not found.';
      }
    } else if (config.targetType == 'Component') {
      bool found = false;
      for (final ne in netService.getNetworkElements()) {
        if (ne.componentIds.contains(config.targetId)) {
          found = true;
          break;
        }
      }
      if (!found) {
        return 'Unresolved: Component "${config.targetId}" not found.';
      }
    }

    return 'Valid';
  }
}
