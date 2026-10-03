import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de texturas')),
      body: const Center(
        child: Text('Próximamente: editar PNGs de bloques e ítems'),
      ),
    );
  }
}