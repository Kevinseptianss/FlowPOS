String formatRupiah(num value, {bool includeSymbol = true}) {
  // Use floor or round since Rupiah doesn't use decimals in this context
  final intValue = value.round();
  final digits = intValue.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return includeSymbol ? 'Rp ${buffer.toString()}' : buffer.toString();
}
