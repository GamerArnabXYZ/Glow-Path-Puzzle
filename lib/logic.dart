import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LevelGenerator {
  static LevelData generate(int levelIndex, {int stage = 0}) {
    int seedBase = (levelIndex * 70000) + (stage * 9999); 
    int attempts = 0;
    bool isDanger = (levelIndex + 1) % 10 == 0;

    while (true) {
      Random rng = Random(seedBase + attempts);
      LevelData? candidate = _tryGen(levelIndex, rng, isDanger);
      if (candidate != null) return candidate;
      attempts++; 
      // If we can't find a solution in 100 seeds, something is too hard, skip seed base
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

    Color color = isDanger ? const Color(0xFFFF1744) : [Colors.cyanAccent, Colors.orangeAccent, Colors.purpleAccent,Colors.greenAccent, Colors.pinkAccent, Colors.amberAccent,const Color(0xFF00E5FF), const Color(0xFFD500F9)][idx % 8];

    int total=rows*cols; int start=rng.nextInt(total); Set<int> gaps={};
    int ax=0;
    while(gaps.length<gapCount && ax<200){
      int g=rng.nextInt(total);
      if(g!=start && !gaps.contains(g)) { if(!_isol(g,start,rows,cols,gaps)) gaps.add(g); }
      ax++;
    }

    Map<int, int> portals = {};
    if (idx >= 14 && rng.nextDouble() < 0.4) {
      List<int> available = [];
      for(int i=0; i<total; i++) if(i!=start && !gaps.contains(i)) available.add(i);
      if(available.length >= 2) {
        available.shuffle(rng);
        int p1 = available[0], p2 = available[1];
        portals[p1] = p2; portals[p2] = p1;
      }
    }

    int targetSize = total - gaps.length;
    // Pre-check: All non-gap tiles must have at least one reachable non-gap neighbor
    for(int i=0; i<total; i++) {
      if(!gaps.contains(i)) {
        var nbs = getNeighbors(i, rows, cols, portals: portals);
        if(nbs.every((nb) => gaps.contains(nb)) && targetSize > 1) return null;
      }
    }

    // Solve with complexity limit (max 2000 steps)
    var sol = Solver.solve(rows, cols, start, {start}, gaps, targetSize, portals, limit: 2000);
    if(sol != null) return LevelData(idx+1, rows, cols, start, color, gaps, portals: portals, isDanger: isDanger);
    
    return null;
  }
  
  static bool _isol(int h, int s, int r, int c, Set<int> gaps) {
    var neighbors = getNeighbors(s, r, c);
    return neighbors.every((n) => n == h || gaps.contains(n));
  }

  static List<int> getNeighbors(int x, int r, int c, {Map<int, int>? portals}) {
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

  static List<int>? solve(int r, int c, int cur, Set<int> vis, Set<int> gaps, int targetSize, Map<int, int> portals, {int limit = 10000}) {
    _steps = 0;
    return _solveInternal(r, c, cur, vis, gaps, targetSize, portals, limit);
  }

  static List<int>? _solveInternal(int r, int c, int cur, Set<int> vis, Set<int> gaps, int targetSize, Map<int, int> portals, int limit) {
    _steps++;
    if(_steps > limit) return null; // Early exit if too complex
    if(vis.length == targetSize) return vis.toList();
    
    List<int> neighbors = LevelGenerator.getNeighbors(cur, r, c, portals: portals);
    
    // Warnsdorff's Heuristic: Sort neighbors by their degree (number of available unvisited neighbors)
    // Tiles with fewer available neighbors should be visited first to avoid isolating them.
    List<MapEntry<int, int>> sorted = [];
    for(int next in neighbors) {
      if(!vis.contains(next) && !gaps.contains(next)) {
        int degree = 0;
        var nextNeighbors = LevelGenerator.getNeighbors(next, r, c, portals: portals);
        for(int nb in nextNeighbors) {
          if(!vis.contains(nb) && !gaps.contains(nb)) degree++;
        }
        sorted.add(MapEntry(next, degree));
      }
    }

    // Sort by degree ascending
    sorted.sort((a, b) => a.value.compareTo(b.value));

    for(var entry in sorted) {
      int next = entry.key;
      vis.add(next);
      
      // Fast connectivity check: if any unvisited tile (other than the goal) has 0 neighbors, it's a dead end
      bool deadEnd = false;
      // We only need to check neighbors of 'cur' that were NOT chosen as 'next'
      for(int nb in neighbors) {
        if(!vis.contains(nb) && !gaps.contains(nb)) {
          var nbsOfNb = LevelGenerator.getNeighbors(nb, r, c, portals: portals);
          int free = 0;
          for(int f in nbsOfNb) if(!vis.contains(f) && !gaps.contains(f)) free++;
          if(free == 0 && vis.length < targetSize) { deadEnd = true; break; }
        }
      }

      if(!deadEnd) {
        var res = _solveInternal(r, c, next, vis, gaps, targetSize, portals, limit);
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
