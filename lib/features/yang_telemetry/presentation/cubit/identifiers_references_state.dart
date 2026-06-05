import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/identifiers_references.dart';

enum IdentifiersReferencesStatus { initial, success, failure }

class IdentifiersReferencesState extends Equatable {
  final List<YangIdentifierReference> nodes;
  final YangIdentifierReference? selectedNode;
  final IdentifiersReferencesStatus status;
  final String? valueError;
  final String? generalError;

  const IdentifiersReferencesState({
    required this.nodes,
    this.selectedNode,
    this.status = IdentifiersReferencesStatus.initial,
    this.valueError,
    this.generalError,
  });

  @override
  List<Object?> get props => [nodes, selectedNode, status, valueError, generalError];

  IdentifiersReferencesState copyWith({
    List<YangIdentifierReference>? nodes,
    YangIdentifierReference? Function()? selectedNode,
    IdentifiersReferencesStatus? status,
    String? Function()? valueError,
    String? Function()? generalError,
  }) {
    return IdentifiersReferencesState(
      nodes: nodes ?? this.nodes,
      selectedNode: selectedNode != null ? selectedNode() : this.selectedNode,
      status: status ?? this.status,
      valueError: valueError != null ? valueError() : this.valueError,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
