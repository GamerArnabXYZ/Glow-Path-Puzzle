import 'dart:ui';

class LevelData {
  final int id;
  final int rows;
  final int cols;
  final int start;
  final Color color;
  final Set<int> gaps;
  final Map<int, int> portals; // id1 -> id2, id2 -> id1
  final bool isDanger;

  LevelData(
    this.id, 
    this.rows, 
    this.cols, 
    this.start, 
    this.color, 
    this.gaps, 
    {this.portals = const {}, this.isDanger = false}
  );
}
