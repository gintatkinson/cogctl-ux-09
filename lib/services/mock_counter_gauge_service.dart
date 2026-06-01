import '../models/counter_gauge.dart';

class MockCounterGaugeService {
  static final MockCounterGaugeService _instance = MockCounterGaugeService._internal();
  factory MockCounterGaugeService() => _instance;

  final List<YangCounterGauge> _nodes = [];

  MockCounterGaugeService._internal() {
    _nodes.addAll([
      YangCounterGauge(
        id: 'rx-packets',
        name: 'Interface RX Packets',
        type: YangDataType.zeroBasedCounter64,
        description: 'Number of packets received on interface gigabitethernet0/1. Initializes at zero.',
        value: BigInt.zero,
      ),
      YangCounterGauge(
        id: 'tx-errors',
        name: 'Interface TX Errors',
        type: YangDataType.counter32,
        description: 'Cumulative transmit packets with errors on gigabitethernet0/1.',
        value: BigInt.from(14),
      ),
      YangCounterGauge(
        id: 'cpu-util',
        name: 'CPU Core 1 Utilization',
        type: YangDataType.gauge32,
        description: 'Real-time CPU utilization percentage for cognitive processing core 1.',
        value: BigInt.from(42),
        maxLimit: BigInt.from(100),
      ),
      YangCounterGauge(
        id: 'card-memory',
        name: 'Line Card Memory Used',
        type: YangDataType.gauge64,
        description: 'Physical RAM utilization on line card 2, in bytes.',
        value: BigInt.from(6442450944), // 6 GB
        maxLimit: BigInt.from(17179869184), // 16 GB
      ),
      YangCounterGauge(
        id: 'qkd-keys',
        name: 'QKD Key Buffer Rate',
        type: YangDataType.gauge32,
        description: 'Active key generation rate for Quantum Key Distribution channel alpha, in bits per second.',
        value: BigInt.from(2450),
        maxLimit: BigInt.from(5000),
      ),
      YangCounterGauge(
        id: 'ntn-drops',
        name: 'NTN Satellite Link Dropouts',
        type: YangDataType.counter32,
        description: 'Total tracking lock dropouts on Non-Terrestrial Network satellite link.',
        value: BigInt.from(3),
      ),
      YangCounterGauge(
        id: 'tunnel-traffic',
        name: 'VPN Tunnel Traffic',
        type: YangDataType.zeroBasedCounter32,
        description: 'Zero-based 32-bit counter tracking IPSec tunnel encapsulation volume.',
        value: BigInt.zero,
      ),
    ]);
  }

  List<YangCounterGauge> getNodes() => List.unmodifiable(_nodes);

  void updateNodeValue(String id, BigInt newValue, {bool discontinuity = false}) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index == -1) {
      throw FormatException("Node with id '$id' not found");
    }
    _nodes[index].updateValue(newValue, discontinuity: discontinuity);
  }

  void addNode(YangCounterGauge node) {
    if (_nodes.any((n) => n.id == node.id)) {
      throw FormatException("Node with id '${node.id}' already exists");
    }
    // Validate value before adding
    YangCounterGaugeValidator.validateValue(node.value, node.type);
    _nodes.add(node);
  }

  void resetNode(String id) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index == -1) {
      throw FormatException("Node with id '$id' not found");
    }
    // Set to zero
    _nodes[index].updateValue(BigInt.zero, discontinuity: true);
  }

  void clearAll() {
    _nodes.clear();
  }
}
