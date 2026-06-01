enum YangDataType {
  counter32,
  zeroBasedCounter32,
  counter64,
  zeroBasedCounter64,
  gauge32,
  gauge64,
}

class YangCounterGauge {
  final String id;
  final String name;
  final YangDataType type;
  final String description;
  BigInt value;
  final BigInt? maxLimit; // Optional max capacity/limit for gauges to compute utilization percentage
  final List<BigInt> history; // Keep track of the last few updates to render sparklines

  YangCounterGauge({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.value,
    this.maxLimit,
    List<BigInt>? history,
  }) : history = history ?? [value];

  bool get isZeroBased =>
      type == YangDataType.zeroBasedCounter32 ||
      type == YangDataType.zeroBasedCounter64;

  bool get isCounter =>
      type == YangDataType.counter32 ||
      type == YangDataType.zeroBasedCounter32 ||
      type == YangDataType.counter64 ||
      type == YangDataType.zeroBasedCounter64;

  bool get isGauge =>
      type == YangDataType.gauge32 ||
      type == YangDataType.gauge64;

  bool get is64Bit =>
      type == YangDataType.counter64 ||
      type == YangDataType.zeroBasedCounter64 ||
      type == YangDataType.gauge64;

  double get utilization {
    if (!isGauge || maxLimit == null || maxLimit == BigInt.zero) return 0.0;
    return (value.toDouble() / maxLimit!.toDouble()).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'value': value.toString(),
        if (maxLimit != null) 'max-limit': maxLimit!.toString(),
        'history': history.map((e) => e.toString()).toList(),
      };

  factory YangCounterGauge.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = YangDataType.values.firstWhere((e) => e.name == typeName);
    return YangCounterGauge(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      description: json['description'] as String,
      value: BigInt.parse(json['value'] as String),
      maxLimit: json['max-limit'] != null ? BigInt.parse(json['max-limit'] as String) : null,
      history: json['history'] != null
          ? (json['history'] as List).map((e) => BigInt.parse(e as String)).toList()
          : null,
    );
  }

  void updateValue(BigInt newValue, {bool discontinuity = false}) {
    YangCounterGaugeValidator.validateUpdate(
      currentValue: value,
      newValue: newValue,
      type: type,
      discontinuity: discontinuity,
      maxLimit: maxLimit,
    );
    value = newValue;
    history.add(newValue);
    if (history.length > 10) {
      history.removeAt(0);
    }
  }
}

class YangCounterGaugeValidator {
  static final BigInt maxUint32 = BigInt.from(4294967295);
  static final BigInt maxUint64 = BigInt.parse('18446744073709551615');

  static void validateValue(BigInt value, YangDataType type) {
    if (value < BigInt.zero) {
      throw const FormatException("Value must be non-negative");
    }
    
    final bool is32Bit = type == YangDataType.counter32 ||
        type == YangDataType.zeroBasedCounter32 ||
        type == YangDataType.gauge32;

    if (is32Bit) {
      if (value > maxUint32) {
        throw FormatException("Value $value exceeds 32-bit limit of $maxUint32");
      }
    } else {
      if (value > maxUint64) {
        throw FormatException("Value $value exceeds 64-bit limit of $maxUint64");
      }
    }
  }

  static void validateUpdate({
    required BigInt currentValue,
    required BigInt newValue,
    required YangDataType type,
    required bool discontinuity,
    BigInt? maxLimit,
  }) {
    validateValue(newValue, type);

    final bool isCounter = type == YangDataType.counter32 ||
        type == YangDataType.zeroBasedCounter32 ||
        type == YangDataType.counter64 ||
        type == YangDataType.zeroBasedCounter64;

    if (isCounter && !discontinuity && newValue < currentValue) {
      throw const FormatException(
          "Counter value cannot decrease unless a discontinuity/re-initialization is signaled");
    }

    final bool isGauge = type == YangDataType.gauge32 ||
        type == YangDataType.gauge64;

    if (isGauge && maxLimit != null && newValue > maxLimit) {
      throw FormatException(
          "Gauge value $newValue exceeds max limit of $maxLimit");
    }
  }
}
