import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/counter_gauge.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_counter_gauge_repository.dart';
import 'counter_gauge_state.dart';

class CounterGaugeCubit extends Cubit<CounterGaugeState> {
  final ICounterGaugeRepository _repository;

  CounterGaugeCubit(this._repository) : super(const CounterGaugeState(nodes: [])) {
    loadNodes();
  }

  void loadNodes() {
    try {
      final nodes = _repository.getNodes();
      emit(state.copyWith(
        nodes: List.of(nodes),
        status: CounterGaugeStatus.success,
      ));
      if (nodes.isNotEmpty) {
        final currentSelected = state.selectedNode != null
            ? nodes.firstWhere(
                (n) => n.id == state.selectedNode!.id,
                orElse: () => nodes.first,
              )
            : nodes.first;
        emit(state.copyWith(selectedNode: () => currentSelected));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CounterGaugeStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectNode(YangCounterGauge? node) {
    emit(state.copyWith(
      selectedNode: () => node,
      valueError: () => null,
    ));
  }

  void validateValue(String val, YangDataType type) {
    if (val.trim().isEmpty) {
      emit(state.copyWith(valueError: () => null));
      return;
    }
    try {
      final parsed = BigInt.parse(val.trim());
      YangCounterGaugeValidator.validateValue(parsed, type);
      emit(state.copyWith(valueError: () => null));
    } catch (e) {
      emit(state.copyWith(valueError: () => e.toString().replaceFirst('FormatException: ', '')));
    }
  }

  void updateValue(String id, String val, {bool discontinuity = false}) {
    emit(state.copyWith(valueError: () => null, generalError: () => null));
    try {
      final parsed = BigInt.parse(val.trim());
      _repository.updateNodeValue(id, parsed, discontinuity: discontinuity);
      loadNodes();
    } catch (e) {
      emit(state.copyWith(valueError: () => e.toString().replaceFirst('FormatException: ', '')));
    }
  }

  void resetNode(String id) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.resetNode(id);
      loadNodes();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }
}
