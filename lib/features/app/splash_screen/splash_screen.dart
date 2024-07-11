import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({super.key, this.child});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => widget.child!),
          (route) => false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 88, 83, 83),
              Color.fromARGB(255, 31, 29, 29)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 114),
            Text(
              'Bridge AI',
              style: GoogleFonts.rammettoOne(
                textStyle: const TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(3, 9),
                      blurRadius: 9,
                      color: Colors.white60,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(), // Pushes the next text to the bottom
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 60.0),
                child: SizedBox(
                  width: 275,
                  child: Text(
                    'Building Bridges to a Brighter Future',
                    style: GoogleFonts.mitr(
                      textStyle: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
