import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

// ... (Keep LevelGenerator and Solver Classes EXACTLY as they passed last time) ...
// ... (To save space I am just showing the GameStorage changes) ...

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
    }
  }

  static LevelData? _tryGen(int idx, Random rng, bool isDanger) {
    // --- (Keep your existing Grid/Difficulty logic exactly same) ---
    // Re-pasting common logic to ensure file is complete
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
      if(g!=start && !gaps.contains(g)) { if(!_isol(g,start,rows,cols)) gaps.add(g); }
      ax++;
    }
    if(Solver.solve(rows,cols,start,{start},gaps,total-gaps.length,rng:rng) != null) {
      return LevelData(idx+1,rows,cols,start,color,gaps,isDanger:isDanger);
    }
    return null;
  }
  
  static bool _isol(int h, int s, int r, int c) => getNeighbors(s,r,c).every((n) => n==h); // Simplified
  static List<int> getNeighbors(int x, int r, int c) {
    List<int>n=[]; int R=x~/c,C=x%c;
    if(R>0)n.add((R-1)*c+C); if(R<r-1)n.add((R+1)*c+C);
    if(C>0)n.add(R*c+C-1); if(C<c-1)n.add(R*c+C+1);
    return n;
  }
}

class Solver {
  static List<int>? solve(int r, int c, int cur, Set<int> vis, Set<int> gaps, int targetSize, {Random? rng}) {
    if(vis.length == targetSize) return vis.toList();
    List<int> n = LevelGenerator.getNeighbors(cur, r, c);
    if (rng != null) n.shuffle(rng);
    for(int next in n) {
      if(!vis.contains(next) && !gaps.contains(next)) {
        vis.add(next);
        var res = solve(r,c,next,vis,gaps,targetSize,rng:rng);
        if(res!=null) return res; vis.remove(next);
      }
    }
    return null;
  }
}

class GameStorage {
  static const String kLvl = 'gp_18_lvl'; 
  static const String kStars = 'gp_18_stars';
  static const String kHints = 'gp_hint_count';
  
  // NEW SETTINGS KEYS
  static const String kSetMusic = 'gp_set_music';
  static const String kSetSfx = 'gp_set_sfx_v2';
  static const String kSetVib = 'gp_set_vib';

  static Future<int> getMaxLevel() async { 
    var p = await SharedPreferences.getInstance(); return p.getInt(kLvl) ?? 1; 
  }
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

  // --- SETTINGS LOGIC ---
  static Future<double> getMusicVol() async => (await SharedPreferences.getInstance()).getDouble(kSetMusic) ?? 1.0;
  static Future<double> getSfxVol() async => (await SharedPreferences.getInstance()).getDouble(kSetSfx) ?? 1.0;
  static Future<bool> getVibration() async => (await SharedPreferences.getInstance()).getBool(kSetVib) ?? true;

  static Future<void> setMusicVol(double v) async => (await SharedPreferences.getInstance()).setDouble(kSetMusic, v);
  static Future<void> setSfxVol(double v) async => (await SharedPreferences.getInstance()).setDouble(kSetSfx, v);
  static Future<void> setVibration(bool v) async => (await SharedPreferences.getInstance()).setBool(kSetVib, v);
}