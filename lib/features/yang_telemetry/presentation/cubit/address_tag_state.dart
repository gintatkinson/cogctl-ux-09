import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/address_tag.dart';

enum AddressTagStatus { initial, success, failure }

class AddressTagState extends Equatable {
  final List<YangAddressTagReference> nodes;
  final YangAddressTagReference? selectedNode;
  final AddressTagStatus status;
  final String? valueError;
  final String? generalError;

  const AddressTagState({
    required this.nodes,
    this.selectedNode,
    this.status = AddressTagStatus.initial,
    this.valueError,
    this.generalError,
  });

  @override
  List<Object?> get props => [nodes, selectedNode, status, valueError, generalError];

  AddressTagState copyWith({
    List<YangAddressTagReference>? nodes,
    YangAddressTagReference? Function()? selectedNode,
    AddressTagStatus? status,
    String? Function()? valueError,
    String? Function()? generalError,
  }) {
    return AddressTagState(
      nodes: nodes ?? this.nodes,
      selectedNode: selectedNode != null ? selectedNode() : this.selectedNode,
      status: status ?? this.status,
      valueError: valueError != null ? valueError() : this.valueError,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
