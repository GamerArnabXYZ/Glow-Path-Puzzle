import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LevelGenerator {
  static Future<LevelData> generate(int levelIndex, {int stage = 0}) async {
    int seedBase = (levelIndex * 70000) + (stage * 9999); 
    int attempts = 0;
    bool isDanger = (levelIndex + 1) % 10 == 0;

    while (true) {
      Random rng = Random(seedBase + attempts);
      LevelData? candidate = _tryGen(levelIndex, rng, isDanger);
      if (candidate != null) return candidate;
      attempts++; 
      if (attempts % 10 == 0) await Future.delayed(Duration.zero);
      if (attempts > 100) { seedBase += rng.nextInt(1000); attempts = 0; }
    }
  }

  static LevelData? _tryGen(int idx, Random rng, bool isDanger) {
    int rows = 3, cols = 3;
    if(idx>=5){rows=4;cols=3;} if(idx>=9){rows=4;cols=4;} if(idx>=25){rows=5;cols=4;}
    if(idx>=40){rows=6;cols=5;} if(idx>=80){rows=6;cols=6;}
    if(isDanger){rows=5;cols=5;} if(isDanger&&idx>=19){rows=6;cols=6;}

    int maxGaps = (idx > 5) ? 1 : 0;
    if(isDanger) maxGaps = (rows*cols)~/3; 
    if(idx > 50) maxGaps = 4;

    int gapCount = maxGaps > 0 ? rng.nextInt(maxGaps + 1) : 0;
    if(isDanger && gapCount<3) gapCount=3+rng.nextInt(3);

    Color color = getColor(idx);
    int total=rows*cols; int start=rng.nextInt(total); Set<int> gaps={};
    int ax=0;
    while(gaps.length<gapCount && ax<200){
      int g=rng.nextInt(total);
      if(g!=start && !gaps.contains(g)) { if(!_isol(g,start,rows,cols,gaps)) gaps.add(g); }
      ax++;
    }

    Map<int, int> portals = {};
    if (idx >= 14 && rng.nextDouble() < 0.3) {
      List<int> avail = _getAvail(total, start, gaps);
      if(avail.length >= 2) {
        avail.shuffle(rng);
        int p1 = avail[0], p2 = avail[1];
        portals[p1] = p2; portals[p2] = p1;
      }
    }

    int? key, lock;
    if (idx >= 20 && rng.nextDouble() < 0.4) {
      List<int> avail = _getAvail(total, start, gaps, exclude: portals.keys.toSet());
      if(avail.length >= 2) {
        avail.shuffle(rng);
        key = avail[0]; lock = avail[1];
      }
    }

    Map<int, Offset> oneWays = {};
    if (idx >= 30 && rng.nextDouble() < 0.3) {
      List<int> avail = _getAvail(total, start, gaps, exclude: {...portals.keys, if(key!=null) key, if(lock!=null) lock});
      if(avail.isNotEmpty) {
        int t = avail[rng.nextInt(avail.length)];
        List<Offset> dirs = [const Offset(0,1), const Offset(0,-1), const Offset(1,0), const Offset(-1,0)];
        dirs.shuffle(rng);
        for(var d in dirs) {
          int r = t~/cols + d.dy.toInt(), c = t%cols + d.dx.toInt();
          if(r>=0 && r<rows && c>=0 && c<cols) { oneWays[t] = d; break; }
        }
      }
    }

    int targetSize = total - gaps.length;
    var sol = Solver.solve(rows, cols, start, {start}, gaps, targetSize, portals, keyTile: key, lockTile: lock, oneWays: oneWays, limit: 3000);
    if(sol != null) return LevelData(idx+1, rows, cols, start, color, gaps, portals: portals, keyTile: key, lockTile: lock, oneWays: oneWays, isDanger: isDanger);
    
    return null;
  }

  static List<int> _getAvail(int total, int start, Set<int> gaps, {Set<int>? exclude}) {
    List<int> a = [];
    for(int i=0; i<total; i++) if(i!=start && !gaps.contains(i) && (exclude==null || !exclude.contains(i))) a.add(i);
    return a;
  }
  
  static bool _isol(int h, int s, int r, int c, Set<int> gaps) {
    var neighbors = getNeighbors(s, r, c);
    return neighbors.every((n) => n == h || gaps.contains(n));
  }

  static Color getColor(int idx) {
    bool isDanger = (idx + 1) % 10 == 0;
    if (isDanger) return const Color(0xFFFF1744);
    return [Colors.cyanAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.greenAccent, Colors.pinkAccent, Colors.amberAccent, const Color(0xFF00E5FF), const Color(0xFFD500F9)][idx % 8];
  }

  static List<int> getNeighbors(int x, int r, int c, {Map<int, int>? portals, Map<int, Offset>? oneWays}) {
    if(oneWays != null && oneWays.containsKey(x)) {
      Offset d = oneWays[x]!;
      int row = x~/c + d.dy.toInt(), col = x%c + d.dx.toInt();
      if(row>=0 && row<r && col>=0 && col<c) return [row*c + col];
      return [];
    }
    List<int>n=[]; int R=x~/c,C=x%c;
    if(R>0)n.add((R-1)*c+C); if(R<r-1)n.add((R+1)*c+C);
    if(C>0)n.add(R*c+C-1); if(C<c-1)n.add(R*c+C+1);
    if(portals != null && portals.containsKey(x)) {
      int p = portals[x]!;
      if (!n.contains(p)) n.add(p);
    }
    return n;
  }
}

