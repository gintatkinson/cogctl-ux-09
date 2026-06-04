import 'package:cogctl_ux/features/yang_telemetry/domain/date_time.dart';

abstract class IDateTimeRepository {
  List<YangDateTimeReference> getNodes();
  void updateNodeValue(String id, String newValue);
  void addNode(YangDateTimeReference node);
}
