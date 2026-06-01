import '../models/time_duration.dart';

class MockTimeDurationService {
  static final MockTimeDurationService _instance = MockTimeDurationService._internal();

  factory MockTimeDurationService() {
    return _instance;
  }

  MockTimeDurationService._internal();

  final List<YangTimeDurationReference> _nodes = [
    YangTimeDurationReference(
      id: 'uptime-ticks',
      name: 'System Uptime Ticks',
      type: YangTimeDurationType.timeticks,
      description: 'The elapsed time modulo 2^32 in centiseconds since system boot.',
      value: '360000',
    ),
    YangTimeDurationReference(
      id: 'boot-timestamp',
      name: 'Last Boot Timestamp',
      type: YangTimeDurationType.timestamp,
      description: 'The timeticks value at which the last warm reboot was initiated.',
      value: '120000',
      associatedNodeId: 'uptime-ticks',
    ),
    YangTimeDurationReference(
      id: 'telemetry-interval',
      name: 'Telemetry Polling Interval',
      type: YangTimeDurationType.seconds32,
      description: 'The interval in seconds between consecutive polling cycles.',
      value: '60',
    ),
    YangTimeDurationReference(
      id: 'sensor-interval',
      name: 'High-Speed Sensor Interval',
      type: YangTimeDurationType.nanoseconds32,
      description: 'Sensor sampling rate in nanoseconds (subject to 2 seconds bound).',
      value: '500000000',
    ),
    YangTimeDurationReference(
      id: 'transmit-delay',
      name: 'Network Transmit Delay',
      type: YangTimeDurationType.microseconds64,
      description: 'Fiber switch transmit buffering delay in microseconds.',
      value: '1500000',
    ),
  ];

  List<YangTimeDurationReference> getNodes() {
    return List.unmodifiable(_nodes);
  }

  void updateNodeValue(String id, String newValue) {
    final node = _nodes.firstWhere(
      (n) => n.id == id,
      orElse: () => throw ArgumentError("Node with ID '$id' not found"),
    );
    node.updateValue(newValue);

    // If a timeticks node wraps around to 0, reset associated timestamps to 0
    if (node.type == YangTimeDurationType.timeticks) {
      final parsed = int.parse(newValue.trim());
      if (parsed == 0) {
        for (final n in _nodes) {
          if (n.associatedNodeId == node.id && n.type == YangTimeDurationType.timestamp) {
            n.value = '0';
          }
        }
      }
    }
  }

  void addNode(YangTimeDurationReference node) {
    if (_nodes.any((n) => n.id == node.id)) {
      throw ArgumentError("Node with ID '${node.id}' already exists");
    }
    YangTimeDurationValidator.validate(node.value, node.type);
    _nodes.add(node);
  }
}
