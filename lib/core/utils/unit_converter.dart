import 'package:instock/data/models/app_models.dart';

class UnitConverter {
  static const _weightUnits = {'g', 'kg', 'oz', 'lb', 'lbs'};
  static const _volumeUnits = {
    'ml',
    'l',
    'cup',
    'cups',
    'tbsp',
    'tsp',
    'fl oz',
  };

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
      'tbsp' => value * 15,
      'tsp' => value * 5,
      'fl oz' => value * 29.5735,
      _ => value,
    };
  }

  static double? convertQuantity(double value, String fromUnit, String toUnit) {
    final from = fromUnit.toLowerCase().trim();
    final to = toUnit.toLowerCase().trim();
    if (from == to) return value;

    final fromIsWeight = _weightUnits.contains(from);
    final toIsWeight = _weightUnits.contains(to);
    if (fromIsWeight && toIsWeight) {
      return _gramsToUnit(toGrams(value, from), to);
    }

    final fromIsVolume = _volumeUnits.contains(from);
    final toIsVolume = _volumeUnits.contains(to);
    if (fromIsVolume && toIsVolume) {
      return _millilitersToUnit(toMilliliters(value, from), to);
    }

    return null;
  }

  static double _gramsToUnit(double grams, String unit) {
    return switch (unit.toLowerCase()) {
      'kg' => grams / 1000,
      'g' => grams,
      'oz' => grams / 28.3495,
      'lb' || 'lbs' => grams / 453.592,
      _ => grams,
    };
  }

  static double _millilitersToUnit(double milliliters, String unit) {
    return switch (unit.toLowerCase()) {
      'l' => milliliters / 1000,
      'ml' => milliliters,
      'cup' || 'cups' => milliliters / 240,
      'tbsp' => milliliters / 15,
      'tsp' => milliliters / 5,
      'fl oz' => milliliters / 29.5735,
      _ => milliliters,
    };
  }

  static String formatQty(double qty, String unit) {
    final display = qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1);
    return '$display $unit';
  }

  static double scaleQuantity(
    double qty,
    int originalServings,
    int newServings,
  ) {
    if (originalServings == 0) return qty;
    return qty * newServings / originalServings;
  }

  // Returns the stock status comparing pantry quantity/unit against needed quantity/unit.
  // Normalises weight↔weight and volume↔volume; returns low for cross-system units so
  // inStock is never falsely reported when units are incompatible.
  static StockStatus calculateStockStatus(
    double pantryQty,
    String pantryUnit,
    double neededQty,
    String neededUnit,
  ) {
    if (pantryQty == 0) return StockStatus.need;

    final pUnit = pantryUnit.toLowerCase().trim();
    final nUnit = neededUnit.toLowerCase().trim();

    final pIsWeight = _weightUnits.contains(pUnit);
    final nIsWeight = _weightUnits.contains(nUnit);
    final pIsVolume = _volumeUnits.contains(pUnit);
    final nIsVolume = _volumeUnits.contains(nUnit);

    double pantryNorm = pantryQty;
    double neededNorm = neededQty;

    if (pIsWeight && nIsWeight) {
      pantryNorm = toGrams(pantryQty, pUnit);
      neededNorm = toGrams(neededQty, nUnit);
    } else if (pIsVolume && nIsVolume) {
      pantryNorm = toMilliliters(pantryQty, pUnit);
      neededNorm = toMilliliters(neededQty, nUnit);
    } else if (pUnit != nUnit) {
      // Incompatible unit systems — never report inStock; caller must verify manually
      return StockStatus.low;
    }

    if (pantryNorm >= neededNorm) return StockStatus.inStock;
    return StockStatus.low;
  }
}
