import 'package:flutter/material.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversor')),
      body: const Center(
        child: Text('Próximamente: convertir Bedrock ↔ Java'),
      ),
    );
  }
}