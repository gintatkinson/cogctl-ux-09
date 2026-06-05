import 'package:cogctl_ux/features/yang_telemetry/data/mock_date_time_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/date_time.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_date_time_repository.dart';

class DateTimeRepositoryImpl implements IDateTimeRepository {
  final MockDateTimeService _service;

  DateTimeRepositoryImpl(this._service);

  @override
  List<YangDateTimeReference> getNodes() => _service.getNodes();

  @override
  void updateNodeValue(String id, String newValue) {
    _service.updateNodeValue(id, newValue);
  }

  @override
  void addNode(YangDateTimeReference node) => _service.addNode(node);
}
