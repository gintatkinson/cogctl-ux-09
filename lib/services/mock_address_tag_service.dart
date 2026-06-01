import '../models/address_tag.dart';

class MockAddressTagService {
  static final MockAddressTagService _instance = MockAddressTagService._internal();

  factory MockAddressTagService() => _instance;

  final List<YangAddressTagReference> _nodes = [];

  MockAddressTagService._internal() {
    _nodes.addAll([
      YangAddressTagReference(
        id: 'active-controller-uuid',
        name: 'Active Controller UUID',
        type: YangAddressTagType.uuid,
        description: 'The canonical 128-bit Universally Unique Identifier for the active cognitive controller instance (RFC 9562).',
        value: 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
      ),
      YangAddressTagReference(
        id: 'switch-mac-address',
        name: 'SDN Switch MAC Address',
        type: YangAddressTagType.macAddress,
        description: 'The 48-bit Media Access Control address of the primary SDN switch (IEEE 802).',
        value: '00:1a:2b:3c:4d:5e',
      ),
      YangAddressTagReference(
        id: 'nic-phys-address',
        name: 'NIC Hardware Physical Address',
        type: YangAddressTagType.physAddress,
        description: 'Media- or physical-level address representing the hardware NIC interface.',
        value: '00:1a:2b:3c:4d:5e:6f:70',
      ),
      YangAddressTagReference(
        id: 'mgmt-dotted-quad',
        name: 'Management Interface Dotted-Quad',
        type: YangAddressTagType.dottedQuad,
        description: 'Management interface IP expressed in dotted-quad notation.',
        value: '192.168.1.1',
      ),
      YangAddressTagReference(
        id: 'preferred-lang',
        name: 'Preferred System Language Tag',
        type: YangAddressTagType.languageTag,
        description: 'Preferred system locale language tag conforming to BCP 47 (RFC 5646).',
        value: 'en-us',
      ),
      YangAddressTagReference(
        id: 'config-xpath',
        name: 'Default Config XPath Filter',
        type: YangAddressTagType.xpath10,
        description: 'XPath 1.0 expression filter to retrieve routing and switching nodes from configuration trees.',
        value: "/ietf-network:networks/network[network-id='primary']",
      ),
      YangAddressTagReference(
        id: 'diag-payload-hex',
        name: 'Diagnostic Payload Hex-String',
        type: YangAddressTagType.hexString,
        description: 'Hexadecimal string representation of raw octets for diagnostic telemetry packets.',
        value: 'de:ad:be:ef:12:34',
      ),
    ]);
  }

  List<YangAddressTagReference> getNodes() => List.unmodifiable(_nodes);

  void updateNodeValue(String id, String newValue) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index == -1) {
      throw FormatException("Node with id '$id' not found");
    }
    _nodes[index].updateValue(newValue);
  }

  void addNode(YangAddressTagReference node) {
    if (_nodes.any((n) => n.id == node.id)) {
      throw FormatException("Node with id '${node.id}' already exists");
    }
    YangAddressTagValidator.validateAndNormalize(node.value, node.type);
    _nodes.add(node);
  }

  void clearAll() {
    _nodes.clear();
  }
}
