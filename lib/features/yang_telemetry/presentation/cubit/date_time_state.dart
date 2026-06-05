import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/date_time.dart';

enum DateTimeStatus { initial, success, failure }

class DateTimeState extends Equatable {
  final List<YangDateTimeReference> nodes;
  final YangDateTimeReference? selectedNode;
  final DateTimeStatus status;
  final String? valueError;
  final String? generalError;

  const DateTimeState({
    required this.nodes,
    this.selectedNode,
    this.status = DateTimeStatus.initial,
    this.valueError,
    this.generalError,
  });

  @override
  List<Object?> get props => [nodes, selectedNode, status, valueError, generalError];

  DateTimeState copyWith({
    List<YangDateTimeReference>? nodes,
    YangDateTimeReference? Function()? selectedNode,
    DateTimeStatus? status,
    String? Function()? valueError,
    String? Function()? generalError,
  }) {
    return DateTimeState(
      nodes: nodes ?? this.nodes,
      selectedNode: selectedNode != null ? selectedNode() : this.selectedNode,
      status: status ?? this.status,
      valueError: valueError != null ? valueError() : this.valueError,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
