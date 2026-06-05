import 'package:flutter/material.dart';
import 'format_utils.dart';

/// Attaches a validation listener to [controller] that calls [validate] on
/// each text change, writing the error message to [setError] on failure and
/// clearing it on success. An optional [onEmpty] callback runs when the text
/// is empty (defaults to clearing the error). An optional [onChanged] callback
/// runs after every validation attempt (both success and failure) for
/// non-empty text.
void addValidationListener({
  required TextEditingController controller,
  required void Function(String? error) setError,
  required void Function(String text) validate,
  VoidCallback? onEmpty,
  VoidCallback? onChanged,
}) {
  controller.addListener(() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      if (onEmpty != null) {
        onEmpty();
      } else {
        setError(null);
      }
      return;
    }
    try {
      validate(text);
      setError(null);
    } catch (e) {
      setError(formatExceptionMessage(e));
    }
    onChanged?.call();
  });
}
