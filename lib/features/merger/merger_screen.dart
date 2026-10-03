import 'package:flutter/material.dart';

class MergerScreen extends StatelessWidget {
  const MergerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fusionar packs')),
      body: const Center(
        child: Text('Próximamente: fusionar dos o más .mcpack'),
      ),
    );
  }
}