/// Strips the 'FormatException: ' prefix from exception messages for UI display.
String formatExceptionMessage(Object e) {
  return e.toString().replaceFirst('FormatException: ', '');
}
