import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/identifiers_references.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_identifiers_references_repository.dart';
import 'identifiers_references_state.dart';

class IdentifiersReferencesCubit extends Cubit<IdentifiersReferencesState> {
  final IIdentifiersReferencesRepository _repository;

  IdentifiersReferencesCubit(this._repository) : super(const IdentifiersReferencesState(nodes: [])) {
    loadNodes();
  }

  void loadNodes() {
    try {
      final nodes = _repository.getNodes();
      emit(state.copyWith(
        nodes: List.of(nodes),
        status: IdentifiersReferencesStatus.success,
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
        status: IdentifiersReferencesStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectNode(YangIdentifierReference? node) {
    emit(state.copyWith(
      selectedNode: () => node,
      valueError: () => null,
    ));
  }

  void validateValue(String val, YangIdentifierType type) {
    if (val.isEmpty) {
      emit(state.copyWith(valueError: () => null));
      return;
    }
    try {
      YangIdentifierValidator.validate(val, type);
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
