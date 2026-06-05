import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/utils/format_error.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/date_time.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_date_time_repository.dart';
import 'date_time_state.dart';

class DateTimeCubit extends Cubit<DateTimeState> {
  final IDateTimeRepository _repository;

  DateTimeCubit(this._repository) : super(const DateTimeState(nodes: [])) {
    loadNodes();
  }

  void loadNodes() {
    try {
      final nodes = _repository.getNodes();
      emit(state.copyWith(
        nodes: List.of(nodes),
        status: DateTimeStatus.success,
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
        status: DateTimeStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectNode(YangDateTimeReference? node) {
    emit(state.copyWith(
      selectedNode: () => node,
      valueError: () => null,
    ));
  }

  void validateValue(String val, YangDateTimeType type) {
    if (val.isEmpty) {
      emit(state.copyWith(valueError: () => null));
      return;
    }
    try {
      YangDateTimeValidator.validate(val, type);
      emit(state.copyWith(valueError: () => null));
    } catch (e) {
      emit(state.copyWith(valueError: () => formatError(e)));
    }
  }

  void updateValue(String id, String val) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.updateNodeValue(id, val);
      loadNodes();
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
    }
  }
}
