import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'dart:math' as math;

class GridPainter extends CustomPainter {
  final LevelData d; 
  final double s; 
  final bool hasKey; // To show if key is already collected
  GridPainter(this.d, this.s, {this.hasKey = false});

  @override 
  void paint(Canvas c, Size z) {
    Paint b = Paint()..style=PaintingStyle.stroke..color=Colors.white30..strokeWidth=1; 
    Paint st= Paint()..style=PaintingStyle.fill..color=d.color.withOpacity(0.15);
    double g = s*0.05, bx = s-g*2; 
    
    if(d.isDanger) b.color = Colors.redAccent.withOpacity(0.2);

    for(int i=0; i<d.rows*d.cols; i++) {
      if (d.gaps.contains(i)) continue;
      double x = (i%d.cols)*s + g, y = (i~/d.cols)*s + g;
      Offset center = Offset(x+bx/2, y+bx/2);
      
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), const Radius.circular(8)), b);
      if(i==d.start) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), const Radius.circular(8)), st);
        c.drawCircle(center, bx*0.1, Paint()..color=d.color.withOpacity(0.5));
      }

      // Special Tiles
      if(i == d.keyTile && !hasKey) {
        _drawKey(c, center, bx*0.25, d.color);
      } else if(i == d.lockTile) {
        _drawLock(c, center, bx*0.25, hasKey ? Colors.greenAccent : Colors.redAccent);
      } else if(d.oneWayTiles.containsKey(i)) {
        _drawArrow(c, center, bx*0.2, d.oneWayTiles[i]!, d.color);
      } else if(d.portals.containsKey(i)) {
        _drawPortal(c, center, bx*0.3, d.color);
      }
    }
  }

  void _drawKey(Canvas c, Offset center, double radius, Color color) {
    Paint p = Paint()..color=color..style=PaintingStyle.fill;
    c.drawCircle(center.translate(0, -radius*0.3), radius*0.6, p);
    c.drawRect(Rect.fromCenter(center: center.translate(0, radius*0.4), width: radius*0.2, height: radius), p);
    c.drawRect(Rect.fromLTWH(center.dx, center.dy+radius*0.2, radius*0.4, radius*0.15), p);
  }

  void _drawLock(Canvas c, Offset center, double radius, Color color) {
    Paint p = Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=2;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center.translate(0, radius*0.2), width: radius*1.2, height: radius), Radius.circular(radius*0.2)), p);
    c.drawPath(Path()..addArc(Rect.fromCenter(center: center.translate(0, -radius*0.1), width: radius*0.8, height: radius), math.pi, math.pi), p);
  }

  void _drawArrow(Canvas c, Offset center, double radius, Offset dir, Color color) {
    double angle = math.atan2(dir.dy, dir.dx);
    Path path = Path();
    path.moveTo(radius, 0);
    path.lineTo(-radius, -radius*0.8);
    path.lineTo(-radius, radius*0.8);
    path.close();
    
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    c.drawPath(path, Paint()..color=color.withOpacity(0.5)..style=PaintingStyle.fill);
    c.restore();
  }

  void _drawPortal(Canvas c, Offset center, double radius, Color color) {
    Paint p = Paint()..style=PaintingStyle.stroke..color=color.withOpacity(0.6)..strokeWidth=2;
    c.drawCircle(center, radius, p);
    c.drawCircle(center, radius*0.7, p..color=color.withOpacity(0.3));
    final swirlPaint = Paint()..color=color..style=PaintingStyle.fill;
    for(int i=0; i<4; i++) {
      double angle = i * (math.pi/2);
      c.drawCircle(Offset(center.dx + math.cos(angle)*radius, center.dy + math.sin(angle)*radius), 3, swirlPaint);
    }
  }

  @override bool shouldRepaint(covariant GridPainter o)=>o.hasKey != hasKey;
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
    Paint f = Paint()..style=PaintingStyle.fill..color=cl.withOpacity(0.35);
    Paint l = Paint()..style=PaintingStyle.stroke..color=cl..strokeWidth=s*0.2..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    if(!kIsWeb) l.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    Offset gc(int i) => Offset((i%d.cols)*s+s/2, (i~/d.cols)*s+s/2);
    
    for(int i=0; i<p.length-1; i++) {
      int cur = p[i], next = p[i+1];
      int diff = (cur%d.cols - next%d.cols).abs() + (cur~/d.cols - next~/d.cols).abs();
      if(diff == 1) c.drawLine(gc(cur), gc(next), l);
      else {
        c.drawCircle(gc(cur), s*0.1, Paint()..color=cl.withOpacity(0.5));
        c.drawCircle(gc(next), s*0.1, Paint()..color=cl.withOpacity(0.5));
      }
    }
    for (int i in p) {
      double x = (i%d.cols)*s+g, y = (i~/d.cols)*s+g;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), const Radius.circular(10)), f);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bx,bx), const Radius.circular(10)), Paint()..color=cl.withOpacity(0.8)..style=PaintingStyle.stroke..strokeWidth=2);
    }
    double hx = (p.last%d.cols)*s+g, hy=(p.last~/d.cols)*s+g;
    final headPaint = Paint()..color=Colors.white..style=PaintingStyle.fill;
    if(!kIsWeb) headPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    c.drawCircle(Offset(hx+bx/2, hy+bx/2), bx*0.2, headPaint);
  }
  @override bool shouldRepaint(covariant PathPainter o)=>true;
}
