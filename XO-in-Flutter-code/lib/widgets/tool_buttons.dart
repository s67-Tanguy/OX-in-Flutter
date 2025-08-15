import 'package:flutter/material.dart';

class ToolButtons extends StatelessWidget {
  final String selectedTool;
  final bool isGameOver;
  final VoidCallback clearBoard;
  final ValueChanged<String> selectTool;

  const ToolButtons({
    super.key,
    required this.selectedTool,
    required this.isGameOver,
    required this.clearBoard,
    required this.selectTool,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: isGameOver ? null : () => selectTool('O'),
          icon: const Icon(Icons.circle_outlined),
          label: const Text('Draw O'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedTool == 'O' ? Colors.blue.shade100 : null,
            foregroundColor:
                selectedTool == 'O' ? Colors.blue.shade800 : null,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isGameOver ? null : () => selectTool('X'),
          icon: const Icon(Icons.close),
          label: const Text('Draw X'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedTool == 'X' ? Colors.red.shade100 : null,
            foregroundColor:
                selectedTool == 'X' ? Colors.red.shade800 : null,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: clearBoard,
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Clear All'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.grey.shade800,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
