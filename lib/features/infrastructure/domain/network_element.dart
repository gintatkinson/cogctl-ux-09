class MockNetworkElement {
  final String neId;
  final List<String> componentIds;

  MockNetworkElement({
    required this.neId,
    required this.componentIds,
  });

  MockNetworkElement copyWith({
    String? neId,
    List<String>? componentIds,
  }) {
    return MockNetworkElement(
      neId: neId ?? this.neId,
      componentIds: componentIds ?? this.componentIds,
    );
  }
}
