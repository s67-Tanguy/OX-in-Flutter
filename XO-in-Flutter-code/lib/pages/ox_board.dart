import 'package:flutter/material.dart';
import '../models/mark.dart';
import '../painters/board_painter.dart';
import '../widgets/tool_buttons.dart';

class OXBoard extends StatefulWidget {
  const OXBoard({super.key});

  @override
  State<OXBoard> createState() => _OXBoardState();
}

class _OXBoardState extends State<OXBoard> {
  List<Mark> _marks = <Mark>[];
  String _selectedTool = 'O';
  bool _isGameOver = false;
  String? _winnerType;

  static const double _markSize = 100.0;
  static const int _gridSize = 3;
  static const String _emptyCell = '-';

  List<String> _getMovesList() {
    final int n = _gridSize;
    List<String> moves = List<String>.filled(n * n, _emptyCell);

    for (final Mark mark in _marks) {
      moves[mark.row * n + mark.col] = mark.type;
    }
    return moves;
  }

  bool _checkWinner() {
    final int n = _gridSize;
    final List<String> moves = _getMovesList();

    // Check rows
    for (int r = 0; r < n; r++) {
      String first = moves[r * n];
      if (first != _emptyCell &&
          List.generate(n, (c) => moves[r * n + c]).every((v) => v == first)) {
        return true;
      }
    }

    // Check columns
    for (int c = 0; c < n; c++) {
      String first = moves[c];
      if (first != _emptyCell &&
          List.generate(n, (r) => moves[r * n + c]).every((v) => v == first)) {
        return true;
      }
    }

    // Main diagonal
    if (moves[0] != _emptyCell &&
        List.generate(n, (i) => moves[i * (n + 1)]).every((v) => v == moves[0])) {
      return true;
    }

    // Anti-diagonal
    if (moves[n - 1] != _emptyCell &&
        List.generate(n, (i) => moves[i * n + (n - 1 - i)])
            .every((v) => v == moves[n - 1])) {
      return true;
    }

    return false;
  }

  void _showWinnerDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Game Over!'),
          content: Text('Player "${_winnerType!}" wins!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _clearBoard();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _showDrawDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Game Over!'),
          content: const Text('It\'s a Draw!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _clearBoard();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _handleTap(Offset localPosition, Size boardSize) {
    if (_isGameOver) return;

    final double cellWidth = boardSize.width / _gridSize;
    final double cellHeight = boardSize.height / _gridSize;

    final int col = (localPosition.dx / cellWidth).floor();
    final int row = (localPosition.dy / cellHeight).floor();

    if (_marks.any((Mark mark) => mark.row == row && mark.col == col)) return;

    final Offset cellCenterPosition = Offset(
      col * cellWidth + (cellWidth / 2),
      row * cellHeight + (cellHeight / 2),
    );

    setState(() {
      _marks.add(Mark(
        position: cellCenterPosition,
        type: _selectedTool,
        row: row,
        col: col,
      ));

      if (_checkWinner()) {
        _isGameOver = true;
        _winnerType = _selectedTool;
        _showWinnerDialog();
      } else if (_marks.length == _gridSize * _gridSize) {
        _isGameOver = true;
        _winnerType = null;
        _showDrawDialog();
      }
    });
  }

  void _selectTool(String tool) {
    if (!_isGameOver) {
      setState(() {
        _selectedTool = tool;
      });
    }
  }

  void _clearBoard() {
    setState(() {
      _marks.clear();
      _isGameOver = false;
      _winnerType = null;
      _selectedTool = 'O';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OX Board'), centerTitle: true),
      body: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size boardSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(
                  onTapDown: (details) {
                    final RenderBox? box =
                        context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final Offset localPos =
                          box.globalToLocal(details.globalPosition);
                      _handleTap(localPos, boardSize);
                    }
                  },
                  child: CustomPaint(
                    size: boardSize,
                    painter: BoardPainter(
                      marks: _marks,
                      markSize: _markSize,
                      gridSize: _gridSize,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ToolButtons(
              selectedTool: _selectedTool,
              isGameOver: _isGameOver,
              clearBoard: _clearBoard,
              selectTool: _selectTool,
            ),
          ),
        ],
      ),
    );
  }
}
