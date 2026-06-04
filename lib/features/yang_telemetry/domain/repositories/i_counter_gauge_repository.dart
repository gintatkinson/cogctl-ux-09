import 'package:cogctl_ux/features/yang_telemetry/domain/counter_gauge.dart';

abstract class ICounterGaugeRepository {
  List<YangCounterGauge> getNodes();
  void updateNodeValue(String id, BigInt newValue, {bool discontinuity = false});
  void addNode(YangCounterGauge node);
  void resetNode(String id);
  void clearAll();
}
