import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'logic.dart';
import 'models.dart';
import 'painters.dart';

class GameScreen extends StatefulWidget {
  final int idx;
  const GameScreen({super.key, required this.idx});
  @override State<GameScreen> createState() => _GS();
}

class _GS extends State<GameScreen> with TickerProviderStateMixin {
  late LevelData _d; List<int> _path = []; bool _win = false; double _cs = 0;
  int _stgCur=0,_stgTot=1; bool _dang=false,_trans=false; Timer? _t; int _elap=0,_timeLeft=10;int _hints=0;
  bool _loading = true; bool _hasKey = false;
  
  @override void initState() { super.initState(); _loadSets(); _initLvl(); }
  @override void dispose() { _t?.cancel(); super.dispose(); }

  void _loadSets() async { 
    int h = await GameStorage.getHints(); 
    if(mounted) setState(() {_hints=h;}); 
  }
  void _initLvl() { 
    _dang=(widget.idx+1)%10==0; 
    _stgTot=_dang?3:1; 
    _stgCur=0; 
    _elap=0; 
    _load(); 
  }

  void _load() async {
    _t?.cancel();
    if(!mounted) return;
    setState(() { _loading = true; _trans = false; _hasKey = false; });
    await Future.delayed(const Duration(milliseconds: 50)); 
    _d = await LevelGenerator.generate(widget.idx, stage:_stgCur);
    if(!mounted) return;
    _path=[_d.start]; _win=false; _trans=false; _timeLeft=10;

    _t=Timer.periodic(const Duration(seconds: 1), (t){
      if(mounted){
        setState((){
          if(_dang){
            _timeLeft--;
            if(_timeLeft<=0){
              t.cancel();
              _fail();
            }
          }else{
            _elap++;
          }
        });
      } else {
        t.cancel();
      }
    });
    setState((){ _loading = false; });
  }

  void _hintLogic() async {
    if(_hints<=0) return;
    List<int>? sol = Solver.solve(_d.rows,_d.cols,_path.last,_path.toSet(),_d.gaps,(_d.rows*_d.cols)-_d.gaps.length, _d.portals, keyTile: _d.keyTile, lockTile: _d.lockTile, oneWays: _d.oneWayTiles);
    if(sol!=null && sol.length > _path.length){
      int nextId = sol[_path.length];
      if(nextId == _d.keyTile) _hasKey = true;
      setState(() { _path.add(nextId); _hints--; GameStorage.useHint(); });
      if(_path.length==((_d.rows*_d.cols)-_d.gaps.length)) _done();
    }
  }

  void _fail() {
    _t?.cancel();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: Text("TIME UP!", style: GoogleFonts.orbitron(color: Colors.white)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _load(); }, child: const Text("RETRY", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  // OPTIMIZED: Strict condition checks before mutating State
  void _inp(Offset o) {
    if(_win||_trans||_loading||_cs==0||(_dang&&_timeLeft<=0)) return;
    int c=(o.dx/_cs).floor(), r=(o.dy/_cs).floor();
    if(c<0||c>=_d.cols||r<0||r>=_d.rows)return; 
    int id=r*_d.cols+c;
    if(_d.gaps.contains(id)) return;
    
    if(_path.length>1 && id==_path[_path.length-2]) { 
      setState(() {
        int removed = _path.removeLast();
        if(removed == _d.keyTile) _hasKey = false;
      }); 
      return; 
    }
    if(id==_path.last||_path.contains(id))return;
    if(id == _d.lockTile && !_hasKey) return;

    var neighbors = LevelGenerator.getNeighbors(_path.last, _d.rows, _d.cols, portals: _d.portals, oneWays: _d.oneWayTiles);
    if(neighbors.contains(id)){
      setState((){ 
        _path = List.from(_path)..add(id); // Pure object replacement to trigger faster Repaint Boundary
        if(id == _d.keyTile) _hasKey = true;
        if(_path.length==(_d.rows*_d.cols)-_d.gaps.length)_done(); 
      });
    }
  }

  void _done() async {
    _t?.cancel();
    if(_stgCur+1<_stgTot){ setState(()=>_trans=true); await Future.delayed(1200.ms); _stgCur++; _load(); }
    else { 
      _win=true;
      int s=1; if(_dang)s=3; else{int t=_d.rows*_d.cols; if(_elap<=t*0.8)s=3; else if(_elap<=t*1.5)s=2;}
      await GameStorage.saveProgress(widget.idx, s);
      if(mounted) {
        showGeneralDialog(
          context: context, 
          barrierColor: Colors.black.withOpacity(0.9),
          pageBuilder:(c,a,b)=>const SizedBox(), 
          transitionBuilder:(c,a,b,ch)=>ScaleTransition(scale:a, child:_WinDialog(stars:s, next:(){
            Navigator.pop(context); 
            Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a, sa) => GameScreen(idx: widget.idx + 1), transitionsBuilder: (c, a, sa, child) => FadeTransition(opacity: a, child: child), transitionDuration: 300.ms));
        })));
      }
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor:Colors.transparent, 
        elevation:0, 
        title:Text(_dang?"BOSS":"LEVEL ${widget.idx+1}", style:TextStyle(color:_loading ? Colors.white24 : _d.color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [ 
          IconButton(icon:const Icon(Icons.lightbulb_outline, color: Colors.amberAccent),onPressed:_loading ? null : _hintLogic), 
          IconButton(icon:Icon(Icons.refresh, color: _loading ? Colors.white24 : Colors.white70),onPressed:_loading ? null : ()=>setState((){_path=[_d.start]; _hasKey=false; })) 
        ]
      ),
      extendBodyBehindAppBar:true,
      body:Stack(children:[
        const SizedBox.expand(child: ColoredBox(color: Colors.black)),
        
        // Native conditional performance lock for web context
        if (!kIsWeb && !_loading) 
          Container(color: Colors.transparent).animate(onPlay:(c)=>c.repeat(reverse: true)).tint(color: _d.color.withOpacity(0.05), duration: 3.seconds),
        
        if(_loading) Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 20),
          Text("GENERATING LEVEL...", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
        ])),

        if(!_loading && _trans) Center(child: Text("STAGE CLEAR!", style:GoogleFonts.orbitron(fontSize:28, color:Colors.greenAccent, fontWeight: FontWeight.bold)).animate().scale(duration: 400.ms).fadeIn().shimmer(delay: 400.ms)),
        
        // CRITICAL PERFORMANCE FIX: RepaintBoundary isolation blocks global context layout shifts
        if(!_loading && !_trans) Center(child:LayoutBuilder(builder:(c,n){
          _cs=min((n.maxWidth-30)/_d.cols,(n.maxHeight*0.8)/_d.rows); 
          return GestureDetector(
            onPanUpdate:(d)=>_inp(d.localPosition),
            onTapDown:(d)=>_inp(d.localPosition),
            child:SizedBox(
              width:_cs*_d.cols,
              height:_cs*_d.rows,
              child:RepaintBoundary(
                child: Stack(children:[
                  CustomPaint(painter:GridPainter(_d,_cs, hasKey: _hasKey), size:Size.infinite), 
                  CustomPaint(painter:PathPainter(_path,_d,_cs), size:Size.infinite)
                ]),
              )
            )
          );
        })),
        
        if(_win) const Positioned.fill(child: IgnorePointer(child: _ParticleCelebration())),
      ])
    );
  }
}

