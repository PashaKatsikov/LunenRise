import 'package:flutter/material.dart';

class C {
  static const navy = Color(0xFF0B1233);
  static const panel = Color(0xF2101738);
  static const panel2 = Color(0xF2182250);
  static const ink = Color(0xFF07101F);
  static const line = Color(0xFF4EF0FF);
  static const line2 = Color(0xFFF4C24A);
  static const gold = Color(0xFFF6C445);
  static const gold2 = Color(0xFFE08A12);
  static const mint = Color(0xFF7CFF62);
  static const mint2 = Color(0xFF1AA82C);
  static const lilac = Color(0xFFD7C9FF);
  static const text = Color(0xFFF7F3FF);
  static const mute = Color(0xFFA9B6E4);
  static const danger = Color(0xFFFF6B7B);
  static const chip = Color(0xD9121C44);
}

class T {
  static const title = TextStyle(
    color: C.gold,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    height: 1.05,
  );

  static const body = TextStyle(
    color: C.text,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const mute = TextStyle(
    color: C.mute,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const num = TextStyle(
    color: C.text,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );
}

String compact(num n) {
  final v = n.abs();
  String s;
  if (v >= 1000000) {
    s = '${(n / 1000000).toStringAsFixed(v >= 10000000 ? 1 : 2)}M';
  } else if (v >= 10000) {
    s = '${(n / 1000).toStringAsFixed(v >= 100000 ? 0 : 1)}K';
  } else {
    s = n.round().toString();
  }
  return s;
}
