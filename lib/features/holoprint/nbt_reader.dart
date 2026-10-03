import 'dart:convert';
import 'dart:typed_data';

/// Lector mínimo de archivos NBT en formato Bedrock (little-endian).
class NbtReader {
  final Uint8List _d;
  int _p = 0;

  NbtReader(this._d);

  int _i8() {
    final v = _d[_p++];
    return v >= 128 ? v - 256 : v;
  }

  int _i16() {
    final v = _d[_p] | (_d[_p + 1] << 8);
    _p += 2;
    return v >= 0x8000 ? v - 0x10000 : v;
  }

  int _i32() {
    final v = _d[_p] |
        (_d[_p + 1] << 8) |
        (_d[_p + 2] << 16) |
        (_d[_p + 3] << 24);
    _p += 4;
    return v;
  }

  int _i64() {
    int v = 0;
    for (int i = 0; i < 8; i++) {
      v |= _d[_p + i] << (8 * i);
    }
    _p += 8;
    return v;
  }

  double _f32() {
    final bd = ByteData(4);
    for (int i = 0; i < 4; i++) {
      bd.setUint8(i, _d[_p + i]);
    }
    _p += 4;
    return bd.getFloat32(0, Endian.little);
  }

  double _f64() {
    final bd = ByteData(8);
    for (int i = 0; i < 8; i++) {
      bd.setUint8(i, _d[_p + i]);
    }
    _p += 8;
    return bd.getFloat64(0, Endian.little);
  }

  String _name() {
    final len = (_d[_p] << 8) | _d[_p + 1];
    _p += 2;
    final s = utf8.decode(_d.sublist(_p, _p + len), allowMalformed: true);
    _p += len;
    return s;
  }

  Map<String, dynamic> parse() {
    final t = _i8();
    if (t != 10) {
      throw Exception('NBT: la raíz no es un compound');
    }
    _name();
    final root = _payload(10) as Map;
    return root.cast<String, dynamic>();
  }

  dynamic _payload(int type) {
    switch (type) {
      case 1:
        return _i8();
      case 2:
        return _i16();
      case 3:
        return _i32();
      case 4:
        return _i64();
      case 5:
        return _f32();
      case 6:
        return _f64();
      case 7:
        final len = _i32();
        final out = _d.sublist(_p, _p + len);
        _p += len;
        return out;
      case 8:
        return _name();
      case 9:
        final elem = _i8();
        final len = _i32();
        final out = <dynamic>[];
        for (int i = 0; i < len; i++) {
          out.add(_payload(elem));
        }
        return out;
      case 10:
        final out = <String, dynamic>{};
        while (true) {
          final t = _i8();
          if (t == 0) break;
          final name = _name();
          out[name] = _payload(t);
        }
        return out;
      case 11:
        final len = _i32();
        final out = <int>[];
        for (int i = 0; i < len; i++) {
          out.add(_i32());
        }
        return out;
      case 12:
        final len = _i32();
        final out = <int>[];
        for (int i = 0; i < len; i++) {
          out.add(_i64());
        }
        return out;
      default:
        throw Exception('NBT: tipo desconocido $type');
    }
  }
}