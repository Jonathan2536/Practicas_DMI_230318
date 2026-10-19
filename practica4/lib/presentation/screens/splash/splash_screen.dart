import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:practica4/presentation/providers/seasonal_theme_provider.dart';
import 'package:practica4/presentation/screens/splash/seasonal_theme.dart';

const _launcherIconChannel = MethodChannel('practica4/seasonal_launcher_icon');

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.destination,
    super.key,
    this.now = DateTime.now,
    this.duration = const Duration(milliseconds: 2500),
  });

  final Widget destination;
  final DateTime Function() now;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SeasonalTheme _theme;
  late final AudioPlayer _audioPlayer;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _theme =
        context.read<SeasonalThemeProvider?>()?.currentTheme ??
        SeasonalTheme.forDate(widget.now());
    _audioPlayer = AudioPlayer();
    unawaited(_updateLauncherIcon());
    unawaited(_playWelcomeAudio());
    _navigationTimer = Timer(widget.duration, _openDestination);
  }

  Future<void> _updateLauncherIcon() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _launcherIconChannel.invokeMethod<void>('setSeasonalLauncherIcon', {
        'theme': _theme.launcherIconTheme,
      });
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Launcher icon channel is unavailable: $error\n$stackTrace');
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Unable to update launcher icon: $error\n$stackTrace');
    }
  }

  Future<void> _playWelcomeAudio() async {
    try {
      await _audioPlayer.play(AssetSource(_theme.audioAsset));
    } on Object catch (error, stackTrace) {
      debugPrint('Unable to play ${_theme.audioAsset}: $error\n$stackTrace');
    }
  }

  void _openDestination() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => widget.destination),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.backgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_theme.backgroundColor, const Color(0xFF09090D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _theme.logoAsset,
                width: 280,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.play_circle_fill_rounded,
                  size: 180,
                  color: _theme.accentColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _theme.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 36,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _theme.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
