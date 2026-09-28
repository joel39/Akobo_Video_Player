import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';

enum EqPreset {
  flat,
  bass,
  synthwave,
  vocal,
  electronic,
  rock,
}

class EqSheet extends StatefulWidget {
  final List<double> eqBands;
  final double volumeBoost;
  final bool spatialAudio;
  final ValueChanged<List<double>> onEqChange;
  final ValueChanged<double> onVolumeBoostChange;
  final ValueChanged<bool> onSpatialAudioChange;

  const EqSheet({
    super.key,
    required this.eqBands,
    required this.volumeBoost,
    required this.spatialAudio,
    required this.onEqChange,
    required this.onVolumeBoostChange,
    required this.onSpatialAudioChange,
  });

  @override
  State<EqSheet> createState() => _EqSheetState();
}

class _EqSheetState extends State<EqSheet> {
  static const List<String> _freqLabels = [
    '32Hz', '64Hz', '125Hz', '250Hz', '500Hz',
    '1kHz', '2kHz', '4kHz', '8kHz', '16kHz',
  ];

  late List<double> _bands;
  late double _boost;
  late bool _spatial;
  EqPreset _activePreset = EqPreset.flat;

  @override
  void initState() {
    super.initState();
    _bands = List<double>.from(widget.eqBands);
    _boost = widget.volumeBoost;
    _spatial = widget.spatialAudio;
  }

  void _applyPreset(EqPreset preset) {
    setState(() {
      _activePreset = preset;
      switch (preset) {
        case EqPreset.flat:
          _bands = List.filled(10, 0.0);
          break;
        case EqPreset.bass:
          _bands = [8.0, 7.0, 5.0, 3.0, 1.0, 0.0, 0.0, 1.0, 2.0, 3.0];
          break;
        case EqPreset.synthwave:
          _bands = [6.0, 5.0, 2.0, 0.0, 2.0, 4.0, 5.0, 6.0, 5.0, 4.0];
          break;
        case EqPreset.vocal:
          _bands = [-2.0, -1.0, 0.0, 2.0, 5.0, 6.0, 4.0, 2.0, 0.0, -1.0];
          break;
        case EqPreset.electronic:
          _bands = [6.0, 5.0, 3.0, 1.0, -1.0, 2.0, 3.0, 5.0, 6.0, 6.0];
          break;
        case EqPreset.rock:
          _bands = [5.0, 4.0, 2.0, -1.0, -1.0, 1.0, 3.0, 4.0, 5.0, 5.0];
          break;
      }
    });
    widget.onEqChange(_bands);
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
                    Icon(Icons.equalizer, color: activeColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '10-BAND STUDIO EQ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _applyPreset(EqPreset.flat),
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
                // 10-Band Horizontal Slider Rack
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(10, (index) {
                        return Container(
                          width: 58,
                          height: 180,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              // dB Readout
                              Text(
                                '${_bands[index] > 0 ? '+' : ''}${_bands[index].toInt()}dB',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: activeColor,
                                ),
                              ),
                              // Vertical Slider
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      activeTrackColor: activeColor,
                                      inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      thumbColor: activeColor,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    ),
                                    child: Slider(
                                      value: _bands[index],
                                      min: -12.0,
                                      max: 12.0,
                                      divisions: 24,
                                      onChanged: (val) {
                                        setState(() {
                                          _bands[index] = val;
                                        });
                                        widget.onEqChange(_bands);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              // Frequency Label
                              Text(
                                _freqLabels[index],
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Acoustic Presets
                Text(
                  'ACOUSTIC PRESETS',
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
                    _presetButton('Flat Studio', EqPreset.flat, isDark, activeColor, borderColor),
                    _presetButton('Bass Cannon', EqPreset.bass, isDark, activeColor, borderColor),
                    _presetButton('Cyber Synth', EqPreset.synthwave, isDark, activeColor, borderColor),
                    _presetButton('Vocal Clear', EqPreset.vocal, isDark, activeColor, borderColor),
                    _presetButton('Electronic', EqPreset.electronic, isDark, activeColor, borderColor),
                    _presetButton('Rock Dynamic', EqPreset.rock, isDark, activeColor, borderColor),
                  ],
                ),

                const SizedBox(height: 24),

                // 300% Volume Super Booster
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '300% VOLUME SUPER BOOSTER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(_boost * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          activeTrackColor: const Color(0xFFF59E0B),
                          inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFFF59E0B),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _boost,
                          min: 1.0,
                          max: 3.0,
                          divisions: 20,
                          onChanged: (val) {
                            setState(() => _boost = val);
                            widget.onVolumeBoostChange(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3D Spatial Audio Simulation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.spatial_audio_off, color: activeColor, size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '3D SPATIAL MATRIX',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Expanded stereo soundstage emulation',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _spatial,
                        activeThumbColor: activeColor,
                        activeTrackColor: activeColor.withValues(alpha: 0.35),
                        inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        onChanged: (val) {
                          setState(() => _spatial = val);
                          widget.onSpatialAudioChange(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _presetButton(String title, EqPreset preset, bool isDark, Color activeColor, Color borderColor) {
    final active = _activePreset == preset;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
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
}
