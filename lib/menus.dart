import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'logic.dart';
import 'models.dart';
import 'game.dart';
import 'settings.dart';
import 'main.dart'; 

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _isNavigating = false;

  Future<void> _openAbout() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.transparent, 
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_,__,___) => const SizedBox(),
      transitionBuilder: (ctx, a1, a2, child) {
        final curve = Curves.easeOutBack.transform(a1.value);
        return Stack(
          children: [
            Opacity(opacity: a1.value, child: Container(color: Colors.black87)), 
            Transform.scale(scale: curve, child: const _AboutInfoCard()),
          ],
        );
      },
    );
    if (mounted) setState(() => _isNavigating = false);
  }

  void _openSettings() {
    if (!_isNavigating) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _startGame() {
    if (!_isNavigating) Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/background.png", 
            fit: BoxFit.cover,
            errorBuilder: (c,e,s) => Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF2C5364)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 20, left: 20,
                  child: _BouncyBtn(
                    onTap: _openAbout,
                    delay: 200,
                    child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 32),
                  )
                ),
                Positioned(
                  top: 20, right: 20,
                  child: _BouncyBtn(
                    onTap: _openSettings,
                    delay: 400,
                    child: const Icon(Icons.settings, color: Colors.cyanAccent, size: 32),
                  )
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 220), 
                    child: _BouncyBtn(
                      onTap: _startGame,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(width: 100, height: 100,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.tealAccent.withOpacity(0.5))))
                          .animate(onPlay: (c)=>c.repeat()).scale(begin: const Offset(1,1), end: const Offset(2.0, 2.0), duration: 1500.ms, curve: Curves.easeOut).fadeOut(duration: 1500.ms),
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.tealAccent.withOpacity(0.15),
                              border: Border.all(color: Colors.tealAccent, width: 2),
                              boxShadow: [BoxShadow(color: Colors.tealAccent.withOpacity(0.6), blurRadius: 25)]
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 55),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
                ),
                const Positioned(bottom: 15, left: 0, right: 0, child: Center(child: Text("v21.0_silent", style: TextStyle(color: Colors.white24, fontSize: 10))))
              ],
            ),
          )
        ],
      )
    );
  }
}

class _BouncyBtn extends StatefulWidget {
  final Widget child; final VoidCallback onTap; final int delay;
  const _BouncyBtn({required this.child, required this.onTap, this.delay = 0});
  @override State<_BouncyBtn> createState() => _BouncyBtnState();
}

class _BouncyBtnState extends State<_BouncyBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _scale;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: 100.ms); _scale = Tween<double>(begin: 1.0, end: 0.85).animate(_ctrl); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return GestureDetector(onTapDown: (_)=>_ctrl.forward(), onTapUp: (_){_ctrl.reverse(); widget.onTap();}, onTapCancel: ()=>_ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child)).animate().slideY(begin: -1, end: 0, duration: 600.ms, delay: widget.delay.ms, curve: Curves.elasticOut).fadeIn();
  }
}

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard();
  @override Widget build(BuildContext context) {
    return Center(child: Material(color:Colors.transparent, child: Container(width: 320, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.purpleAccent.withOpacity(0.5))),
      child: Column(mainAxisSize:MainAxisSize.min, children:[
           Text("GlowPath", style:GoogleFonts.orbitron(fontSize:24, color:Colors.purpleAccent, fontWeight: FontWeight.bold)),
           const SizedBox(height:20), 
           const Text("Connect all tiles.\nAvoid gaps.\nMaster the glow.", textAlign:TextAlign.center, style:TextStyle(color:Colors.white70)),
           const Divider(height:40, color:Colors.white12),
           SizedBox(width: double.infinity, child: OutlinedButton(onPressed:()=>Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)), child: const Text("CLOSE", style: TextStyle(color: Colors.white))))
      ]))));
  }
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});
  @override State<LevelSelectScreen> createState() => _LSS();
}

class _LSS extends State<LevelSelectScreen> with RouteAware {
  int ul = 1; Map<String, int> _stars = {};
  @override void initState() { super.initState(); _r(); }
  @override void didChangeDependencies() { super.didChangeDependencies(); routeObserver.subscribe(this, ModalRoute.of(context)!); }
  @override void dispose() { routeObserver.unsubscribe(this); super.dispose(); }
  @override void didPopNext() { _r(); }
  void _r() async { int i = await GameStorage.getMaxLevel(); var s = await GameStorage.getStars(); if(mounted) setState(() { ul=i; _stars=s; }); }

  @override Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title:const Text("LEVELS"), centerTitle:true, backgroundColor:Colors.transparent, elevation:0),
       extendBodyBehindAppBar: true,
       body: Stack(children:[
          Container(color:Colors.black),
          GridView.builder(padding:const EdgeInsets.fromLTRB(20, 100, 20, 20), itemCount:ul+12, 
            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4, crossAxisSpacing:15, mainAxisSpacing:15, childAspectRatio:0.9),
            itemBuilder:(c,i) {
               bool loc = (i+1)>ul; bool dang = (i+1)%10==0;
               LevelData? prev; if(!loc) prev = LevelGenerator.generate(i);
               Color col = loc ? Colors.white10 : (dang ? Colors.redAccent : prev!.color);
               int s = _stars[i.toString()] ?? 0;
               return GestureDetector( 
                 onTap: loc ? null : () => Navigator.push(context, MaterialPageRoute(builder:(_)=>GameScreen(idx:i))), 
                 child: Container(decoration:BoxDecoration( color: loc ? Colors.white10 : col.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: loc ? Colors.transparent : col.withOpacity(0.6))),
                   child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[ if(loc) const Icon(Icons.lock, size:16, color:Colors.white12) else ...[ Text("${i+1}", style:const TextStyle(fontWeight:FontWeight.bold, fontSize:20)), const SizedBox(height:5), Row(mainAxisAlignment:MainAxisAlignment.center, children: List.generate(3, (x) => Icon(Icons.star, size:10, color: x < s ? Colors.amber : Colors.white12))) ]]))
               );
            }
          )
       ]),
    );
  }
}