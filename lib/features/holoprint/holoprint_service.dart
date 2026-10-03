import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'nbt_reader.dart';

class HoloPrintResult {
  final File outputFile;
  final int width;
  final int height;
  final int length;
  final int blockCount;
  final int uniqueBlocks;

  HoloPrintResult({
    required this.outputFile,
    required this.width,
    required this.height,
    required this.length,
    required this.blockCount,
    required this.uniqueBlocks,
  });
}

class HoloPrintService {
  Future<HoloPrintResult> generate(File mcstructure) async {
    final bytes = await mcstructure.readAsBytes();
    final nbt = NbtReader(bytes).parse();

    final size = (nbt['size'] as List).cast<int>();
    final w = size[0];
    final h = size[1];
    final l = size[2];

    final structure = nbt['structure'] as Map<String, dynamic>;
    final indices = structure['block_indices'] as List;
    final mainIndices = (indices[0] as List).cast<int>();

    final paletteRoot = structure['palette'] as Map<String, dynamic>;
    final defaultPalette = paletteRoot['default'] as Map<String, dynamic>;
    final blockPalette = (defaultPalette['block_palette'] as List)
        .cast<Map<String, dynamic>>();

    int blockCount = 0;
    for (final i in mainIndices) {
      if (i < 0 || i >= blockPalette.length) continue;
      final name = blockPalette[i]['name'] as String;
      if (name != 'minecraft:air') blockCount++;
    }

    final uniqueBlocks = <String>{};
    for (final b in blockPalette) {
      final n = b['name'] as String;
      if (n != 'minecraft:air') uniqueBlocks.add(n);
    }

    final headerUuid = _uuid();
    final moduleUuid = _uuid();
    final fileName = mcstructure.path.split('/').last;

    final manifest = {
      'format_version': 2,
      'header': {
        'name': 'HoloPrint - $fileName',
        'description': 'Generado con Texture Studio',
        'uuid': headerUuid,
        'version': [1, 0, 0],
        'min_engine_version': [1, 20, 0],
      },
      'modules': [
        {
          'type': 'resources',
          'uuid': moduleUuid,
          'version': [1, 0, 0],
        }
      ],
    };

    final blocksJson = <String, dynamic>{};
    for (final name in uniqueBlocks) {
      blocksJson[name] = {
        'textures': name,
        'sound': 'stone',
      };
    }

    final archive = Archive();
    void addFile(String name, List<int> data) {
      archive.addFile(ArchiveFile(name, data.length, data));
    }

    addFile('manifest.json', utf8.encode(jsonEncode(manifest)));
    addFile('blocks.json', utf8.encode(jsonEncode(blocksJson)));
    addFile('pack_icon.png', _generateIcon());
    addFile(
      'textures/textures_list.json',
      utf8.encode(jsonEncode(uniqueBlocks.toList())),
    );

    final zipped = ZipEncoder().encode(archive);
    final tempDir = await getTemporaryDirectory();
    final outFile = File(
      '${tempDir.path}/holoprint_${DateTime.now().millisecondsSinceEpoch}.mcpack',
    );
    await outFile.writeAsBytes(Uint8List.fromList(zipped!));

    return HoloPrintResult(
      outputFile: outFile,
      width: w,
      height: h,
      length: l,
      blockCount: blockCount,
      uniqueBlocks: uniqueBlocks.length,
    );
  }

  String _uuid() {
    final r = Random.secure();
    const hex = '0123456789abcdef';
    String seg(int n) => List.generate(n, (_) => hex[r.nextInt(16)]).join();
    return '${seg(8)}-${seg(4)}-4${seg(3)}-${seg(4)}-${seg(12)}';
  }

  List<int> _generateIcon() {
    final image = img.Image(width: 128, height: 128);
    img.fill(image, color: img.ColorRgb8(108, 77, 255));
    for (int y = 40; y < 88; y++) {
      for (int x = 40; x < 88; x++) {
        image.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    return img.encodePng(image);
  }
}