import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class MergeResult {
  final File outputFile;
  final int filesMerged;
  final List<String> conflicts;

  MergeResult({
    required this.outputFile,
    required this.filesMerged,
    required this.conflicts,
  });
}

class MergerService {
  /// Fusiona varios .mcpack en uno solo.
  /// Los paquetes posteriores sobrescriben a los anteriores.
  Future<MergeResult> merge(
    List<File> packs, {
    String outputName = 'merged_pack',
  }) async {
    final Map<String, Uint8List> mergedFiles = {};
    final List<String> conflicts = [];

    for (final pack in packs) {
      final bytes = await pack.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (!file.isFile) continue;
        final name = file.name;
        final data = Uint8List.fromList(file.content as List<int>);
        if (mergedFiles.containsKey(name)) {
          if (!conflicts.contains(name)) conflicts.add(name);
        }
        mergedFiles[name] = data;
      }
    }

    final outArchive = Archive();
    mergedFiles.forEach((name, data) {
      outArchive.addFile(ArchiveFile(name, data.length, data));
    });

    final zipped = ZipEncoder().encode(outArchive);
    final zippedBytes = Uint8List.fromList(zipped);

    final tempDir = await getTemporaryDirectory();
    final outFile = File('${tempDir.path}/$outputName.mcpack');
    await outFile.writeAsBytes(zippedBytes);

    return MergeResult(
      outputFile: outFile,
      filesMerged: mergedFiles.length,
      conflicts: conflicts,
    );
  }
}