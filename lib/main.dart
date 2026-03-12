import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'menus.dart';

// Global Observer for Back Button logic

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GlowPathApp());

}

class GlowPathApp extends StatelessWidget {

  const GlowPathApp({super.key});

  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'GlowPath',

      navigatorObservers: [routeObserver], // Attach Observer

      theme: ThemeData.dark().copyWith(

        scaffoldBackgroundColor: const Color(0xFF050505),

        textTheme: GoogleFonts.exo2TextTheme().apply(bodyColor: Colors.white),

      ),

      home: const MainMenu(),

    );

  }

}