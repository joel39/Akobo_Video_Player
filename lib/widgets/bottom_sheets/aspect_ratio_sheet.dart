import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';
import 'tools_sheet.dart';

class AspectRatioSheet extends StatelessWidget {
  final PlayerAspectRatio currentAspectRatio;
  final ValueChanged<PlayerAspectRatio> onAspectRatioSelected;

  const AspectRatioSheet({
    super.key,
    required this.currentAspectRatio,
    required this.onAspectRatioSelected,
  });

  static const List<_RatioIconOption> _options = [
    _RatioIconOption(
      ratio: PlayerAspectRatio.original,
      icon: Icons.crop_original_rounded,
      label: 'Auto',
      tooltip: 'Original Source',
    ),
    _RatioIconOption(
      ratio: PlayerAspectRatio.cinema16x9,
      icon: Icons.tv_rounded,
      label: '16:9',
      tooltip: '16:9 Widescreen',
    ),
    _RatioIconOption(
      ratio: PlayerAspectRatio.cinema21x9,
      icon: Icons.panorama_horizontal_rounded,
      label: '21:9',
      tooltip: '21:9 Cinema UltraWide',
    ),
    _RatioIconOption(
      ratio: PlayerAspectRatio.classic4x3,
      icon: Icons.crop_square_rounded,
      label: '4:3',
      tooltip: '4:3 Classic TV',
    ),
    _RatioIconOption(
      ratio: PlayerAspectRatio.fill,
      icon: Icons.fullscreen_rounded,
      label: 'Fill',
      tooltip: 'Fill Screen',
    ),
    _RatioIconOption(
      ratio: PlayerAspectRatio.stretch,
      icon: Icons.open_in_full_rounded,
      label: 'Stretch',
      tooltip: 'Stretch to Fit',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final bg = CyberTheme.getCard(context);
    final activeColor = CyberTheme.primaryBlue;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: activeColor.withValues(alpha: 0.3), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimal Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Horizontal Row with ONLY ICONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _options.map((opt) {
                  final isSelected = opt.ratio == currentAspectRatio;
                  return Tooltip(
                    message: opt.tooltip,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        onAspectRatioSelected(opt.ratio);
                        Navigator.of(context).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.12)
                              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? activeColor : borderColor,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: activeColor.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              opt.icon,
                              size: 24,
                              color: isSelected
                                  ? activeColor
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? activeColor
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatioIconOption {
  final PlayerAspectRatio ratio;
  final IconData icon;
  final String label;
  final String tooltip;

  const _RatioIconOption({
    required this.ratio,
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}
