enum YangDateTimeType {
  dateAndTime,
  date,
  dateNoZone,
  time,
  timeNoZone,
}

class YangDateTimeReference {
  final String id;
  final String name;
  final YangDateTimeType type;
  final String description;
  String value;

  YangDateTimeReference({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'value': value,
      };

  factory YangDateTimeReference.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = YangDateTimeType.values.firstWhere((e) => e.name == typeName);
    return YangDateTimeReference(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      description: json['description'] as String,
      value: json['value'] as String,
    );
  }

  void updateValue(String newValue) {
    YangDateTimeValidator.validate(newValue, type);
    value = newValue;
  }
}

class YangDateTimeValidator {
  static final RegExp _dateAndTimeRegExp = RegExp(
    r'^[0-9]{4}-(1[0-2]|0[1-9])-(0[1-9]|[1-2][0-9]|3[0-1])T(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?(Z|[\+\-]((1[0-3]|0[0-9]):([0-5][0-9])|14:00))?$',
  );

  static final RegExp _dateRegExp = RegExp(
    r'^[0-9]{4}-(1[0-2]|0[1-9])-(0[1-9]|[1-2][0-9]|3[0-1])(Z|[\+\-]((1[0-3]|0[0-9]):([0-5][0-9])|14:00))?$',
  );

  static final RegExp _dateNoZoneRegExp = RegExp(
    r'^[0-9]{4}-(1[0-2]|0[1-9])-(0[1-9]|[1-2][0-9]|3[0-1])$',
  );

  static final RegExp _timeRegExp = RegExp(
    r'^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?(Z|[\+\-]((1[0-3]|0[0-9]):([0-5][0-9])|14:00))?$',
  );

  static final RegExp _timeNoZoneRegExp = RegExp(
    r'^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?$',
  );

  static void validate(String value, YangDateTimeType type) {
    if (value.trim().isEmpty) {
      throw const FormatException("Value cannot be empty");
    }

    switch (type) {
      case YangDateTimeType.dateAndTime:
        _validateDateAndTime(value);
        break;
      case YangDateTimeType.date:
        _validateDate(value);
        break;
      case YangDateTimeType.dateNoZone:
        _validateDateNoZone(value);
        break;
      case YangDateTimeType.time:
        _validateTime(value);
        break;
      case YangDateTimeType.timeNoZone:
        _validateTimeNoZone(value);
        break;
    }
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static void _validateCalendarDate(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw FormatException("Month '$month' must be between 1 and 12");
    }

    int maxDays = 31;
    switch (month) {
      case 4:
      case 6:
      case 9:
      case 11:
        maxDays = 30;
        break;
      case 2:
        maxDays = _isLeapYear(year) ? 29 : 28;
        break;
    }

    if (day < 1 || day > maxDays) {
      if (month == 2 && day == 29) {
        throw FormatException("February 29 is only valid in leap years (year $year is not a leap year)");
      }
      throw FormatException("Day '$day' is invalid for month '$month' in year '$year' (max days is $maxDays)");
    }
  }

  static void _validateLeapSecond(int hour, int minute, int second, {int? month, int? day}) {
    if (second == 60) {
      if (hour != 23 || minute != 59) {
        throw const FormatException("Leap second (seconds=60) is only allowed at 23:59:60");
      }
      if (month != null && day != null) {
        // Leap seconds traditionally only scheduled on June 30 or December 31
        if (!((month == 6 && day == 30) || (month == 12 && day == 31))) {
          throw FormatException("Leap seconds are only scheduled on June 30 or December 31 (found date $month-$day)");
        }
      }
    }
  }

  static void _validateDateAndTime(String value) {
    if (!_dateAndTimeRegExp.hasMatch(value)) {
      throw const FormatException("Value does not match RFC 9911 date-and-time format");
    }

    // Parse components
    // Format: YYYY-MM-DDTHH:MM:SS(.sss)?(Z|offset)?
    final parts = value.split('T');
    final dateParts = parts[0].split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    _validateCalendarDate(year, month, day);

    // Extract time components (strip timezone info at the end)
    final timeWithZone = parts[1];
    
    // Find where timezone starts
    int zoneIdx = timeWithZone.indexOf('Z');
    if (zoneIdx == -1) {
      zoneIdx = timeWithZone.indexOf('+');
    }
    if (zoneIdx == -1) {
      zoneIdx = timeWithZone.indexOf('-');
    }

    final timePart = zoneIdx == -1 ? timeWithZone : timeWithZone.substring(0, zoneIdx);
    final timeParts = timePart.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Seconds might contain fraction
    final secondPart = timeParts[2];
    final dotIdx = secondPart.indexOf('.');
    final secondStr = dotIdx == -1 ? secondPart : secondPart.substring(0, dotIdx);
    final second = int.parse(secondStr);

    _validateLeapSecond(hour, minute, second, month: month, day: day);
  }

  static void _validateDate(String value) {
    if (!_dateRegExp.hasMatch(value)) {
      throw const FormatException("Value does not match RFC 9911 date format");
    }

    // Split year-month-day (remove timezone offset if present)
    int zoneIdx = value.indexOf('Z');
    if (zoneIdx == -1) {
      zoneIdx = value.indexOf('+');
    }
    if (zoneIdx == -1) {
      zoneIdx = value.indexOf('-');
    }

    final datePart = zoneIdx == -1 ? value : value.substring(0, zoneIdx);
    final dateParts = datePart.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    _validateCalendarDate(year, month, day);
  }

  static void _validateDateNoZone(String value) {
    if (!_dateNoZoneRegExp.hasMatch(value)) {
      throw const FormatException("Value does not match RFC 9911 date-no-zone format");
    }

    final dateParts = value.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    _validateCalendarDate(year, month, day);
  }

  static void _validateTime(String value) {
    if (!_timeRegExp.hasMatch(value)) {
      throw const FormatException("Value does not match RFC 9911 time format");
    }

    // Strip timezone
    int zoneIdx = value.indexOf('Z');
    if (zoneIdx == -1) {
      zoneIdx = value.indexOf('+');
    }
    if (zoneIdx == -1) {
      zoneIdx = value.indexOf('-');
    }

    final timePart = zoneIdx == -1 ? value : value.substring(0, zoneIdx);
    final timeParts = timePart.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Seconds might contain fraction
    final secondPart = timeParts[2];
    final dotIdx = secondPart.indexOf('.');
    final secondStr = dotIdx == -1 ? secondPart : secondPart.substring(0, dotIdx);
    final second = int.parse(secondStr);

    _validateLeapSecond(hour, minute, second);
  }

  static void _validateTimeNoZone(String value) {
    if (!_timeNoZoneRegExp.hasMatch(value)) {
      throw const FormatException("Value does not match RFC 9911 time-no-zone format");
    }

    final timeParts = value.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Seconds might contain fraction
    final secondPart = timeParts[2];
    final dotIdx = secondPart.indexOf('.');
    final secondStr = dotIdx == -1 ? secondPart : secondPart.substring(0, dotIdx);
    final second = int.parse(secondStr);

    _validateLeapSecond(hour, minute, second);
  }
}
