import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'logic.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVol = 1.0; double _sfxVol = 1.0;

  @override void initState() { super.initState(); _load(); }
  void _load() async {
    double m = await GameStorage.getMusicVol();
    double s = await GameStorage.getSfxVol();
    setState(() { _musicVol = m; _sfxVol = s; });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SETTINGS", style: GoogleFonts.orbitron()), centerTitle: true, backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(children: [
          const SizedBox(height: 20),
          _slider("MUSIC", _musicVol, (v){ setState(()=>_musicVol=v); GameStorage.setMusicVol(v); }),
          const SizedBox(height: 30),
          _slider("SOUND EFFECTS", _sfxVol, (v){ setState(()=>_sfxVol=v); GameStorage.setSfxVol(v); }),
          const Spacer(),
          const Text("Vibration removed for better stability.", style: TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _slider(String label, double val, Function(double) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
      Slider(value: val, onChanged: onChanged, activeColor: Colors.cyanAccent),
    ]);
  }
}