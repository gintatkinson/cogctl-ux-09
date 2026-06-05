import 'package:cogctl_ux/features/yang_telemetry/domain/time_duration.dart';

abstract class ITimeDurationRepository {
  List<YangTimeDurationReference> getNodes();
  void updateNodeValue(String id, String newValue);
  void addNode(YangTimeDurationReference node);
}
