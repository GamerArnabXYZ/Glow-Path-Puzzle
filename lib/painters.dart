import 'package:flutter/material.dart';
import 'models.dart';

class GridPainter extends CustomPainter {
  final LevelData d; 
  final double s; 
  GridPainter(this.d, this.s);

  @override 
  void paint(Canvas c, Size z) {
    Paint b = Paint()..style=PaintingStyle.stroke..color=Colors.white10; 
    Paint st= Paint()..style=PaintingStyle.fill..color=d.color.withOpacity(0.2);
    double g = s*0.05, bx = s-g*2; 
    
    if(d.isDanger) b.color = Colors.redAccent.withOpacity(0.3);

    for(int i=0; i<d.rows*d.cols; i++) {
      if (d.gaps.contains(i)) continue;
      double x = (i%d.cols)*s + g, y = (i~/d.cols)*s + g;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), Radius.circular(4)), b);
      if(i==d.start) c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), Radius.circular(4)), st);
    }
  }
  @override bool shouldRepaint(covariant GridPainter o)=>false;
}

class PathPainter extends CustomPainter {
  final List<int> p; 
  final LevelData d; 
  final double s; 
  PathPainter(this.p, this.d, this.s);

  @override 
  void paint(Canvas c, Size z) {
    if (p.isEmpty) return; 
    double g=s*0.05, bx=s-g*2; 
    Color cl=d.color;
    
    Paint f = Paint()..style=PaintingStyle.fill..color=cl.withOpacity(0.4);
    Paint l = Paint()..style=PaintingStyle.stroke..color=cl..strokeWidth=s*0.15..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    Offset gc(int i) => Offset((i%d.cols)*s+s/2, (i~/d.cols)*s+s/2);
    
    for(int i=0; i<p.length-1; i++) c.drawLine(gc(p[i]), gc(p[i+1]), l);
    
    for (int i in p) {
      double x = (i%d.cols)*s+g, y = (i~/d.cols)*s+g;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), Radius.circular(6)), f);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), Radius.circular(6)), Paint()..color=cl.withOpacity(0.8)..style=PaintingStyle.stroke..strokeWidth=1.5);
    }
    
    double hx = (p.last%d.cols)*s+g, hy=(p.last~/d.cols)*s+g;
    c.drawRect(Rect.fromLTWH(hx+bx*0.35, hy+bx*0.35, bx*0.3, bx*0.3), Paint()..color=Colors.white);
  }
  @override bool shouldRepaint(covariant PathPainter o)=>true;
}