import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class EditorService {
  Archive? _archive;
  File? _sourcePack;
  final Map<String, Uint8List> _modified = {};

  bool get hasPack => _archive != null;
  String? get sourceName => _sourcePack?.path.split('/').last;
  int get modifiedCount => _modified.length;

  Future<List<String>> loadPack(File pack) async {
    final bytes = await pack.readAsBytes();
    _archive = ZipDecoder().decodeBytes(bytes);
    _sourcePack = pack;
    _modified.clear();

    final textures = <String>[];
    for (final f in _archive!.files) {
      if (!f.isFile) continue;
      final n = f.name.toLowerCase();
      if (n.endsWith('.png')) {
        textures.add(f.name);
      }
    }
    textures.sort();
    return textures;
  }

  Uint8List getTextureBytes(String path) {
    if (_modified.containsKey(path)) return _modified[path]!;
    final f = _archive!.files.firstWhere((e) => e.name == path);
    return Uint8List.fromList(f.content as List<int>);
  }

  void updateTexture(String path, Uint8List png) {
    _modified[path] = png;
  }

  Future<File> exportPack({String? name}) async {
    if (_archive == null) throw StateError('No hay pack cargado');

    final out = Archive();
    for (final f in _archive!.files) {
      if (!f.isFile) continue;
      final data =
          _modified[f.name] ?? Uint8List.fromList(f.content as List<int>);
      out.addFile(ArchiveFile(f.name, data.length, data));
    }

    final zipped = ZipEncoder().encode(out);
    final dir = await getTemporaryDirectory();
    final fileName = name ??
        'edited_${DateTime.now().millisecondsSinceEpoch}.mcpack';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(Uint8List.fromList(zipped));
    return file;
  }
}