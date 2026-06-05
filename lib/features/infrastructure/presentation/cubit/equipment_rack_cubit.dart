import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_equipment_rack_repository.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_inventory_location_repository.dart';
import 'equipment_rack_state.dart';

class EquipmentRackCubit extends Cubit<EquipmentRackState> {
  final IEquipmentRackRepository _repository;
  final IInventoryLocationRepository _locationRepository;

  EquipmentRackCubit(this._repository, this._locationRepository)
      : super(const EquipmentRackState(racks: [], validLocationIds: [])) {
    loadData();
  }

  void loadData() {
    try {
      final racks = _repository.getRacks();
      final validLocationIds = _locationRepository.getLocations().map((l) => l.id).toList();

      EquipmentRack? nextSelected = state.selectedRack;
      if (nextSelected == null && racks.isNotEmpty) {
        nextSelected = racks.first;
      } else if (nextSelected != null) {
        nextSelected = racks.firstWhere(
          (r) => r.id == nextSelected!.id,
          orElse: () => racks.first,
        );
      }

      emit(state.copyWith(
        racks: List.of(racks),
        validLocationIds: validLocationIds,
        status: EquipmentRackStatus.success,
        selectedRack: () => nextSelected,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EquipmentRackStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectRack(EquipmentRack? rack) {
    emit(state.copyWith(
      selectedRack: () => rack,
      isEditing: false,
    ));
    _clearErrors();
  }

  void setEditing(bool editing) {
    emit(state.copyWith(isEditing: editing));
  }

  void validateField(String field, String value) {
    final trimmed = value.trim();
    switch (field) {
      case 'id':
        if (trimmed.isEmpty) {
          emit(state.copyWith(idError: () => 'Rack ID is required.'));
        } else {
          emit(state.copyWith(idError: () => null));
        }
        break;
      case 'height':
        if (trimmed.isEmpty) {
          emit(state.copyWith(heightError: () => 'Height is required.'));
          break;
        }
        try {
          final h = int.parse(trimmed);
          if (h <= 0) throw const FormatException();
          emit(state.copyWith(heightError: () => null));
        } catch (_) {
          emit(state.copyWith(heightError: () => 'Must be a positive integer.'));
        }
        break;
      case 'width':
        if (trimmed.isEmpty) {
          emit(state.copyWith(widthError: () => 'Width is required.'));
          break;
        }
        try {
          final w = int.parse(trimmed);
          if (w <= 0) throw const FormatException();
          emit(state.copyWith(widthError: () => null));
        } catch (_) {
          emit(state.copyWith(widthError: () => 'Must be a positive integer.'));
        }
        break;
      case 'depth':
        if (trimmed.isEmpty) {
          emit(state.copyWith(depthError: () => 'Depth is required.'));
          break;
        }
        try {
          final d = int.parse(trimmed);
          if (d <= 0) throw const FormatException();
          emit(state.copyWith(depthError: () => null));
        } catch (_) {
          emit(state.copyWith(depthError: () => 'Must be a positive integer.'));
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
        } catch (_) {
          emit(state.copyWith(timestampError: () => 'Invalid ISO-8601 format.'));
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
        } catch (_) {
          emit(state.copyWith(validUntilError: () => 'Invalid ISO-8601 format.'));
        }
        break;
      case 'rowNumber':
        if (trimmed.isEmpty) {
          emit(state.copyWith(rowError: () => 'Row number is required.'));
          break;
        }
        try {
          final r = int.parse(trimmed);
          if (r < 0) throw const FormatException();
          emit(state.copyWith(rowError: () => null));
        } catch (_) {
          emit(state.copyWith(rowError: () => 'Must be a non-negative integer.'));
        }
        break;
      case 'columnNumber':
        if (trimmed.isEmpty) {
          emit(state.copyWith(colError: () => 'Column number is required.'));
          break;
        }
        try {
          final c = int.parse(trimmed);
          if (c < 0) throw const FormatException();
          emit(state.copyWith(colError: () => null));
        } catch (_) {
          emit(state.copyWith(colError: () => 'Must be a non-negative integer.'));
        }
        break;
      case 'maxVoltage':
        if (trimmed.isEmpty) {
          emit(state.copyWith(maxVoltageError: () => 'Max voltage is required.'));
          break;
        }
        try {
          final v = double.parse(trimmed);
          if (v <= 0) throw const FormatException();
          emit(state.copyWith(maxVoltageError: () => null));
        } catch (_) {
          emit(state.copyWith(maxVoltageError: () => 'Must be a positive number.'));
        }
        break;
      case 'maxAllocatedPower':
        if (trimmed.isEmpty) {
          emit(state.copyWith(maxAllocatedPowerError: () => 'Max power is required.'));
          break;
        }
        try {
          final p = double.parse(trimmed);
          if (p <= 0) throw const FormatException();
          emit(state.copyWith(maxAllocatedPowerError: () => null));
        } catch (_) {
          emit(state.copyWith(maxAllocatedPowerError: () => 'Must be a positive number.'));
        }
        break;
    }
  }

  void addRack({
    required String id,
    required String rackClass,
    required String rawHeight,
    required String rawWidth,
    required String rawDepth,
    required String rawTimestamp,
    String? rawValidUntil,
    required String locationRef,
    required String rawRow,
    required String rawCol,
    required String rawMaxVoltage,
    required String rawMaxAllocatedPower,
    required List<RackContainedChassis> containedChassis,
  }) {
    emit(state.copyWith(generalError: () => null));
    try {
      final height = int.parse(rawHeight.trim());
      final width = int.parse(rawWidth.trim());
      final depth = int.parse(rawDepth.trim());
      final timestamp = DateTime.parse(rawTimestamp.trim());
      final rawVU = (rawValidUntil ?? '').trim();
      if (rawVU.isEmpty) {
        throw const FormatException('Valid-until is required');
      }
      final validUntil = DateTime.parse(rawVU);
      final row = locationRef.isNotEmpty ? int.parse(rawRow.trim()) : 0;
      final col = locationRef.isNotEmpty ? int.parse(rawCol.trim()) : 0;
      final maxVoltage = int.parse(rawMaxVoltage.trim());
      final maxAllocatedPower = int.parse(rawMaxAllocatedPower.trim());

      final newRack = EquipmentRack(
        id: id.trim(),
        rackClass: rackClass.trim(),
        height: height,
        width: width,
        depth: depth,
        timestamp: timestamp,
        validUntil: validUntil,
        rackLocation: locationRef.isNotEmpty
            ? RackLocation(
                locationRef: locationRef,
                rowNumber: row,
                columnNumber: col,
              )
            : null,
        maxVoltage: maxVoltage,
        maxAllocatedPower: maxAllocatedPower,
        containedChassis: containedChassis,
      );

      _repository.addRack(newRack, validLocationIds: Set.from(state.validLocationIds));
      loadData();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString().replaceFirst('FormatException: ', '')));
    }
  }

  void updateRack({
    required String id,
    required String rackClass,
    required String rawHeight,
    required String rawWidth,
    required String rawDepth,
    required String rawTimestamp,
    String? rawValidUntil,
    required String locationRef,
    required String rawRow,
    required String rawCol,
    required String rawMaxVoltage,
    required String rawMaxAllocatedPower,
    required List<RackContainedChassis> containedChassis,
  }) {
    emit(state.copyWith(generalError: () => null));
    try {
      final height = int.parse(rawHeight.trim());
      final width = int.parse(rawWidth.trim());
      final depth = int.parse(rawDepth.trim());
      final timestamp = DateTime.parse(rawTimestamp.trim());
      final rawVU = (rawValidUntil ?? '').trim();
      if (rawVU.isEmpty) {
        throw const FormatException('Valid-until is required');
      }
      final validUntil = DateTime.parse(rawVU);
      final row = locationRef.isNotEmpty ? int.parse(rawRow.trim()) : 0;
      final col = locationRef.isNotEmpty ? int.parse(rawCol.trim()) : 0;
      final maxVoltage = int.parse(rawMaxVoltage.trim());
      final maxAllocatedPower = int.parse(rawMaxAllocatedPower.trim());

      final updatedRack = EquipmentRack(
        id: id,
        rackClass: rackClass.trim(),
        height: height,
        width: width,
        depth: depth,
        timestamp: timestamp,
        validUntil: validUntil,
        rackLocation: locationRef.isNotEmpty
            ? RackLocation(
                locationRef: locationRef,
                rowNumber: row,
                columnNumber: col,
              )
            : null,
        maxVoltage: maxVoltage,
        maxAllocatedPower: maxAllocatedPower,
        containedChassis: containedChassis,
      );

      _repository.updateRack(id, updatedRack, validLocationIds: Set.from(state.validLocationIds));
      loadData();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString().replaceFirst('FormatException: ', '')));
    }
  }

  void deleteRack(String id) {
    try {
      _repository.deleteRack(id);
      loadData();
      if (state.selectedRack?.id == id) {
        emit(state.copyWith(selectedRack: () => null));
      }
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
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

  void setGeneralError(String? error) {
    emit(state.copyWith(generalError: () => error));
  }

  void _clearErrors() {
    emit(state.copyWith(
      generalError: () => null,
      idError: () => null,
      heightError: () => null,
      widthError: () => null,
      depthError: () => null,
      timestampError: () => null,
      validUntilError: () => null,
      rowError: () => null,
      colError: () => null,
      maxVoltageError: () => null,
      maxAllocatedPowerError: () => null,
      chassisError: () => null,
    ));
  }
}
