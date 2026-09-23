import 'dart:convert';
import 'dart:typed_data';

// String cloak for sealed slips. 24-byte salt, a murmur-style mixer.
// The twin writer is tool/slip_press.dart — keep this file as the only mixer.

const List<int> _salt = <int>[
  0x17, 0xA4, 0x6E, 0xD2, 0x09, 0xB8, 0x53, 0xF1,
  0x8C, 0x2D, 0x70, 0xE6, 0x3B, 0x94, 0xC5, 0x11,
  0x5A, 0xDE, 0x42, 0x88, 0xF9, 0x06, 0x73, 0xBE,
];

const int _golden = 0x9E3779B9;
const int _lane = 0x85EBCA6B;
const int _nudge = 0x27BB2EE6;

int _mix(int s) {
  s &= 0xFFFFFFFF;
  s = (s ^ (s >> 16)) & 0xFFFFFFFF;
  s = (s * 0x7FEB352D) & 0xFFFFFFFF;
  s = (s ^ (s >> 15)) & 0xFFFFFFFF;
  s = (s * 0x846CA68B) & 0xFFFFFFFF;
  s = (s ^ (s >> 16)) & 0xFFFFFFFF;
  return s;
}

int _seed() {
  int h = _golden;
  for (final int b in _salt) {
    h = (h + (b * _lane)) & 0xFFFFFFFF;
    h = _mix(h);
  }
  return h == 0 ? 0xC0FFEE01 : h;
}

int _step(int acc, int i) {
  final int saltByte = _salt[i % _salt.length];
  acc = (acc + saltByte * (i + 1) + _nudge) & 0xFFFFFFFF;
  return _mix(acc);
}

int _keyByte(int acc, int i) {
  final int lane = (i & 3) * 8;
  return ((acc >> lane) ^ (acc >> 11) ^ (i * 13)) & 0xFF;
}

List<int> sealText(String plain) {
  if (plain.isEmpty) return const <int>[];
  final List<int> bytes = utf8.encode(plain);
  final List<int> out = List<int>.filled(bytes.length, 0);
  int acc = _seed();
  for (int i = 0; i < bytes.length; i++) {
    acc = _step(acc, i);
    out[i] = (bytes[i] ^ _keyByte(acc, i)) & 0xFF;
  }
  return out;
}

String openText(List<int> data) {
  if (data.isEmpty) return '';
  final Uint8List out = Uint8List(data.length);
  int acc = _seed();
  for (int i = 0; i < data.length; i++) {
    acc = _step(acc, i);
    out[i] = (data[i] ^ _keyByte(acc, i)) & 0xFF;
  }
  return utf8.decode(out);
}
