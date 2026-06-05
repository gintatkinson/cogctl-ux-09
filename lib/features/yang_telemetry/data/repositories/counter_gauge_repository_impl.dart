import 'package:cogctl_ux/features/yang_telemetry/data/mock_counter_gauge_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/counter_gauge.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_counter_gauge_repository.dart';

class CounterGaugeRepositoryImpl implements ICounterGaugeRepository {
  final MockCounterGaugeService _service;

  CounterGaugeRepositoryImpl(this._service);

  @override
  List<YangCounterGauge> getNodes() => _service.getNodes();

  @override
  void updateNodeValue(String id, BigInt newValue, {bool discontinuity = false}) {
    _service.updateNodeValue(id, newValue, discontinuity: discontinuity);
  }

  @override
  void addNode(YangCounterGauge node) => _service.addNode(node);

  @override
  void resetNode(String id) => _service.resetNode(id);

  @override
  void clearAll() => _service.clearAll();
}