// REST OF THE DIALOGS REMAIN SAME UNCHANGED FOR STABILITY
class _ParticleCelebration extends StatefulWidget {
  const _ParticleCelebration();
  @override State<_ParticleCelebration> createState() => _ParticleCelebrationState();
}

class _ParticleCelebrationState extends State<_ParticleCelebration> {
  // Pre-calculate random values once in initState so particles don't jump every frame
  late final List<_ParticleData> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(12, (_) => _ParticleData(
      xFraction: rng.nextDouble(),
      yFraction: rng.nextDouble(),
      colorIndex: rng.nextInt(3),
      moveEnd: -100 - rng.nextDouble() * 200,
    ));
  }

  @override Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(children: _particles.map((p) {
      return Positioned(
        left: p.xFraction * size.width,
        top: p.yFraction * size.height,
        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: [Colors.cyanAccent, Colors.purpleAccent, Colors.yellowAccent][p.colorIndex], shape: BoxShape.circle))
        .animate().moveY(begin: 0, end: p.moveEnd, duration: 1.seconds, curve: Curves.easeOut).fadeOut(),
      );
    }).toList());
  }
}

class _ParticleData {
  final double xFraction;
  final double yFraction;
  final int colorIndex;
  final double moveEnd;
  const _ParticleData({required this.xFraction, required this.yFraction, required this.colorIndex, required this.moveEnd});
}

class _WinDialog extends StatelessWidget {
  final int stars; final VoidCallback next;
  const _WinDialog({required this.stars, required this.next});
  @override Widget build(BuildContext context) {
    return Center(child: Material(color:Colors.transparent, child: Container(padding:const EdgeInsets.all(30), decoration:BoxDecoration(color:const Color(0xFF0A0A0A), borderRadius:BorderRadius.circular(30), border:Border.all(color:Colors.amber, width: 2), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 20)]),
        child: Column(mainAxisSize:MainAxisSize.min, children:[
           const Icon(Icons.emoji_events, color:Colors.amber, size:70).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
           const SizedBox(height:20), Text("COMPLETE!", style:GoogleFonts.orbitron(color:Colors.white, fontSize:22, fontWeight: FontWeight.bold)),
           const SizedBox(height:20), Row(mainAxisAlignment:MainAxisAlignment.center, children: List.generate(3,(i)=>Icon(Icons.star, size: 35, color:i<stars?Colors.amber:Colors.white10)).animate(interval: 100.ms).scale(duration: 300.ms)),
           const SizedBox(height:30), ElevatedButton(onPressed:next, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child:Text("NEXT LEVEL", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)))
        ]))));
  }
}
