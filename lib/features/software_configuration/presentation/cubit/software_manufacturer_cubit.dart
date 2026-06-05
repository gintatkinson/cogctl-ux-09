import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/utils/format_error.dart';
import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_software_manufacturer_repository.dart';
import 'software_manufacturer_state.dart';

class SoftwareManufacturerCubit extends Cubit<SoftwareManufacturerState> {
  final ISoftwareManufacturerRepository _repository;

  SoftwareManufacturerCubit(this._repository) : super(const SoftwareManufacturerState(configs: [])) {
    loadConfigs();
  }

  void loadConfigs() {
    try {
      final configs = _repository.getConfigs();
      emit(state.copyWith(
        configs: List.of(configs),
        status: SoftwareManufacturerStatus.success,
      ));
      if (configs.isNotEmpty) {
        final currentSelected = state.selectedConfig != null
            ? configs.firstWhere(
                (c) => c.id == state.selectedConfig!.id,
                orElse: () => configs.first,
              )
            : configs.first;
        emit(state.copyWith(selectedConfig: () => currentSelected));
      } else {
        emit(state.copyWith(selectedConfig: () => null));
      }
    } catch (e) {
      emit(state.copyWith(
        status: SoftwareManufacturerStatus.failure,
        generalError: () => e.toString(),
      ));
    }
  }

  void selectConfig(MockSoftwareManufacturerConfig? config) {
    emit(state.copyWith(selectedConfig: () => config));
  }

  void addConfig(MockSoftwareManufacturerConfig config) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.addConfig(config);
      loadConfigs();
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
    }
  }

  void updateConfig(MockSoftwareManufacturerConfig config) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.updateConfig(config);
      loadConfigs();
    } catch (e) {
      emit(state.copyWith(generalError: () => formatError(e)));
    }
  }

  void deleteConfig(String id) {
    emit(state.copyWith(generalError: () => null));
    try {
      _repository.deleteConfig(id);
      loadConfigs();
      if (state.selectedConfig?.id == id) {
        emit(state.copyWith(selectedConfig: () => null));
      }
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }

  String validateConfig(MockSoftwareManufacturerConfig config) {
    return _repository.validateConfig(config);
  }

  void resetToDefaults() {
    try {
      _repository.resetToDefaults();
      loadConfigs();
    } catch (e) {
      emit(state.copyWith(generalError: () => e.toString()));
    }
  }
}
