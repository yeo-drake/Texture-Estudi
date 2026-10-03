import 'package:flutter/material.dart';

class HoloPrintScreen extends StatelessWidget {
  const HoloPrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HoloPrint')),
      body: const Center(
        child: Text('Próximamente: generar hologramas desde .mcstructure'),
      ),
    );
  }
}