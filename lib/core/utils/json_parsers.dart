int parseInt(Object? value, {int fallback = 0}) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return fallback;
    }
    return int.tryParse(normalized) ??
        double.tryParse(normalized)?.toInt() ??
        fallback;
  }
  return fallback;
}

bool parseBool(Object? value, {bool fallback = false}) {
  if (value == null) {
    return fallback;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
        return false;
    }
  }
  return fallback;
}

String parseString(Object? value, {String fallback = '-'}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

DateTime? parseDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse('$value');
}
