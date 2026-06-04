import 'package:cogctl_ux/features/yang_telemetry/data/mock_time_duration_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/time_duration.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_time_duration_repository.dart';

class TimeDurationRepositoryImpl implements ITimeDurationRepository {
  final MockTimeDurationService _service;

  TimeDurationRepositoryImpl(this._service);

  @override
  List<YangTimeDurationReference> getNodes() => _service.getNodes();

  @override
  void updateNodeValue(String id, String newValue) {
    _service.updateNodeValue(id, newValue);
  }

  @override
  void addNode(YangTimeDurationReference node) => _service.addNode(node);
}
