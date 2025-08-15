import 'package:flutter/material.dart';

/// บอกว่าจะวาด x หรือ o ที่ตำแหน่งไหน
class Mark {
  final Offset position;
  final String type; // 'O' or 'X'
  final int row;
  final int col;

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
