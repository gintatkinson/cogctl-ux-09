import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/counter_gauge.dart';

enum CounterGaugeStatus { initial, success, failure }

class CounterGaugeState extends Equatable {
  final List<YangCounterGauge> nodes;
  final YangCounterGauge? selectedNode;
  final CounterGaugeStatus status;
  final String? valueError;
  final String? generalError;

  const CounterGaugeState({
    required this.nodes,
    this.selectedNode,
    this.status = CounterGaugeStatus.initial,
    this.valueError,
    this.generalError,
  });

  @override
  List<Object?> get props => [nodes, selectedNode, status, valueError, generalError];

  CounterGaugeState copyWith({
    List<YangCounterGauge>? nodes,
    YangCounterGauge? Function()? selectedNode,
    CounterGaugeStatus? status,
    String? Function()? valueError,
    String? Function()? generalError,
  }) {
    return CounterGaugeState(
      nodes: nodes ?? this.nodes,
      selectedNode: selectedNode != null ? selectedNode() : this.selectedNode,
      status: status ?? this.status,
      valueError: valueError != null ? valueError() : this.valueError,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
