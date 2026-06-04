import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/address_tag.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_address_tag_repository.dart';
import 'address_tag_state.dart';

class AddressTagCubit extends Cubit<AddressTagState> {
  final IAddressTagRepository _repository;

  AddressTagCubit(this._repository) : super(const AddressTagState(nodes: [])) {
    loadNodes();
  }

  void loadNodes() {
    try {
      final nodes = _repository.getNodes();
      emit(state.copyWith(
        nodes: List.of(nodes),
        status: AddressTagStatus.success,
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
        status: AddressTagStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectNode(YangAddressTagReference? node) {
    emit(state.copyWith(
      selectedNode: () => node,
      valueError: () => null,
    ));
  }

  void validateValue(String val, YangAddressTagType type) {
    if (val.isEmpty) {
      emit(state.copyWith(valueError: () => null));
      return;
    }
    try {
      YangAddressTagValidator.validateAndNormalize(val, type);
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
