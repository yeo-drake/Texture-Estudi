import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'merger_service.dart';

class MergerScreen extends StatefulWidget {
  const MergerScreen({super.key});

  @override
  State<MergerScreen> createState() => _MergerScreenState();
}

class _MergerScreenState extends State<MergerScreen> {
  final List<File> _packs = [];
  final MergerService _service = MergerService();

  bool _working = false;
  MergeResult? _result;
  String? _error;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mcpack', 'zip', 'mcaddon'],
    );
    if (result == null) return;

    setState(() {
      _packs.clear();
      for (final f in result.files) {
        if (f.path != null) _packs.add(File(f.path!));
      }
      _result = null;
      _error = null;
    });
  }

  Future<void> _merge() async {
    if (_packs.length < 2) {
      setState(() => _error = 'Selecciona al menos 2 paquetes.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
      _result = null;
    });

    try {
      final r = await _service.merge(_packs);
      setState(() => _result = r);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    await Share.shareXFiles([XFile(_result!.outputFile.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fusionar packs')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _working ? null : _pickFiles,
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar .mcpack'),
            ),
            const SizedBox(height: 12),
            Text(
              '${_packs.length} paquete(s) seleccionado(s)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _packs.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin paquetes seleccionados todavía.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _packs.length,
                      itemBuilder: (_, i) {
                        final p = _packs[i];
                        final size =
                            (p.lengthSync() / 1024).toStringAsFixed(1);
                        return ListTile(
                          leading: const Icon(Icons.inventory_2),
                          title: Text(p.path.split('/').last),
                          subtitle: Text('$size KB'),
                        );
                      },
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Fusionado: ${_result!.filesMerged} archivos',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (_result!.conflicts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '⚠️ ${_result!.conflicts.length} conflicto(s) resueltos (se usó el último pack)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (_result == null)
              ElevatedButton.icon(
                onPressed: _working ? null : _merge,
                icon: _working
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.merge),
                label: Text(_working ? 'Fusionando...' : 'Fusionar'),
              )
            else
              ElevatedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share),
                label: const Text('Compartir .mcpack'),
              ),
          ],
        ),
      ),
    );
  }
}