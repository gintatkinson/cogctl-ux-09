import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/time_duration.dart';

enum TimeDurationStatus { initial, success, failure }

class TimeDurationState extends Equatable {
  final List<YangTimeDurationReference> nodes;
  final YangTimeDurationReference? selectedNode;
  final TimeDurationStatus status;
  final String? valueError;
  final String? generalError;

  const TimeDurationState({
    required this.nodes,
    this.selectedNode,
    this.status = TimeDurationStatus.initial,
    this.valueError,
    this.generalError,
  });

  @override
  List<Object?> get props => [nodes, selectedNode, status, valueError, generalError];

  TimeDurationState copyWith({
    List<YangTimeDurationReference>? nodes,
    YangTimeDurationReference? Function()? selectedNode,
    TimeDurationStatus? status,
    String? Function()? valueError,
    String? Function()? generalError,
  }) {
    return TimeDurationState(
      nodes: nodes ?? this.nodes,
      selectedNode: selectedNode != null ? selectedNode() : this.selectedNode,
      status: status ?? this.status,
      valueError: valueError != null ? valueError() : this.valueError,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
