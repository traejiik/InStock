class UnitConverter {
  static double toGrams(double value, String unit) {
    return switch (unit.toLowerCase()) {
      'kg' => value * 1000,
      'g' => value,
      'oz' => value * 28.3495,
      'lb' || 'lbs' => value * 453.592,
      _ => value,
    };
  }

  static double toMilliliters(double value, String unit) {
    return switch (unit.toLowerCase()) {
      'l' => value * 1000,
      'ml' => value,
      'cup' || 'cups' => value * 240,
      'tbsp' => value * 14.787,
      'tsp' => value * 4.929,
      'fl oz' => value * 29.5735,
      _ => value,
    };
  }

  static String formatQty(double qty, String unit) {
    final display = qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$display $unit';
  }

  static double scaleQuantity(double qty, int originalServings, int newServings) {
    if (originalServings == 0) return qty;
    return qty * newServings / originalServings;
  }
}
