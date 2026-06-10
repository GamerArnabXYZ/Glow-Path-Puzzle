import 'dart:ui'; 
import 'package:flutter/foundation.dart';
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
      barrierColor: Colors.black54, 
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_,__,___) => const SizedBox(),
      transitionBuilder: (ctx, a1, a2, child) {
        if (kIsWeb) {
          return FadeTransition(
            opacity: a1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
              child: const _AboutInfoCard(),
            ),
          );
        }
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * a1.value, sigmaY: 5 * a1.value),
          child: FadeTransition(
            opacity: a1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
              child: const _AboutInfoCard(),
            ),
          ),
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
            errorBuilder: (c,e,s) => Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF000428), Color(0xFF004e92)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
          ).animate().fadeIn(duration: 1.seconds),
          Container(color: Colors.black38),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      _BouncyBtn(
                        onTap: _startGame,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 120, height: 120,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))))
                            .animate(onPlay: (c)=>c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.8, 1.8), duration: 2.seconds, curve: Curves.easeOut).fadeOut(),
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)]
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 60),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    ],
                  ),
                ),
                const Positioned(bottom: 20, left: 0, right: 0, child: Center(child: Text("EXPERIENCE THE GLOW", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 3))))
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
    return GestureDetector(
      onTapDown: (_)=>_ctrl.forward(), 
      onTapUp: (_){ if(mounted) _ctrl.reverse(); widget.onTap(); }, 
      onTapCancel: (){ if(mounted) _ctrl.reverse(); },
      child: ScaleTransition(scale: _scale, child: widget.child)).animate().slideY(begin: -1, end: 0, duration: 600.ms, delay: widget.delay.ms, curve: Curves.elasticOut).fadeIn();
  }
}

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard();
  @override Widget build(BuildContext context) {
    return Center(child: Material(color:Colors.transparent, child: Container(width: 320, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: const Color(0xFF050505), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 40)]),
      child: Column(mainAxisSize:MainAxisSize.min, children:[
           Text("GLOW PATH", style:GoogleFonts.orbitron(fontSize:28, color:Colors.cyanAccent, fontWeight: FontWeight.bold)),
           const SizedBox(height:25), 
           _infoRow(Icons.grid_4x4, "Connect all tiles to win"),
           _infoRow(Icons.cyclone, "Use portals to teleport"),
           _infoRow(Icons.timer, "Beat the boss in time"),
           const Divider(height:40, color:Colors.white10),
           SizedBox(width: double.infinity, child: ElevatedButton(onPressed:()=>Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold))))
      ]))));
  }
  Widget _infoRow(IconData i, String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(i, color: Colors.cyanAccent, size: 20), const SizedBox(width: 15), Text(t, style: const TextStyle(color: Colors.white70))]));
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
       appBar: AppBar(title:Text("SELECT LEVEL", style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold)), centerTitle:true, backgroundColor:Colors.transparent, elevation:0),
       extendBodyBehindAppBar: true,
       body: Stack(children:[
          Container(color:Colors.black),
          GridView.builder(padding:const EdgeInsets.fromLTRB(25, 120, 25, 25), itemCount:ul+12, 
            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4, crossAxisSpacing:15, mainAxisSpacing:15, childAspectRatio:0.85),
            itemBuilder:(c,i) {
               bool loc = (i+1)>ul; bool dang = (i+1)%10==0;
               Color col = loc ? Colors.white10 : LevelGenerator.getColor(i);
               int s = _stars[i.toString()] ?? 0;
               return GestureDetector( 
                 onTap: loc ? null : () => Navigator.push(context, MaterialPageRoute(builder:(_)=>GameScreen(idx:i))), 
                 child: Container(decoration:BoxDecoration( color: loc ? Colors.white.withOpacity(0.02) : col.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: loc ? Colors.white10 : col.withOpacity(0.4), width: 1.5)),
                   child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[ 
                     if(loc) const Icon(Icons.lock_outline, size:20, color:Colors.white10) 
                     else ...[ 
                       Text("${i+1}", style:GoogleFonts.orbitron(fontWeight:FontWeight.w900, fontSize:22, color: col)), 
                       const SizedBox(height:8), 
                       Row(mainAxisAlignment:MainAxisAlignment.center, children: List.generate(3, (x) => Icon(Icons.star, size:12, color: x < s ? Colors.amber : Colors.white10))) 
                     ]
                   ]))
               ).animate().scale(delay: (i%20 * 50).ms, duration: 400.ms, curve: Curves.easeOut);
            }
          )
       ]),
    );
  }
}
