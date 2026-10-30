String formatDocumentSize(int bytes) {
  String value(double amount) {
    final rounded = amount.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }

  if (bytes < 1000) return '$bytes B';
  if (bytes < 1000000) return '${value(bytes / 1000)} KB';
  return '${value(bytes / 1000000)} MB';
}
