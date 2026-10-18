import 'package:flutter/material.dart';

final class SeasonalTheme {
  const SeasonalTheme({
    required this.name,
    required this.logoAsset,
    required this.audioAsset,
    required this.launcherIconTheme,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String name;
  final String logoAsset;
  final String audioAsset;
  final String launcherIconTheme;
  final Color backgroundColor;
  final Color accentColor;

  static const normal = SeasonalTheme(
    name: 'TokTik',
    logoAsset: 'assets/images/logo_normal.png',
    audioAsset: 'audio/audio_normal.mp3',
    launcherIconTheme: 'normal',
    backgroundColor: Color(0xFF17171D),
    accentColor: Color(0xFFB9A6FF),
  );

  static const halloween = SeasonalTheme(
    name: 'Halloween',
    logoAsset: 'assets/images/logo_halloween.png',
    audioAsset: 'audio/audio_halloween.mp3',
    launcherIconTheme: 'halloween',
    backgroundColor: Color(0xFF1B1025),
    accentColor: Color(0xFFFF8A35),
  );

  static const christmas = SeasonalTheme(
    name: 'Navidad',
    logoAsset: 'assets/images/logo_navidad.png',
    audioAsset: 'audio/audio_navidad.mp3',
    launcherIconTheme: 'christmas',
    backgroundColor: Color(0xFF10251B),
    accentColor: Color(0xFFE34B54),
  );

  static const valentine = SeasonalTheme(
    name: 'San Valentín',
    logoAsset: 'assets/images/logo_sanvalentin.png',
    audioAsset: 'audio/audio_sanvalentin.mp3',
    launcherIconTheme: 'valentine',
    backgroundColor: Color(0xFF2A111B),
    accentColor: Color(0xFFFF718B),
  );

  static const values = [normal, halloween, christmas, valentine];

  static SeasonalTheme? fromId(String id) {
    for (final theme in values) {
      if (theme.launcherIconTheme == id) return theme;
    }
    return null;
  }

  static SeasonalTheme forDate(DateTime date) {
    if ((date.month == 10 && date.day >= 20) ||
        (date.month == 11 && date.day <= 3)) {
      return halloween;
    }
    if (date.month == 12) return christmas;
    if (date.month == 2 && date.day >= 10 && date.day <= 18) {
      return valentine;
    }
    return normal;
  }
}
