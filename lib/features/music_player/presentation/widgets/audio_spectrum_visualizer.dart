import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/service/audio_player_service.dart';
import '../../../../core/theme/colors.dart';
import '../bloc/player_bloc.dart';

class AudioSpectrumVisualizer extends StatefulWidget {
  const AudioSpectrumVisualizer({super.key});

  @override
  State<AudioSpectrumVisualizer> createState() => _AudioSpectrumVisualizerState();
}

class _AudioSpectrumVisualizerState extends State<AudioSpectrumVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final int _barCount = 20;
  late List<double> _heights;
  final math.Random _random = math.Random();
  double _phase = 0.0;

  @override
  void initState() {
    super.initState();
    _heights = List.filled(_barCount, 4.0);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    
    final state = context.read<PlayerBloc>().state;
    final isPlaying = state.playerState == AudioPlayerState.playing;
    final isBuffering = state.playerState == AudioPlayerState.buffering;

    _phase += 0.15;
    if (_phase > 2 * math.pi) {
      _phase -= 2 * math.pi;
    }

    // Determine base scale based on state
    double baseAmplitude = 0.05;
    if (isBuffering) {
      baseAmplitude = 0.25; // Gentle wave during buffer
    } else if (isPlaying) {
      baseAmplitude = 0.75; // Active bouncing
    }

    // EQ Influence Modifiers
    final eqBands = state.eqBands;
    final double bassGain = ((eqBands['60 Hz'] ?? 0.0) + (eqBands['230 Hz'] ?? 0.0)) / 2.0;
    final double midGain = eqBands['910 Hz'] ?? 0.0;
    final double trebleGain = ((eqBands['4 kHz'] ?? 0.0) + (eqBands['14 kHz'] ?? 0.0)) / 2.0;

    // Convert dB gain (-12 to +12) to scale factors (0.4 to 1.8)
    final double bassScale = math.pow(10, bassGain / 40.0).toDouble().clamp(0.4, 1.8);
    final double midScale = math.pow(10, midGain / 40.0).toDouble().clamp(0.5, 1.5);
    final double trebleScale = math.pow(10, trebleGain / 40.0).toDouble().clamp(0.4, 1.8);

    // Bitrate variance
    final double bitrateScale = state.currentBitrate > 0 
        ? (state.currentBitrate / 920.0).clamp(0.7, 1.3)
        : 1.0;

    for (int i = 0; i < _barCount; i++) {
      double target = 4.0; // minimum height

      if (isBuffering) {
        // Slow scrolling sine wave
        target = 4.0 + (12.0 * (math.sin(_phase + (i * 0.4)) + 1.0));
      } else if (isPlaying) {
        // Generate pseudo-random spectrum columns reacting to EQ
        double eqScale = 1.0;
        if (i < _barCount * 0.3) {
          eqScale = bassScale; // Bass region
        } else if (i < _barCount * 0.7) {
          eqScale = midScale;  // Vocals/Mid region
        } else {
          eqScale = trebleScale; // Treble/High region
        }

        // Noise base
        final noise = _random.nextDouble();
        final waveVal = math.sin(_phase * 2 + i * 0.8) * 0.3 + 0.7;
        
        // Target calculation
        target = 4.0 + (32.0 * noise * waveVal * baseAmplitude * eqScale * bitrateScale);
      } else {
        // Paused/Idle: settle to flatline
        target = 4.0 + (1.5 * math.sin(_phase + i));
      }

      // Smooth interpolation: height = height + (target - height) * speed
      final double smoothFactor = isPlaying ? 0.3 : 0.15;
      _heights[i] = _heights[i] + (target - _heights[i]) * smoothFactor;
    }

    // Force paint update
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: CustomPaint(
        painter: _SpectrumPainter(
          heights: _heights,
          isDarkMode: context.select((PlayerBloc bloc) => bloc.state.isDarkMode),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double> heights;
  final bool isDarkMode;

  _SpectrumPainter({required this.heights, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final int barCount = heights.length;
    final double spacing = 4.0;
    final double totalSpacing = spacing * (barCount - 1);
    final double barWidth = (size.width - totalSpacing) / barCount;

    final Paint barPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final double barHeight = heights[i];
      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      // Neon Gradient paint
      final Gradient gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.primary.withAlpha(180), // Cobalt Blue base
          const Color(0xFF00FFCC),           // Neon Green-Cyan peak
        ],
      );

      barPaint.shader = gradient.createShader(
        Rect.fromLTWH(x, y, barWidth, barHeight),
      );

      // Draw shadow glow for active bars
      if (barHeight > 8.0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = AppColors.primary.withAlpha(isDarkMode ? 40 : 20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.drawRRect(rrect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) => true;
}
