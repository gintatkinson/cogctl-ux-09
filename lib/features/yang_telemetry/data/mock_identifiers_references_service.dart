import 'package:cogctl_ux/features/yang_telemetry/domain/identifiers_references.dart';

class MockIdentifiersReferencesService {
  static final MockIdentifiersReferencesService _instance =
      MockIdentifiersReferencesService._internal();

  factory MockIdentifiersReferencesService() => _instance;

  final List<YangIdentifierReference> _nodes = [];

  MockIdentifiersReferencesService._internal() {
    _nodes.addAll([
      YangIdentifierReference(
        id: 'enterprise-oid',
        name: 'IANA Private Enterprise OID',
        type: YangIdentifierType.objectIdentifier,
        description:
            'Administratively assigned names in a registration hierarchical tree for private enterprise nodes (RFC 9911).',
        value: '1.3.6.1.4.1',
      ),
      YangIdentifierReference(
        id: 'sys-descr-oid',
        name: 'System Description OID',
        type: YangIdentifierType.objectIdentifier128,
        description:
            'Standard system description object identifier restricted to 128 sub-identifiers.',
        value: '1.3.6.1.2.1.1.1',
      ),
      YangIdentifierReference(
        id: 'interface-name',
        name: 'YANG Interface Name',
        type: YangIdentifierType.yangIdentifier,
        description:
            'Standard YANG identifier string denoting the local network interface slot/port (RFC 7950).',
        value: 'gigabit-ethernet-0.1',
      ),
      YangIdentifierReference(
        id: 'sdn-controller-id',
        name: 'SDN Active Controller ID',
        type: YangIdentifierType.yangIdentifier,
        description:
            'The unique, RFC-compliant YANG identifier string for the primary cognitive controller.',
        value: 'sdn_controller_active',
      ),
      YangIdentifierReference(
        id: 'root-cc-oid',
        name: 'Cognitive Controller Root OID',
        type: YangIdentifierType.objectIdentifier,
        description:
            'Root OID arc assigning space to the Cognitive Controller under the administrative joint-iso-itu-t branch.',
        value: '2.999.1.1.2',
      ),
    ]);
  }

  List<YangIdentifierReference> getNodes() => List.unmodifiable(_nodes);

  void updateNodeValue(String id, String newValue) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index == -1) {
      throw FormatException("Node with id '$id' not found");
    }
    // Will throw FormatException if value is invalid
    _nodes[index].updateValue(newValue);
  }

  void addNode(YangIdentifierReference node) {
    if (_nodes.any((n) => n.id == node.id)) {
      throw FormatException("Node with id '${node.id}' already exists");
    }
    // Validate value before adding
    YangIdentifierValidator.validate(node.value, node.type);
    _nodes.add(node);
  }

  void clearAll() {
    _nodes.clear();
  }
}
