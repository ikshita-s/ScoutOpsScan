import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scout_ops_scan/utils/constants.dart';

class ScoutHeader extends StatelessWidget {
  const ScoutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150, // Increased height for more natural blending
      decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
        Colors.black, // Solid black at the top
        Colors.black, // Continue solid
        Colors.transparent, // Fade to transparent to let camera feed show
        ],
        stops: [
        0.0,
        0.6, // Adjusted to keep solid black area for text
        1.0,
        ],
      ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 0.0,
          right: 0.0,
          top: 0.0,
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE53935), // Red
                  Color(0xFF8E24AA), // Purple
                  Color(0xFF3949AB), // Blue
                ],
              ).createShader(bounds),
              child: Text(
                AppStrings.appTitle,
                style: GoogleFonts.museoModerno(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // Ignored due to ShaderMask
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
