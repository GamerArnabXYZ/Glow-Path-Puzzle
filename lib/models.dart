import 'dart:ui';
import 'package:flutter/material.dart';

class LevelData {
  final int id;
  final int rows;
  final int cols;
  final int start;
  final Color color;
  final Set<int> gaps;
  final Map<int, int> portals; // id1 -> id2
  final int? keyTile;
  final int? lockTile;
  final Map<int, Offset> oneWayTiles; // id -> direction vector (dx, dy)
  final bool isDanger;

  LevelData(
    this.id, 
    this.rows, 
    this.cols, 
    this.start, 
    this.color, 
    this.gaps, 
    {
      this.portals = const {}, 
      this.keyTile,
      this.lockTile,
      this.oneWayTiles = const {},
      this.isDanger = false
    }
  );
}
