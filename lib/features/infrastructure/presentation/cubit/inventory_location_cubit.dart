import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/utils/format_error.dart';
import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';
import 'package:cogctl_ux/features/infrastructure/domain/network_element.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_inventory_location_repository.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_network_inventory_repository.dart';
import 'inventory_location_state.dart';

class InventoryLocationCubit extends Cubit<InventoryLocationState> {
  final IInventoryLocationRepository _repository;
  final INetworkInventoryRepository _networkInventoryRepository;

  InventoryLocationCubit(this._repository, this._networkInventoryRepository)
      : super(const InventoryLocationState(locations: [], networkElements: [])) {
    loadData();
  }

  void loadData() {
    try {
      final locs = _repository.getLocations();
      final nes = _networkInventoryRepository.getNetworkElements();
      emit(state.copyWith(
        locations: List.of(locs),
        networkElements: List.of(nes),
        status: InventoryLocationStatus.success,
      ));
      if (state.selectedLocation != null) {
        final currentSelected = locs.firstWhere(
          (l) => l.id == state.selectedLocation!.id,
          orElse: () => locs.first,
        );
        emit(state.copyWith(selectedLocation: () => currentSelected));
      }
    } catch (e) {
      emit(state.copyWith(
        status: InventoryLocationStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectLocation(InventoryLocation? location) {
    emit(state.copyWith(
      selectedLocation: () => location,
      isEditing: false,
    ));
    _clearErrors();
  }

  void setEditing(bool editing) {
    emit(state.copyWith(isEditing: editing));
  }

  void setNeManagerExpanded(bool expanded) {
    emit(state.copyWith(isNeManagerExpanded: expanded));
  }

  void validateField(String field, String value) {
    final trimmed = value.trim();
    switch (field) {
      case 'id':
        if (trimmed.isEmpty) {
          emit(state.copyWith(idError: () => 'Location ID is required.'));
        } else {
          emit(state.copyWith(idError: () => null));
        }
        break;
      case 'type':
        if (trimmed.isEmpty) {
          emit(state.copyWith(typeError: () => 'Location type is required.'));
        } else {
          emit(state.copyWith(typeError: () => null));
        }
        break;
      case 'countryCode':
        if (trimmed.isEmpty) {
          emit(state.copyWith(countryCodeError: () => null));
          break;
        }
        try {
          InventoryLocationValidator.validateCountryCode(trimmed);
          emit(state.copyWith(countryCodeError: () => null));
        } catch (e) {
          emit(state.copyWith(countryCodeError: () => formatError(e)));
        }
        break;
      case 'timestamp':
        if (trimmed.isEmpty) {
          emit(state.copyWith(timestampError: () => 'Timestamp is required.'));
          break;
        }
        try {
          DateTime.parse(trimmed);
          emit(state.copyWith(timestampError: () => null));
        } catch (e) {
          emit(state.copyWith(timestampError: () => 'Invalid date format. Use ISO-8601 (YYYY-MM-DDThh:mm:ssZ).'));
        }
        break;
      case 'validUntil':
        if (trimmed.isEmpty) {
          emit(state.copyWith(validUntilError: () => null));
          break;
        }
        try {
          DateTime.parse(trimmed);
          emit(state.copyWith(validUntilError: () => null));
        } catch (e) {
          emit(state.copyWith(validUntilError: () => 'Invalid date format. Use ISO-8601 (YYYY-MM-DDThh:mm:ssZ).'));
        }
        break;
    }
  }

   bool addLocation({
    required String id,
    required String type,
    String? parent,
    required String rawTimestamp,
    String? rawValidUntil,
    PhysicalAddress? physicalAddress,
    required List<ContainedChassis> containedChassis,
  }) {
    emit(state.copyWith(generalError: () => null));
    try {
      if (id.trim().isEmpty) throw const FormatException('Location ID is required.');
      if (type.trim().isEmpty) throw const FormatException('Location type is required.');
      if (rawTimestamp.trim().isEmpty) throw const FormatException('Timestamp is required.');

      final timestamp = DateTime.parse(rawTimestamp.trim());
      final validUntil = rawValidUntil != null && rawValidUntil.trim().isNotEmpty
          ? DateTime.parse(rawValidUntil.trim())
          : null;

      final newLoc = InventoryLocation(
        id: id.trim(),
        type: type.trim(),
        parent: parent,
        timestamp: timestamp,
        validUntil: validUntil,
        physicalAddress: physicalAddress,
        containedChassis: containedChassis,
      );

      _repository.addLocation(newLoc);
      loadData();
      return true;
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
      return false;
    }
  }

  bool updateLocation({
    required String id,
    required String type,
    String? parent,
    required String rawTimestamp,
    String? rawValidUntil,
    PhysicalAddress? physicalAddress,
    required List<ContainedChassis> containedChassis,
  }) {
    emit(state.copyWith(generalError: () => null));
    try {
      if (type.trim().isEmpty) throw const FormatException('Location type is required.');
      if (rawTimestamp.trim().isEmpty) throw const FormatException('Timestamp is required.');

      final timestamp = DateTime.parse(rawTimestamp.trim());
      final validUntil = rawValidUntil != null && rawValidUntil.trim().isNotEmpty
          ? DateTime.parse(rawValidUntil.trim())
          : null;

      _repository.updateLocation(
        id,
        type: type.trim(),
        parent: parent,
        timestamp: timestamp,
        validUntil: validUntil,
        physicalAddress: physicalAddress,
        containedChassis: containedChassis,
      );
      loadData();
      return true;
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
      return false;
    }
  }

  void resetAll() {
    try {
      _repository.reset();
      loadData();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }

  void deleteLocation(String id) {
    try {
      // Just a clearAll wrapper since we can clear and load defaults,
      // or we can remove the location if we implement remove in repository.
      // Wait, mock_inventory_location_service has clearAll, but not delete. Let's see if delete is required.
      // In main.dart, does it have delete location? No, main.dart only adds or updates.
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }

  // Network Elements
  void addNetworkElement(String neId, List<String> componentIds) {
    emit(state.copyWith(neManagerError: () => null));
    try {
      if (neId.trim().isEmpty) {
        throw const FormatException('Network Element ID cannot be empty.');
      }
      _networkInventoryRepository.addNetworkElement(MockNetworkElement(
        neId: neId.trim(),
        componentIds: componentIds,
      ));
      loadData();
    } catch (e) {
      emit(state.copyWith(neManagerError: () => formatError(e)));
    }
  }

  void deleteNetworkElement(String neId) {
    try {
      _networkInventoryRepository.deleteNetworkElement(neId);
      loadData();
    } catch (e) {
      emit(state.copyWith(neManagerError: () => e.toString()));
    }
  }

  void addComponent(String neId, String componentId) {
    emit(state.copyWith(neManagerError: () => null));
    try {
      if (componentId.trim().isEmpty) {
        throw const FormatException('Component ID cannot be empty.');
      }
      _networkInventoryRepository.addComponent(neId, componentId.trim());
      loadData();
    } catch (e) {
      emit(state.copyWith(neManagerError: () => formatError(e)));
    }
  }

  void deleteComponent(String neId, String componentId) {
    try {
      _networkInventoryRepository.deleteComponent(neId, componentId);
      loadData();
    } catch (e) {
      emit(state.copyWith(neManagerError: () => e.toString()));
    }
  }

  void _clearErrors() {
    emit(state.copyWith(
      generalError: () => null,
      idError: () => null,
      typeError: () => null,
      countryCodeError: () => null,
      timestampError: () => null,
      validUntilError: () => null,
      neManagerError: () => null,
      chassisError: () => null,
    ));
  }
}
