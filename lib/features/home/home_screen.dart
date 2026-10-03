import 'package:flutter/material.dart';
import '../editor/editor_screen.dart';
import '../converter/converter_screen.dart';
import '../holoprint/holoprint_screen.dart';
import '../merger/merger_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem('Editor de texturas', Icons.brush, const EditorScreen()),
      _MenuItem('Conversor', Icons.swap_horiz, const ConverterScreen()),
      _MenuItem('HoloPrint', Icons.view_in_ar, const HoloPrintScreen()),
      _MenuItem('Fusionar packs', Icons.merge, const MergerScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Texture Studio'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: items.map((item) {
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.screen),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 48),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  _MenuItem(this.title, this.icon, this.screen);
}