class Solver {
  static int _steps = 0;
  static List<int>? solve(int r, int c, int cur, Set<int> vis, Set<int> gaps, int targetSize, Map<int, int> portals, {int? keyTile, int? lockTile, Map<int, Offset>? oneWays, int limit = 10000}) {
    _steps = 0;
    return _solveInternal(r, c, cur, vis, gaps, targetSize, portals, keyTile, lockTile, oneWays, limit);
  }

  static List<int>? _solveInternal(int r, int c, int cur, Set<int> vis, Set<int> gaps, int targetSize, Map<int, int> portals, int? key, int? lock, Map<int, Offset>? oneWays, int limit) {
    _steps++; if(_steps > limit) return null;
    if(vis.length == targetSize) return vis.toList();
    
    List<int> nbs = LevelGenerator.getNeighbors(cur, r, c, portals: portals, oneWays: oneWays);
    List<MapEntry<int, int>> sorted = [];
    for(int next in nbs) {
      if(!vis.contains(next) && !gaps.contains(next)) {
        if(next == lock && !vis.contains(key!)) continue; // Lock is blocked
        int degree = 0;
        var nn = LevelGenerator.getNeighbors(next, r, c, portals: portals, oneWays: oneWays);
        for(int nb in nn) if(!vis.contains(nb) && !gaps.contains(nb)) degree++;
        sorted.add(MapEntry(next, degree));
      }
    }
    sorted.sort((a, b) => a.value.compareTo(b.value));

    for(var entry in sorted) {
      int next = entry.key; vis.add(next);
      bool dead = false;
      for(int nb in nbs) {
        if(!vis.contains(nb) && !gaps.contains(nb)) {
          if(nb == lock && !vis.contains(key!)) continue; 
          var nnn = LevelGenerator.getNeighbors(nb, r, c, portals: portals, oneWays: oneWays);
          int free = 0;
          for(int f in nnn) if(!vis.contains(f) && !gaps.contains(f)) free++;
          if(free == 0 && vis.length < targetSize) { dead = true; break; }
        }
      }
      if(!dead) {
        var res = _solveInternal(r, c, next, vis, gaps, targetSize, portals, key, lock, oneWays, limit);
        if(res != null) return res;
      }
      vis.remove(next);
    }
    return null;
  }
}

class GameStorage {
  static const String kLvl = 'gp_18_lvl'; 
  static const String kStars = 'gp_18_stars';
  static const String kHints = 'gp_hint_count';
  static const String kSetMusic = 'gp_set_music';
  static const String kSetSfx = 'gp_set_sfx_v2';
  static const String kSetVib = 'gp_set_vib';
  static Future<int> getMaxLevel() async { var p = await SharedPreferences.getInstance(); return p.getInt(kLvl) ?? 1; }
  static Future<Map<String, int>> getStars() async {
    var p = await SharedPreferences.getInstance();
    String? str = p.getString(kStars); return str == null ? {} : Map<String, int>.from(jsonDecode(str));
  }
  static Future<void> saveProgress(int lvl, int stars) async {
    var p = await SharedPreferences.getInstance();
    int cur = p.getInt(kLvl) ?? 1; if ((lvl+2)>cur) await p.setInt(kLvl, lvl+2);
    Map<String, int> sm = await getStars();
    if (stars > (sm[lvl.toString()]??0)) { sm[lvl.toString()]=stars; await p.setString(kStars, jsonEncode(sm)); }
  }
  static Future<int> getHints() async { var p = await SharedPreferences.getInstance(); return p.getInt(kHints) ?? 5; }
  static Future<void> useHint() async { var p = await SharedPreferences.getInstance(); int c=p.getInt(kHints)??5; if(c>0)await p.setInt(kHints,c-1); }
  static Future<void> addHints(int a) async { var p = await SharedPreferences.getInstance(); int c=p.getInt(kHints)??5; await p.setInt(kHints, c+a); }
  static Future<double> getMusicVol() async => (await SharedPreferences.getInstance()).getDouble(kSetMusic) ?? 1.0;
  static Future<double> getSfxVol() async => (await SharedPreferences.getInstance()).getDouble(kSetSfx) ?? 1.0;
  static Future<bool> getVibration() async => (await SharedPreferences.getInstance()).getBool(kSetVib) ?? true;
  static Future<void> setMusicVol(double v) async => (await SharedPreferences.getInstance()).setDouble(kSetMusic, v);
  static Future<void> setSfxVol(double v) async => (await SharedPreferences.getInstance()).setDouble(kSetSfx, v);
  static Future<void> setVibration(bool v) async => (await SharedPreferences.getInstance()).setBool(kSetVib, v);
}
