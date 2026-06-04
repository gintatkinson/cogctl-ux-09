import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';
import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';

enum InventoryLocationStatus { initial, success, failure }

class InventoryLocationState {
  final List<InventoryLocation> locations;
  final InventoryLocation? selectedLocation;
  final List<MockNetworkElement> networkElements;
  final InventoryLocationStatus status;
  final String? generalError;
  final String? idError;
  final String? typeError;
  final String? countryCodeError;
  final String? timestampError;
  final String? validUntilError;
  final String? neManagerError;
  final String? chassisError;
  final bool isEditing;
  final bool isNeManagerExpanded;

  const InventoryLocationState({
    required this.locations,
    this.selectedLocation,
    required this.networkElements,
    this.status = InventoryLocationStatus.initial,
    this.generalError,
    this.idError,
    this.typeError,
    this.countryCodeError,
    this.timestampError,
    this.validUntilError,
    this.neManagerError,
    this.chassisError,
    this.isEditing = false,
    this.isNeManagerExpanded = false,
  });

  InventoryLocationState copyWith({
    List<InventoryLocation>? locations,
    InventoryLocation? Function()? selectedLocation,
    List<MockNetworkElement>? networkElements,
    InventoryLocationStatus? status,
    String? Function()? generalError,
    String? Function()? idError,
    String? Function()? typeError,
    String? Function()? countryCodeError,
    String? Function()? timestampError,
    String? Function()? validUntilError,
    String? Function()? neManagerError,
    String? Function()? chassisError,
    bool? isEditing,
    bool? isNeManagerExpanded,
  }) {
    return InventoryLocationState(
      locations: locations ?? this.locations,
      selectedLocation: selectedLocation != null ? selectedLocation() : this.selectedLocation,
      networkElements: networkElements ?? this.networkElements,
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
      idError: idError != null ? idError() : this.idError,
      typeError: typeError != null ? typeError() : this.typeError,
      countryCodeError: countryCodeError != null ? countryCodeError() : this.countryCodeError,
      timestampError: timestampError != null ? timestampError() : this.timestampError,
      validUntilError: validUntilError != null ? validUntilError() : this.validUntilError,
      neManagerError: neManagerError != null ? neManagerError() : this.neManagerError,
      chassisError: chassisError != null ? chassisError() : this.chassisError,
      isEditing: isEditing ?? this.isEditing,
      isNeManagerExpanded: isNeManagerExpanded ?? this.isNeManagerExpanded,
    );
  }
}
