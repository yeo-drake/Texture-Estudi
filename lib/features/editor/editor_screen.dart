import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';

import 'editor_service.dart';
import 'pixel_canvas.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorService _service = EditorService();

  List<String> _textures = [];
  String? _selectedTexture;
  img.Image? _currentImage;
  Color _selectedColor = const Color(0xFFFFFFFF);
  bool _eraser = false;
  bool _loading = false;
  String? _error;

  static const List<Color> _palette = [
    Color(0xFFFFFFFF), Color(0xFF000000), Color(0xFF7F7F7F),
    Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF),
    Color(0xFFFFFF00), Color(0xFF00FFFF), Color(0xFFFF00FF),
    Color(0xFFFF7F00), Color(0xFF7F00FF), Color(0xFF00FF7F),
    Color(0xFF8B4513), Color(0xFFFFC0CB), Color(0xFF654321),
    Color(0xFF1E90FF),
  ];

  Future<void> _pickPack() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['mcpack', 'zip', 'mcaddon'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _textures = [];
      _selectedTexture = null;
      _currentImage = null;
    });

    try {
      final list = await _service.loadPack(File(result.files.single.path!));
      setState(() => _textures = list);
    } catch (e) {
      setState(() => _error = 'Error al cargar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openTexture(String path) {
    try {
      final bytes = _service.getTextureBytes(path);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        setState(() => _error = 'No se pudo decodificar la imagen');
        return;
      }
      setState(() {
        _selectedTexture = path;
        _currentImage = decoded;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  void _paintAt(int x, int y) {
    final image = _currentImage;
    if (image == null) return;

    if (_eraser) {
      image.setPixelRgba(x, y, 0, 0, 0, 0);
    } else {
      image.setPixelRgba(
        x,
        y,
        _selectedColor.red,
        _selectedColor.green,
        _selectedColor.blue,
        255,
      );
    }
    setState(() {});
  }

  Future<void> _applyTexture() async {
    if (_selectedTexture == null || _currentImage == null) return;
    final png = Uint8List.fromList(img.encodePng(_currentImage!));
    _service.updateTexture(_selectedTexture!, png);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambios guardados en memoria')),
    );
  }

  Future<void> _closeTexture() async {
    await _applyTexture();
    if (!mounted) return;
    setState(() {
      _selectedTexture = null;
      _currentImage = null;
    });
  }

  Future<void> _exportPack() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await _service.exportPack();
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      setState(() => _error = 'Error al exportar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTexture == null
            ? 'Editor de texturas'
            : _selectedTexture!.split('/').last),
        leading: _selectedTexture != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeTexture,
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_service.hasPack) return _buildWelcome();
    if (_selectedTexture != null) return _buildCanvas();
    return _buildTextureList();
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.brush, size: 96, color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'Abre un paquete de texturas\n(.mcpack o .zip) para editarlo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loading ? null : _pickPack,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            label: Text(_loading ? 'Cargando...' : 'Seleccionar .mcpack'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextureList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_textures.length} texturas · ${_service.modifiedCount} modificadas',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Cambiar pack',
                onPressed: _pickPack,
                icon: const Icon(Icons.folder_open),
              ),
            ],
          ),
        ),
        Expanded(
          child: _textures.isEmpty
              ? const Center(
                  child: Text(
                    'No hay PNGs en este pack.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: _textures.length,
                  itemBuilder: (_, i) {
                    final t = _textures[i];
                    return ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(
                        t.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        t,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => _openTexture(t),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _exportPack,
              icon: const Icon(Icons.save),
              label: const Text('Exportar .mcpack editado'),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildCanvas() {
    final image = _currentImage!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            '${image.width} × ${image.height} px',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PixelCanvas(image: image, onPaintAt: _paintAt),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.black26,
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _EraserChip(
                      selected: _eraser,
                      onTap: () => setState(() => _eraser = true),
                    ),
                    const SizedBox(width: 8),
                    ..._palette.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedColor = c;
                            _eraser = false;
                          }),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (!_eraser && _selectedColor == c)
                                    ? Colors.white
                                    : Colors.white24,
                                width: (!_eraser && _selectedColor == c)
                                    ? 3
                                    : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _applyTexture,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar cambios'),
                  ),
                  TextButton.icon(
                    onPressed: _closeTexture,
                    icon: const Icon(Icons.list),
                    label: const Text('Volver'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EraserChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _EraserChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
        child: const Icon(Icons.cleaning_services, size: 18),
      ),
    );
  }
}