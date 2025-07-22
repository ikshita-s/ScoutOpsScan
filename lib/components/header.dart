import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scout_ops_scan/utils/constants.dart';

class ScoutHeader extends StatelessWidget {
  const ScoutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Increased height to account for status bar area
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 16.0,
          top: 40.0,
          bottom: 16.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Red status indicator
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),

            // Gradient Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE53935), // Red
                  Color(0xFF8E24AA), // Purple
                  Color(0xFF3949AB), // Blue
                ],
              ).createShader(bounds),
              child: Text(
                AppStrings.appTitle,
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // This color is ignored due to ShaderMask
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // Spacer
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
