import 'dart:ui';

class LevelData {
  final int id;
  final int rows;
  final int cols;
  final int start;
  final Color color;
  final Set<int> gaps;
  final bool isDanger;

  LevelData(
    this.id, 
    this.rows, 
    this.cols, 
    this.start, 
    this.color, 
    this.gaps, 
    {this.isDanger = false}
  );
}