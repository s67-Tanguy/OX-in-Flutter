import 'package:flutter/material.dart';
import 'dart:math' as math; // Import for math.pi

void main() {
  runApp(const MaterialApp(home: OXBoard(), debugShowCheckedModeBanner: false));
}

/// A class representing a mark (X or O) on the board.
/// It stores the position, type ('O' or 'X'), and grid coordinates.
class Mark {
  final Offset position;
  final String type; // 'O' or 'X'
  final int row; // Row index of the cell this mark occupies
  final int col; // Column index of the cell this mark occupies

  Mark({
    required this.position,
    required this.type,
    required this.row,
    required this.col,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mark &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          type == other.type &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode =>
      position.hashCode ^ type.hashCode ^ row.hashCode ^ col.hashCode;
}

/// The main OX board widget, managing game state and animations.
class OXBoard extends StatefulWidget {
  const OXBoard({super.key});

  @override
  State<OXBoard> createState() => _OXBoardState();
}

class _OXBoardState extends State<OXBoard> with TickerProviderStateMixin {
  // A list to store the marks (x or o)
  List<Mark> _marks = <Mark>[];
  // The currently selected tool for drawing
  String _selectedTool = 'O';

  // Game state variables
  bool _isGameOver = false;
  String? _winnerType; // 'O', 'X', or null if draw/no winner yet

  // Animation variables for the 'O' mark
  AnimationController? _oAnimationController;
  Animation<double>? _oAnimation;
  Mark? _currentAnimatingOMark; // Stores the 'O' mark currently being animated

  // Animation variables for the 'X' mark
  AnimationController? _xAnimationController;
  Animation<double>? _xAnimation;
  Mark? _currentAnimatingXMark; // Stores the 'X' mark currently being animated

  static const double _markSize = 100.0;
  static const int _gridSize = 3; // Define grid size consistently
  static const String _emptyCell = '-'; // Placeholder for an empty cell

  @override
  void dispose() {
    _oAnimationController
        ?.dispose(); // Dispose the 'O' controller when the widget is disposed
    _xAnimationController
        ?.dispose(); // Dispose the 'X' controller when the widget is disposed
    super.dispose();
  }

  /// Converts the current [_marks] list into a 1D list representing the grid state.
  List<String> _getMovesList() {
    final int n = _gridSize;
    List<String> moves = List<String>.filled(n * n, _emptyCell);

    for (final Mark mark in _marks) {
      moves[mark.row * n + mark.col] = mark.type;
    }
    return moves;
  }

  /// Checks for a winning combination in an N x N grid.
  bool _checkWinner() {
    final int n = _gridSize;
    final List<String> moves = _getMovesList();

    // Check rows
    for (int r = 0; r < n; r++) {
      String first = moves[r * n];
      if (first != _emptyCell) {
        bool rowWin = true;
        for (int c = 1; c < n; c++) {
          if (moves[r * n + c] != first) {
            rowWin = false;
            break;
          }
        }
        if (rowWin) {
          _winnerType = first; // Set winner type
          return true;
        }
      }
    }

    // Check columns
    for (int c = 0; c < n; c++) {
      String first = moves[c]; // Top element of the column
      if (first != _emptyCell) {
        bool colWin = true;
        for (int r = 1; r < n; r++) {
          if (moves[r * n + c] != first) {
            colWin = false;
            break;
          }
        }
        if (colWin) {
          _winnerType = first; // Set winner type
          return true;
        }
      }
    }

    // Check main diagonal (top-left to bottom-right)
    String firstDiagonal1 = moves[0];
    if (firstDiagonal1 != _emptyCell) {
      bool diag1Win = true;
      for (int i = 1; i < n; i++) {
        if (moves[i * (n + 1)] != firstDiagonal1) {
          diag1Win = false;
          break;
        }
      }
      if (diag1Win) {
        _winnerType = firstDiagonal1; // Set winner type
        return true;
      }
    }

    // Check anti-diagonal (top-right to bottom-left)
    String firstDiagonal2 = moves[n - 1]; // Top-right element
    if (firstDiagonal2 != _emptyCell) {
      bool diag2Win = true;
      for (int i = 1; i < n; i++) {
        // Index for anti-diagonal: i * n + (n - 1 - i)
        if (moves[i * n + (n - 1 - i)] != firstDiagonal2) {
          diag2Win = false;
          break;
        }
      }
      if (diag2Win) {
        _winnerType = firstDiagonal2; // Set winner type
        return true;
      }
    }

    return false;
  }

  /// Displays an alert dialog when a player wins.
  void _showWinnerDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Game Over!'),
          content: Text('Player "${_winnerType!}" wins!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                _clearBoard(); // Reset game after dismissal
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  /// Displays an alert dialog when the game ends in a draw.
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

  /// Handles a tap down event on the drawing area.
  /// Converts the global tap position to a local position relative to the CustomPaint
  /// and adds a new Mark to the list, placing it at the center of the tapped grid cell.
  /// If the cell is already occupied, don't draw a new mark.
  void _handleTap(Offset localPosition, Size boardSize) {
    if (_isGameOver) {
      // Do not allow placing marks if the game is over
      return;
    }

    // Calculate cell dimensions
    final double cellWidth = boardSize.width / _gridSize;
    final double cellHeight = boardSize.height / _gridSize;

    // Determine which cell was tapped
    final int col = (localPosition.dx / cellWidth).floor();
    final int row = (localPosition.dy / cellHeight).floor();

    // Check if a mark already exists in the tapped cell
    final bool cellOccupied = _marks.any(
      (Mark mark) => mark.row == row && mark.col == col,
    );

    // If the cell is marked, do not draw a new mark.
    if (cellOccupied) {
      return;
    }

    // Calculate the center of the tapped cell
    final double centerX = col * cellWidth + (cellWidth / 2);
    final double centerY = row * cellHeight + (cellHeight / 2);

    final Offset cellCenterPosition = Offset(centerX, centerY);

    setState(() {
      final Mark newMark = Mark(
        position: cellCenterPosition,
        type: _selectedTool,
        row: row,
        col: col,
      );

      // Stop and dispose any *other* ongoing animation before starting a new one.
      // This ensures only one mark animates at a time.
      if (newMark.type == 'O') {
        _xAnimationController?.stop();
        _xAnimationController?.dispose();
        _xAnimationController = null;
        _xAnimation = null;
        _currentAnimatingXMark = null; // Clear X's animating mark
      } else {
        // newMark.type == 'X'
        _oAnimationController?.stop();
        _oAnimationController?.dispose();
        _oAnimationController = null;
        _oAnimation = null;
        _currentAnimatingOMark = null; // Clear O's animating mark
      }

      _marks = List<Mark>.from(_marks)..add(newMark);

      // Handle 'O' animation
      if (newMark.type == 'O') {
        _currentAnimatingOMark = newMark;
        _oAnimationController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        _oAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(_oAnimationController!);

        _oAnimationController!.addListener(() {
          setState(() {
            // No-op, just rebuilds the UI
          });
        });

        _oAnimationController!.forward().whenCompleteOrCancel(() {
          // Animation finished, ensure current animating mark is cleared
          if (_currentAnimatingOMark == newMark) {
            setState(() {
              _currentAnimatingOMark = null;
            });
          }
        });
      } else {
        // Handle 'X' animation
        _currentAnimatingXMark = newMark;
        _xAnimationController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        _xAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(_xAnimationController!);

        _xAnimationController!.addListener(() {
          setState(() {
            // No-op, just rebuilds the UI
          });
        });

        _xAnimationController!.forward().whenCompleteOrCancel(() {
          if (_currentAnimatingXMark == newMark) {
            setState(() {
              _currentAnimatingXMark = null;
            });
          }
        });
      }

      if (_checkWinner()) {
        _isGameOver = true;
        _oAnimationController?.stop(); // Stop O animation on game over
        _xAnimationController?.stop(); // Stop X animation on game over
        _showWinnerDialog();
      } else if (_marks.length == _gridSize * _gridSize) {
        // All cells are filled, and no winner, so it's a draw
        _isGameOver = true;
        _winnerType = null; // Indicate a draw
        _oAnimationController?.stop(); // Stop O animation on game over
        _xAnimationController?.stop(); // Stop X animation on game over
        _showDrawDialog();
      }
    });
  }

  /// Sets the currently selected drawing tool ('O' or 'X').
  void _selectTool(String tool) {
    if (_isGameOver) {
      return; // Cannot change tool if game is over
    }
    setState(() {
      _selectedTool = tool;
    });
  }

  /// Clears all drawn marks from the board and resets game state.
  void _clearBoard() {
    setState(() {
      _marks = <Mark>[]; // Create a new empty list instance to clear the board.
      _isGameOver = false;
      _winnerType = null;
      _selectedTool = 'O'; // Reset selected tool to default

      _oAnimationController?.dispose(); // Dispose any ongoing 'O' animation
      _oAnimationController = null;
      _oAnimation = null;
      _currentAnimatingOMark = null;

      _xAnimationController?.dispose(); // Dispose any ongoing 'X' animation
      _xAnimationController = null;
      _xAnimation = null;
      _currentAnimatingXMark = null;
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
              builder: (BuildContext context, BoxConstraints constraints) {
                // Determine the size available for the custom paint area.
                final Size boardSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    // Find the render box of the current context to convert global to local coordinates.
                    final RenderBox? box =
                        context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final Offset localPos = box.globalToLocal(
                        details.globalPosition,
                      );
                      // Pass boardSize to _handleTap so it can calculate cell centers
                      _handleTap(localPos, boardSize);
                    }
                  },
                  child: CustomPaint(
                    size: boardSize,
                    painter: BoardPainter(
                      marks: _marks,
                      markSize: _markSize,
                      gridSize: _gridSize,
                      animatingOMark: _currentAnimatingOMark,
                      animationValue:
                          _oAnimation?.value, // Pass current O animation value
                      animatingXMark:
                          _currentAnimatingXMark, // Pass current X animating mark
                      xAnimationValue:
                          _xAnimation?.value, // Pass current X animation value
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _isGameOver ? null : () => _selectTool('O'),
                  icon: const Icon(Icons.circle_outlined),
                  label: const Text('Draw O'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTool == 'O'
                        ? Colors.blue.shade100
                        : null,
                    foregroundColor: _selectedTool == 'O'
                        ? Colors.blue.shade800
                        : null,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isGameOver ? null : () => _selectTool('X'),
                  icon: const Icon(Icons.close),
                  label: const Text('Draw X'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTool == 'X'
                        ? Colors.red.shade100
                        : null,
                    foregroundColor: _selectedTool == 'X'
                        ? Colors.red.shade800
                        : null,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearBoard,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade800,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A CustomPainter for drawing the NxN grid and all the 'O' and 'X' marks.
class BoardPainter extends CustomPainter {
  final List<Mark> marks;
  final double markSize;
  final int gridSize;
  final Mark? animatingOMark; // The 'O' mark currently being animated
  final double? animationValue; // The current O animation progress (0.0 to 1.0)
  final Mark? animatingXMark; // The 'X' mark currently being animated
  final double?
  xAnimationValue; // The current X animation progress (0.0 to 1.0)

  BoardPainter({
    required this.marks,
    required this.markSize,
    required this.gridSize,
    this.animatingOMark,
    this.animationValue,
    this.animatingXMark,
    this.xAnimationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cellWidth = size.width / gridSize;
    final double cellHeight = size.height / gridSize;

    // Draw vertical grid lines
    for (int i = 1; i < gridSize; i++) {
      final double x = cellWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal grid lines
    for (int i = 1; i < gridSize; i++) {
      final double y = cellHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Paint for 'O'
    final Paint oPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Paint for 'X'
    final Paint xPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Draw each 'O' and 'X' mark based on its stored position and type
    for (final Mark mark in marks) {
      if (mark.type == 'O') {
        if (mark == animatingOMark && animationValue != null) {
          // Draw animated 'O' as an arc
          // Starting angle: -math.pi/2 (top center)
          // Sweep angle: ranges from 0 to 2*math.pi based on animationValue
          final double sweepAngle = 2 * math.pi * animationValue!;
          final Rect rect = Rect.fromCircle(
            center: mark.position,
            radius: markSize / 2,
          );
          canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, oPaint);
        } else {
          // Draw static 'O' (already completed animation or not currently animating)
          canvas.drawCircle(mark.position, markSize / 2, oPaint);
        }
      } else if (mark.type == 'X') {
        final double halfSize = markSize / 2;
        if (mark == animatingXMark && xAnimationValue != null) {
          // Animation for 'X'
          final Offset p1Start = mark.position + Offset(-halfSize, -halfSize);
          final Offset p1End = mark.position + Offset(halfSize, halfSize);
          final Offset p2Start = mark.position + Offset(-halfSize, halfSize);
          final Offset p2End = mark.position + Offset(halfSize, -halfSize);

          // Animation for the first line (0.0 to 0.5 of total animation)
          final double progress1 = (xAnimationValue! * 2).clamp(0.0, 1.0);
          final Offset p1AnimatedEnd = Offset.lerp(p1Start, p1End, progress1)!;
          canvas.drawLine(p1Start, p1AnimatedEnd, xPaint);

          // Animation for the second line (0.5 to 1.0 of total animation)
          final double progress2 = ((xAnimationValue! - 0.5) * 2).clamp(
            0.0,
            1.0,
          );
          if (progress2 > 0) {
            // Only draw the second line if its animation has started
            final Offset p2AnimatedEnd = Offset.lerp(
              p2Start,
              p2End,
              progress2,
            )!;
            canvas.drawLine(p2Start, p2AnimatedEnd, xPaint);
          }
        } else {
          // Draw static 'X' (already completed animation or not currently animating)
          // Adjust line drawing to be centered around mark.position
          canvas.drawLine(
            mark.position + Offset(-halfSize, -halfSize),
            mark.position + Offset(halfSize, halfSize),
            xPaint,
          );
          canvas.drawLine(
            mark.position + Offset(-halfSize, halfSize),
            mark.position + Offset(halfSize, -halfSize),
            xPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // Repaint if the list of marks changes (new mark added/removed),
    // or if markSize/gridSize change,
    // or if the currently animating 'O' mark changes,
    // or if the animation progress value changes.
    return oldDelegate.marks != marks ||
        oldDelegate.markSize != markSize ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.animatingOMark != animatingOMark ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.animatingXMark != animatingXMark ||
        oldDelegate.xAnimationValue != xAnimationValue;
  }
}
