import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';

enum SoftwareManufacturerStatus { initial, success, failure }

class SoftwareManufacturerState {
  final List<MockSoftwareManufacturerConfig> configs;
  final MockSoftwareManufacturerConfig? selectedConfig;
  final SoftwareManufacturerStatus status;
  final String? generalError;

  const SoftwareManufacturerState({
    required this.configs,
    this.selectedConfig,
    this.status = SoftwareManufacturerStatus.initial,
    this.generalError,
  });

  SoftwareManufacturerState copyWith({
    List<MockSoftwareManufacturerConfig>? configs,
    MockSoftwareManufacturerConfig? Function()? selectedConfig,
    SoftwareManufacturerStatus? status,
    String? Function()? generalError,
  }) {
    return SoftwareManufacturerState(
      configs: configs ?? this.configs,
      selectedConfig: selectedConfig != null ? selectedConfig() : this.selectedConfig,
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
