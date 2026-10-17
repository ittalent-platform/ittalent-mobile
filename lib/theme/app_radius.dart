import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double button = 12.0;
  static const double input = 12.0;
  static const double card = 16.0;
  static const double dialog = 16.0;
  static const double pill = 9999.0;

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(dialog),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
