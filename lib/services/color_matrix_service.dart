import 'dart:math' as math;
import 'package:flutter/material.dart';

enum VideoFxPreset {
  normal,
  cyberpunk,
  matrix,
  cinema,
  noir,
  hdr,
}

class ColorMatrixService {
  /// Computes a 4x5 (20 elements) color filter matrix combining:
  /// - brightness (0.5 to 2.0, default 1.0)
  /// - contrast (0.5 to 2.0, default 1.0)
  /// - saturation (0.0 to 2.5, default 1.0)
  /// - hue rotation in degrees (0 to 360, default 0)
  static List<double> computeMatrix({
    double brightness = 1.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double hueDegrees = 0.0,
  }) {
    // 1. Contrast & Brightness base
    // Contrast formula: f(x) = contrast * (x - 0.5) + 0.5 + (brightness - 1.0)
    // = contrast * x + (0.5 * (1 - contrast) + brightness - 1.0)
    final double c = contrast;
    final double bOffset = (0.5 * (1.0 - c) + (brightness - 1.0)) * 255.0;

    // 2. Saturation coefficients (ITU-R BT.709 luminance)
    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;

    final double s = saturation;
    final double invS = 1.0 - s;

    final double sR1 = invS * lumR + s;
    final double sR2 = invS * lumG;
    final double sR3 = invS * lumB;

    final double sG1 = invS * lumR;
    final double sG2 = invS * lumG + s;
    final double sG3 = invS * lumB;

    final double sB1 = invS * lumR;
    final double sB2 = invS * lumG;
    final double sB3 = invS * lumB + s;

    // 3. Hue rotation matrix
    final double rad = hueDegrees * math.pi / 180.0;
    final double cosVal = math.cos(rad);
    final double sinVal = math.sin(rad);

    final double hR1 = lumR + cosVal * (1.0 - lumR) + sinVal * (-lumR);
    final double hR2 = lumG + cosVal * (-lumG) + sinVal * (-lumG);
    final double hR3 = lumB + cosVal * (-lumB) + sinVal * (1.0 - lumB);

    final double hG1 = lumR + cosVal * (-lumR) + sinVal * 0.143;
    final double hG2 = lumG + cosVal * (1.0 - lumG) + sinVal * 0.140;
    final double hG3 = lumB + cosVal * (-lumB) + sinVal * (-0.283);

    final double hB1 = lumR + cosVal * (-lumR) + sinVal * (-(1.0 - lumR));
    final double hB2 = lumG + cosVal * (-lumG) + sinVal * lumG;
    final double hB3 = lumB + cosVal * (1.0 - lumB) + sinVal * lumB;

    // Multiply Hue * Saturation * Contrast
    // For performance and clarity, calculate combined rows:
    final double r1 = c * (hR1 * sR1 + hR2 * sG1 + hR3 * sB1);
    final double r2 = c * (hR1 * sR2 + hR2 * sG2 + hR3 * sB2);
    final double r3 = c * (hR1 * sR3 + hR2 * sG3 + hR3 * sB3);

    final double g1 = c * (hG1 * sR1 + hG2 * sG1 + hG3 * sB1);
    final double g2 = c * (hG1 * sR2 + hG2 * sG2 + hG3 * sB2);
    final double g3 = c * (hG1 * sR3 + hG2 * sG3 + hG3 * sB3);

    final double b1 = c * (hB1 * sR1 + hB2 * sG1 + hB3 * sB1);
    final double b2 = c * (hB1 * sR2 + hB2 * sG2 + hB3 * sB2);
    final double b3 = c * (hB1 * sR3 + hB2 * sG3 + hB3 * sB3);

    return [
      r1, r2, r3, 0.0, bOffset,
      g1, g2, g3, 0.0, bOffset,
      b1, b2, b3, 0.0, bOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  /// Preset matrix definitions for instant cinematic grading
  static List<double> getPresetMatrix(VideoFxPreset preset) {
    switch (preset) {
      case VideoFxPreset.normal:
        return [
          1.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];

      case VideoFxPreset.cyberpunk:
        // Punchy contrast, boosted vibrant magenta/cyan shift
        return [
          1.35, 0.05, 0.15, 0.0, 10.0,
          0.00, 1.10, 0.30, 0.0, 0.0,
          0.15, 0.20, 1.60, 0.0, 25.0,
          0.00, 0.00, 0.00, 1.0, 0.0,
        ];

      case VideoFxPreset.matrix:
        // Phosphor terminal green tint with deep dark blacks
        return [
          0.25, 0.40, 0.10, 0.0, -25.0,
          0.10, 1.45, 0.20, 0.0, 30.0,
          0.15, 0.30, 0.25, 0.0, -30.0,
          0.00, 0.00, 0.00, 1.0, 0.0,
        ];

      case VideoFxPreset.cinema:
        // Hollywood Teal & Orange
        return [
          1.30, 0.05, -0.10, 0.0, 15.0,
          0.00, 1.05, 0.15, 0.0, 0.0,
          -0.10, 0.25, 1.35, 0.0, 20.0,
          0.00, 0.00, 0.00, 1.0, 0.0,
        ];

      case VideoFxPreset.noir:
        // Dramatic high-contrast black and white
        return [
          0.33, 0.55, 0.12, 0.0, -10.0,
          0.33, 0.55, 0.12, 0.0, -10.0,
          0.33, 0.55, 0.12, 0.0, -10.0,
          0.00, 0.00, 0.00, 1.0, 0.0,
        ];

      case VideoFxPreset.hdr:
        // Elevated dynamic range, vibrant pop
        return [
          1.25, 0.00, 0.00, 0.0, 8.0,
          0.00, 1.25, 0.00, 0.0, 8.0,
          0.00, 0.00, 1.25, 0.0, 8.0,
          0.00, 0.00, 0.00, 1.0, 0.0,
        ];
    }
  }

  /// Returns ColorFilter instance
  static ColorFilter getColorFilter({
    VideoFxPreset preset = VideoFxPreset.normal,
    double brightness = 1.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double hueDegrees = 0.0,
  }) {
    if (preset != VideoFxPreset.normal) {
      return ColorFilter.matrix(getPresetMatrix(preset));
    }
    return ColorFilter.matrix(computeMatrix(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      hueDegrees: hueDegrees,
    ));
  }
}
