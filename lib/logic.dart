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
      if (attempts > 500) { // Safety break
         // Fallback to a simpler version or different seed if stuck
         seedBase += 1; attempts = 0;
      }
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

    // Fast check for isolated tiles before solving
    int targetSize = total - gaps.length;
    for(int i=0; i<total; i++) {
      if(!gaps.contains(i)) {
        var n = getNeighbors(i, rows, cols, portals: portals);
        int available = 0;
        for(int nb in n) if(!gaps.contains(nb)) available++;
        if(available == 0 && targetSize > 1) return null; // Isolated tile
      }
    }

    if(Solver.solve(rows,cols,start,{start},gaps,targetSize,portals,rng:rng) != null) {
      return LevelData(idx+1,rows,cols,start,color,gaps,portals:portals,isDanger:isDanger);
    }
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
      if (!n.contains(p)) n.add(p); // Remove duplicates
    }
    return n;
  }
}

class Solver {
  static List<int>? solve(int r, int c, int cur, Set<int> vis, Set<int> gaps, int targetSize, Map<int, int> portals, {Random? rng}) {
    if(vis.length == targetSize) return vis.toList();
    
    List<int> n = LevelGenerator.getNeighbors(cur, r, c, portals: portals);
    if (rng != null) n.shuffle(rng);

    // Dead-end detection: if any unvisited tile becomes isolated, backtrack early
    for(int next in n) {
      if(!vis.contains(next) && !gaps.contains(next)) {
        vis.add(next);
        
        // Simple connectivity heuristic: check if we just isolated a tile
        bool isolated = false;
        // Only check neighbors of 'cur' and 'next' for efficiency
        List<int> check = LevelGenerator.getNeighbors(cur, r, c, portals: portals);
        for(int tile in check) {
          if(!vis.contains(tile) && !gaps.contains(tile)) {
            var nbs = LevelGenerator.getNeighbors(tile, r, c, portals: portals);
            int reachable = 0;
            for(int nb in nbs) if(!vis.contains(nb) && !gaps.contains(nb)) reachable++;
            if(reachable == 0 && vis.length < targetSize) { isolated = true; break; }
          }
        }

        if(!isolated) {
          var res = solve(r,c,next,vis,gaps,targetSize,portals,rng:rng);
          if(res!=null) return res;
        }
        vis.remove(next);
      }
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
