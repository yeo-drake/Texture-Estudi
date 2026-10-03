import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'holoprint_service.dart';

class HoloPrintScreen extends StatefulWidget {
  const HoloPrintScreen({super.key});

  @override
  State<HoloPrintScreen> createState() => _HoloPrintScreenState();
}

class _HoloPrintScreenState extends State<HoloPrintScreen> {
  final HoloPrintService _service = HoloPrintService();

  File? _file;
  bool _working = false;
  HoloPrintResult? _result;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['mcstructure'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _file = File(result.files.single.path!);
      _result = null;
      _error = null;
    });
  }

  Future<void> _generate() async {
    if (_file == null) {
      setState(() => _error = 'Selecciona un archivo .mcstructure primero.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
      _result = null;
    });

    try {
      final r = await _service.generate(_file!);
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
      appBar: AppBar(title: const Text('HoloPrint')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _working ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar .mcstructure'),
            ),
            const SizedBox(height: 12),
            if (_file != null)
              ListTile(
                leading: const Icon(Icons.view_in_ar),
                title: Text(_file!.path.split('/').last),
                subtitle: Text(
                  '${(_file!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin archivo seleccionado.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            const Spacer(),
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
                      const Text(
                        '✅ Holograma generado',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text('Tamaño: ${_result!.width} × ${_result!.height} × ${_result!.length}'),
                      Text('Bloques: ${_result!.blockCount}'),
                      Text('Bloques únicos: ${_result!.uniqueBlocks}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (_result == null)
              ElevatedButton.icon(
                onPressed: _working ? null : _generate,
                icon: _working
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_working ? 'Generando...' : 'Generar .mcpack'),
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