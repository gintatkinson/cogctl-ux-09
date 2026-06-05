import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';

enum EquipmentRackStatus { initial, success, failure }

class EquipmentRackState extends Equatable {
  final List<EquipmentRack> racks;
  final EquipmentRack? selectedRack;
  final List<String> validLocationIds;
  final EquipmentRackStatus status;
  final String? generalError;
  final String? idError;
  final String? heightError;
  final String? widthError;
  final String? depthError;
  final String? timestampError;
  final String? validUntilError;
  final String? rowError;
  final String? colError;
  final String? maxVoltageError;
  final String? maxAllocatedPowerError;
  final String? chassisError;
  final bool isEditing;

  const EquipmentRackState({
    required this.racks,
    this.selectedRack,
    required this.validLocationIds,
    this.status = EquipmentRackStatus.initial,
    this.generalError,
    this.idError,
    this.heightError,
    this.widthError,
    this.depthError,
    this.timestampError,
    this.validUntilError,
    this.rowError,
    this.colError,
    this.maxVoltageError,
    this.maxAllocatedPowerError,
    this.chassisError,
    this.isEditing = false,
  });

  @override
  List<Object?> get props => [
        racks,
        selectedRack,
        validLocationIds,
        status,
        generalError,
        idError,
        heightError,
        widthError,
        depthError,
        timestampError,
        validUntilError,
        rowError,
        colError,
        maxVoltageError,
        maxAllocatedPowerError,
        chassisError,
        isEditing,
      ];

  EquipmentRackState copyWith({
    List<EquipmentRack>? racks,
    EquipmentRack? Function()? selectedRack,
    List<String>? validLocationIds,
    EquipmentRackStatus? status,
    String? Function()? generalError,
    String? Function()? idError,
    String? Function()? heightError,
    String? Function()? widthError,
    String? Function()? depthError,
    String? Function()? timestampError,
    String? Function()? validUntilError,
    String? Function()? rowError,
    String? Function()? colError,
    String? Function()? maxVoltageError,
    String? Function()? maxAllocatedPowerError,
    String? Function()? chassisError,
    bool? isEditing,
  }) {
    return EquipmentRackState(
      racks: racks ?? this.racks,
      selectedRack: selectedRack != null ? selectedRack() : this.selectedRack,
      validLocationIds: validLocationIds ?? this.validLocationIds,
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
      idError: idError != null ? idError() : this.idError,
      heightError: heightError != null ? heightError() : this.heightError,
      widthError: widthError != null ? widthError() : this.widthError,
      depthError: depthError != null ? depthError() : this.depthError,
      timestampError: timestampError != null ? timestampError() : this.timestampError,
      validUntilError: validUntilError != null ? validUntilError() : this.validUntilError,
      rowError: rowError != null ? rowError() : this.rowError,
      colError: colError != null ? colError() : this.colError,
      maxVoltageError: maxVoltageError != null ? maxVoltageError() : this.maxVoltageError,
      maxAllocatedPowerError: maxAllocatedPowerError != null ? maxAllocatedPowerError() : this.maxAllocatedPowerError,
      chassisError: chassisError != null ? chassisError() : this.chassisError,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}
