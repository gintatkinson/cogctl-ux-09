class MockSoftwarePatch {
  final String revision;

  MockSoftwarePatch({required this.revision});

  MockSoftwarePatch copyWith({String? revision}) {
    return MockSoftwarePatch(
      revision: revision ?? this.revision,
    );
  }

  Map<String, dynamic> toJson() => {'revision': revision};
  factory MockSoftwarePatch.fromJson(Map<String, dynamic> json) {
    return MockSoftwarePatch(
      revision: json['revision'] as String,
    );
  }
}

class MockSoftwareRevision {
  final String name;
  final String revision;
  final List<MockSoftwarePatch> patches;

  MockSoftwareRevision({
    required this.name,
    required this.revision,
    required this.patches,
  });

  MockSoftwareRevision copyWith({
    String? name,
    String? revision,
    List<MockSoftwarePatch>? patches,
  }) {
    return MockSoftwareRevision(
      name: name ?? this.name,
      revision: revision ?? this.revision,
      patches: patches ?? this.patches,
    );
  }
}

class MockSoftwareManufacturerConfig {
  final String id;
  final String targetType; // 'Network Element' or 'Component'
  final String targetId; // target identifier
  final String uuid;
  final String name;
  final String alias;
  final String description;
  final String mfgName;
  final String productName;
  final List<MockSoftwareRevision> softwareRevisions;

  MockSoftwareManufacturerConfig({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.uuid,
    required this.name,
    required this.alias,
    required this.description,
    required this.mfgName,
    required this.productName,
    required this.softwareRevisions,
  });

  MockSoftwareManufacturerConfig copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? uuid,
    String? name,
    String? alias,
    String? description,
    String? mfgName,
    String? productName,
    List<MockSoftwareRevision>? softwareRevisions,
  }) {
    return MockSoftwareManufacturerConfig(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      description: description ?? this.description,
      mfgName: mfgName ?? this.mfgName,
      productName: productName ?? this.productName,
      softwareRevisions: softwareRevisions ?? this.softwareRevisions,
    );
  }
}
