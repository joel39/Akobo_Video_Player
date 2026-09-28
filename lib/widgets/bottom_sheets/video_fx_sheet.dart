import 'package:flutter/material.dart';
import '../../services/color_matrix_service.dart';
import '../../theme/cyber_theme.dart';

class VideoFxSheet extends StatefulWidget {
  final VideoFxPreset currentPreset;
  final double brightness;
  final double contrast;
  final double saturation;
  final double hueRotation;
  final ValueChanged<VideoFxPreset> onPresetChange;
  final ValueChanged<double> onBrightnessChange;
  final ValueChanged<double> onContrastChange;
  final ValueChanged<double> onSaturationChange;
  final ValueChanged<double> onHueChange;
  final VoidCallback onReset;

  const VideoFxSheet({
    super.key,
    required this.currentPreset,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.hueRotation,
    required this.onPresetChange,
    required this.onBrightnessChange,
    required this.onContrastChange,
    required this.onSaturationChange,
    required this.onHueChange,
    required this.onReset,
  });

  @override
  State<VideoFxSheet> createState() => _VideoFxSheetState();
}

class _VideoFxSheetState extends State<VideoFxSheet> {
  late VideoFxPreset _preset;
  late double _brightness;
  late double _contrast;
  late double _saturation;
  late double _hue;

  @override
  void initState() {
    super.initState();
    _preset = widget.currentPreset;
    _brightness = widget.brightness;
    _contrast = widget.contrast;
    _saturation = widget.saturation;
    _hue = widget.hueRotation;
  }

  void _resetAll() {
    setState(() {
      _preset = VideoFxPreset.normal;
      _brightness = 1.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _hue = 0.0;
    });
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final bg = CyberTheme.getCard(context);
    final surface = CyberTheme.getSurface(context);
    final activeColor = CyberTheme.primaryBlue;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: activeColor.withValues(alpha: 0.3), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: activeColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'VIDEO FX & COLOR GRADING',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _resetAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Cinematic Presets
                Text(
                  'CINEMATIC PRESETS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetButton('Normal', VideoFxPreset.normal, isDark, activeColor, borderColor),
                    _presetButton('Cyberpunk', VideoFxPreset.cyberpunk, isDark, activeColor, borderColor),
                    _presetButton('Matrix Green', VideoFxPreset.matrix, isDark, activeColor, borderColor),
                    _presetButton('Teal & Orange', VideoFxPreset.cinema, isDark, activeColor, borderColor),
                    _presetButton('Noir Mono', VideoFxPreset.noir, isDark, activeColor, borderColor),
                    _presetButton('HDR Simulator', VideoFxPreset.hdr, isDark, activeColor, borderColor),
                  ],
                ),

                const SizedBox(height: 24),

                // Sliders
                _fxSlider(
                  title: 'Brightness',
                  value: _brightness,
                  min: 0.5,
                  max: 2.0,
                  readout: '${(_brightness * 100).toInt()}%',
                  surface: surface,
                  borderColor: borderColor,
                  activeColor: activeColor,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() {
                      _preset = VideoFxPreset.normal;
                      _brightness = val;
                    });
                    widget.onBrightnessChange(val);
                  },
                ),

                _fxSlider(
                  title: 'Contrast',
                  value: _contrast,
                  min: 0.5,
                  max: 2.0,
                  readout: '${(_contrast * 100).toInt()}%',
                  surface: surface,
                  borderColor: borderColor,
                  activeColor: activeColor,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() {
                      _preset = VideoFxPreset.normal;
                      _contrast = val;
                    });
                    widget.onContrastChange(val);
                  },
                ),

                _fxSlider(
                  title: 'Saturation',
                  value: _saturation,
                  min: 0.0,
                  max: 2.5,
                  readout: '${(_saturation * 100).toInt()}%',
                  surface: surface,
                  borderColor: borderColor,
                  activeColor: activeColor,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() {
                      _preset = VideoFxPreset.normal;
                      _saturation = val;
                    });
                    widget.onSaturationChange(val);
                  },
                ),

                _fxSlider(
                  title: 'Hue Rotation',
                  value: _hue,
                  min: 0.0,
                  max: 360.0,
                  readout: '${_hue.toInt()}°',
                  surface: surface,
                  borderColor: borderColor,
                  activeColor: activeColor,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() {
                      _preset = VideoFxPreset.normal;
                      _hue = val;
                    });
                    widget.onHueChange(val);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _presetButton(String title, VideoFxPreset preset, bool isDark, Color activeColor, Color borderColor) {
    final active = _preset == preset;
    return GestureDetector(
      onTap: () {
        setState(() => _preset = preset);
        widget.onPresetChange(preset);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : borderColor,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? activeColor : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _fxSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required String readout,
    required Color surface,
    required Color borderColor,
    required Color activeColor,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                readout,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: activeColor,
              inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              thumbColor: activeColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
