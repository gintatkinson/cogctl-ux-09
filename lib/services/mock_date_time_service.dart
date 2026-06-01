import '../models/date_time.dart';

class MockDateTimeService {
  static final MockDateTimeService _instance = MockDateTimeService._internal();

  factory MockDateTimeService() {
    return _instance;
  }

  MockDateTimeService._internal();

  final List<YangDateTimeReference> _nodes = [
    YangDateTimeReference(
      id: 'datetime-utc',
      name: 'System Boot Time',
      type: YangDateTimeType.dateAndTime,
      description: 'The date and time when the system finished booting (UTC).',
      value: '2026-06-01T12:00:00Z',
    ),
    YangDateTimeReference(
      id: 'datetime-leap',
      name: 'Leap Second Epoch',
      type: YangDateTimeType.dateAndTime,
      description: 'Historical epoch containing a scheduled UTC leap second.',
      value: '2016-12-31T23:59:60Z',
    ),
    YangDateTimeReference(
      id: 'date-offset',
      name: 'Calibration Date',
      type: YangDateTimeType.date,
      description: 'The date of the last sensor calibration (+08:00 offset).',
      value: '2026-06-01+08:00',
    ),
    YangDateTimeReference(
      id: 'date-nz',
      name: 'Release Date (No Zone)',
      type: YangDateTimeType.dateNoZone,
      description: 'The official release date of this software version.',
      value: '2026-06-01',
    ),
    YangDateTimeReference(
      id: 'time-offset',
      name: 'Backup Trigger Time',
      type: YangDateTimeType.time,
      description: 'The recurring time when daily backup starts (-05:00 offset).',
      value: '14:30:00-05:00',
    ),
    YangDateTimeReference(
      id: 'time-nz',
      name: 'Telemetry Interval (No Zone)',
      type: YangDateTimeType.timeNoZone,
      description: 'Relative interval offset for polling telemetry.',
      value: '09:15:30.123',
    ),
  ];

  List<YangDateTimeReference> getNodes() {
    return List.unmodifiable(_nodes);
  }

  void updateNodeValue(String id, String newValue) {
    final node = _nodes.firstWhere(
      (n) => n.id == id,
      orElse: () => throw ArgumentError("Node with ID '$id' not found"),
    );
    node.updateValue(newValue);
  }

  void addNode(YangDateTimeReference node) {
    if (_nodes.any((n) => n.id == node.id)) {
      throw ArgumentError("Node with ID '${node.id}' already exists");
    }
    // Verify valid format before adding
    YangDateTimeValidator.validate(node.value, node.type);
    _nodes.add(node);
  }
}
