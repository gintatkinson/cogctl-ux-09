import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/utils/format_error.dart';
import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_types_references_repository.dart';
import 'types_references_state.dart';

class TypesReferencesCubit extends Cubit<TypesReferencesState> {
  final ITypesReferencesRepository _repository;

  TypesReferencesCubit(this._repository) : super(const TypesReferencesState(references: [])) {
    loadReferences();
  }

  void loadReferences() {
    try {
      final references = _repository.getReferences();
      emit(state.copyWith(
        references: List.of(references),
        status: TypesReferencesStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TypesReferencesStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void addReference(MockInventoryTypeReference ref) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.addReference(ref);
      loadReferences();
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
    }
  }

  void deleteReference(String id) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.deleteReference(id);
      loadReferences();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }

  void setComponentClass(String compId, String compClass) {
    try {
      _repository.setComponentClass(compId, compClass);
      loadReferences();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }

  String validateReference(MockInventoryTypeReference ref) {
    return _repository.validateReference(ref);
  }

  void resetToDefaults() {
    try {
      _repository.resetToDefaults();
      loadReferences();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }
}
