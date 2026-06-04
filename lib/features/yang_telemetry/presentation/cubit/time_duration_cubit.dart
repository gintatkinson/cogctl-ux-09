import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/time_duration.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_time_duration_repository.dart';
import 'time_duration_state.dart';

class TimeDurationCubit extends Cubit<TimeDurationState> {
  final ITimeDurationRepository _repository;

  TimeDurationCubit(this._repository) : super(const TimeDurationState(nodes: [])) {
    loadNodes();
  }

  void loadNodes() {
    try {
      final nodes = _repository.getNodes();
      emit(state.copyWith(
        nodes: List.of(nodes),
        status: TimeDurationStatus.success,
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
        status: TimeDurationStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectNode(YangTimeDurationReference? node) {
    emit(state.copyWith(
      selectedNode: () => node,
      valueError: () => null,
    ));
  }

  void validateValue(String val, YangTimeDurationType type) {
    if (val.isEmpty) {
      emit(state.copyWith(valueError: () => null));
      return;
    }
    try {
      YangTimeDurationValidator.validate(val, type);
      emit(state.copyWith(valueError: () => null));
    } catch (e) {
      emit(state.copyWith(valueError: () => e.toString().replaceFirst('FormatException: ', '')));
    }
  }

  void updateValue(String id, String val) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.updateNodeValue(id, val);
      loadNodes();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString().replaceFirst('FormatException: ', '')));
    }
  }
}
