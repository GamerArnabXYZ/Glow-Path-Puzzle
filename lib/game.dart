import 'dart:async';
import 'dart:math';
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

class _GS extends State<GameScreen> {
  late LevelData _d; List<int> _path = []; bool _win = false; double _cs = 0;
  int _stgCur=0,_stgTot=1; bool _dang=false,_trans=false; Timer? _t; int _elap=0,_timeLeft=10;int _hints=0;
  
  @override void initState() { super.initState(); _loadSets(); _initLvl(); }
  @override void dispose() { _t?.cancel(); super.dispose(); }

  void _loadSets() async { int h = await GameStorage.getHints(); setState(() {_hints=h;}); }
  void _initLvl() { _dang=(widget.idx+1)%10==0; _stgTot=_dang?3:1; _stgCur=0; _elap=0; _load(); }
  void _load() {
    _t?.cancel(); _d = LevelGenerator.generate(widget.idx, stage:_stgCur); _path=[_d.start]; _win=false; _trans=false; _timeLeft=10;
    _t=Timer.periodic(1.seconds, (t){if(mounted)setState((){if(_dang){_timeLeft--;if(_timeLeft<=0)_fail();}else{_elap++;}} );});
    setState((){});
  }

  void _hintLogic() async {
    if(_hints<=0) return;
    List<int>? sol = Solver.solve(_d.rows,_d.cols,_path.last,_path.toSet(),_d.gaps,(_d.rows*_d.cols)-_d.gaps.length);
    if(sol!=null && sol.length > _path.length){
      setState(() { _path.add(sol[_path.length]); _hints--; GameStorage.useHint(); });
      if(_path.length==((_d.rows*_d.cols)-_d.gaps.length)) _done();
    }
  }

  void _fail() { _t?.cancel(); showDialog(barrierDismissible:false,context:context,builder:(_)=>AlertDialog(backgroundColor:Colors.red.shade900, title: const Text("TIME UP!"), actions:[TextButton(onPressed:()=>Navigator.pop(context), child: const Text("RETRY"))])); }

  void _inp(Offset o) {
    if(_win||_trans||_cs==0||(_dang&&_timeLeft<=0)) return;
    int c=(o.dx/_cs).floor(); int r=(o.dy/_cs).floor();
    if(c<0||c>=_d.cols||r<0||r>=_d.rows)return; int id=r*_d.cols+c;
    if(_d.gaps.contains(id)) return;
    if(_path.length>1 && id==_path[_path.length-2]) { setState(()=>_path.removeLast()); return; }
    if(id==_path.last||_path.contains(id))return;
    if(((id~/_d.cols)-(_path.last~/_d.cols)).abs()+((id%_d.cols)-(_path.last%_d.cols)).abs()==1){
      setState((){ _path.add(id); if(_path.length==(_d.rows*_d.cols)-_d.gaps.length)_done(); });
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
        showGeneralDialog(context: context, pageBuilder:(c,a,b)=>const SizedBox(), transitionBuilder:(c,a,b,ch)=>ScaleTransition(scale:a, child:_WinDialog(stars:s, next:(){
           Navigator.pop(context); Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>GameScreen(idx:widget.idx+1)));
        })));
      }
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor:Colors.transparent, elevation:0, title:Text(_dang?"BOSS":"LEVEL ${widget.idx+1}", style:TextStyle(color:_d.color)),
        actions: [ IconButton(icon:const Icon(Icons.lightbulb),onPressed:_hintLogic), IconButton(icon:const Icon(Icons.refresh),onPressed:()=>setState(()=>_path=[_d.start])) ]
      ),
      extendBodyBehindAppBar:true,
      body:Stack(children:[
        Container(color:Colors.black),
        if(_trans) Center(child: Text("STAGE CLEAR!", style:GoogleFonts.orbitron(fontSize:28, color:Colors.greenAccent))),
        if(!_trans) Center(child:LayoutBuilder(builder:(c,n){_cs=min((n.maxWidth-30)/_d.cols,(n.maxHeight*0.8)/_d.rows); return GestureDetector(onPanUpdate:(d)=>_inp(d.localPosition),onTapDown:(d)=>_inp(d.localPosition),child:SizedBox(width:_cs*_d.cols,height:_cs*_d.rows,child:Stack(children:[CustomPaint(painter:GridPainter(_d,_cs), size:Size.infinite), CustomPaint(painter:PathPainter(_path,_d,_cs), size:Size.infinite)])));}))
      ])
    );
  }
}

class _WinDialog extends StatelessWidget {
  final int stars; final VoidCallback next;
  const _WinDialog({required this.stars, required this.next});
  @override Widget build(BuildContext context) {
    return Center(child: Material(color:Colors.transparent, child: Container(padding:const EdgeInsets.all(30), decoration:BoxDecoration(color:Colors.black, borderRadius:BorderRadius.circular(30), border:Border.all(color:Colors.amber)),
        child: Column(mainAxisSize:MainAxisSize.min, children:[
           const Icon(Icons.emoji_events, color:Colors.amber, size:60),
           const SizedBox(height:20), Text("COMPLETE!", style:GoogleFonts.orbitron(color:Colors.white, fontSize:20)),
           const SizedBox(height:20), Row(mainAxisAlignment:MainAxisAlignment.center, children: List.generate(3,(i)=>Icon(Icons.star, color:i<stars?Colors.amber:Colors.white10))),
           const SizedBox(height:30), ElevatedButton(onPressed:next, child:const Text("NEXT LEVEL"))
        ]))));
  }
}