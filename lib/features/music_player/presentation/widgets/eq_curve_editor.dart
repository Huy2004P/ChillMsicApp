import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

class EqCurveEditor extends StatefulWidget {
  final Map<String, double> bands;
  final Function(String band, double value) onBandChanged;

  const EqCurveEditor({
    super.key,
    required this.bands,
    required this.onBandChanged,
  });

  @override
  State<EqCurveEditor> createState() => _EqCurveEditorState();
}

class _EqCurveEditorState extends State<EqCurveEditor> {
  int? _activeBandIndex;

  static const List<String> bandKeys = [
    '60 Hz',
    '230 Hz',
    '910 Hz',
    '4 kHz',
    '14 kHz',
  ];

  double _getBandX(int index, double width, double padding) {
    return padding + index * (width - 2 * padding) / (bandKeys.length - 1);
  }

  double _getYToGain(double y, double height, double padding) {
    final double workableHeight = height - 2 * padding;
    final double relativeY = height - padding - y;
    final double normalized = relativeY / workableHeight;
    final double gain = (normalized * 24.0) - 12.0;
    return gain.clamp(-12.0, 12.0);
  }

  void _handlePointer(Offset localPosition, double width, double height, double padding) {
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < bandKeys.length; i++) {
      final double bandX = _getBandX(i, width, padding);
      final double dist = (localPosition.dx - bandX).abs();
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    if (minDistance < width / (bandKeys.length * 1.5)) {
      setState(() {
        _activeBandIndex = closestIndex;
      });
      final double newGain = _getYToGain(localPosition.dy, height, padding);
      final String bandKey = bandKeys[closestIndex];
      final double roundedGain = (newGain * 2).round() / 2.0;
      widget.onBandChanged(bandKey, roundedGain);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight.isInfinite ? 200.0 : constraints.maxHeight;

        return GestureDetector(
          onPanStart: (details) {
            _handlePointer(details.localPosition, width, height, padding);
          },
          onPanUpdate: (details) {
            _handlePointer(details.localPosition, width, height, padding);
          },
          onPanEnd: (_) {
            setState(() {
              _activeBandIndex = null;
            });
          },
          child: CustomPaint(
            size: Size(width, height),
            painter: _EqCurvePainter(
              bands: widget.bands,
              bandKeys: bandKeys,
              activeBandIndex: _activeBandIndex,
              padding: padding,
              isDarkMode: AppColors.isDarkMode,
            ),
          ),
        );
      },
    );
  }
}

class _EqCurvePainter extends CustomPainter {
  final Map<String, double> bands;
  final List<String> bandKeys;
  final int? activeBandIndex;
  final double padding;
  final bool isDarkMode;

  _EqCurvePainter({
    required this.bands,
    required this.bandKeys,
    required this.activeBandIndex,
    required this.padding,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final gridPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1D283D) : const Color(0xFFE4E6EB)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashedGridPaint = Paint()
      ..color = isDarkMode ? const Color(0x338A9CAF) : const Color(0x33657786)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final List<double> dbs = [12, 6, 0, -6, -12];
    for (final db in dbs) {
      final double y = _getBandY(db, height, padding);
      
      if (db == 0) {
        final centerPaint = Paint()
          ..color = isDarkMode ? const Color(0x668A9CAF) : const Color(0x66657786)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(0, y), Offset(width, y), centerPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
      }

      textPainter.text = TextSpan(
        text: '${db > 0 ? '+' : ''}$db dB',
        style: TextStyle(
          color: isDarkMode ? const Color(0xFF657786) : const Color(0xFF8D99AE),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height - 2));
    }

    final List<Offset> points = [];
    for (int i = 0; i < bandKeys.length; i++) {
      final String key = bandKeys[i];
      final double gain = bands[key] ?? 0.0;
      final double x = _getBandX(i, width, padding);
      final double y = _getBandY(gain, height, padding);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < bandKeys.length; i++) {
      final double x = _getBandX(i, width, padding);
      canvas.drawLine(Offset(x, padding), Offset(x, height - padding), dashedGridPaint);

      textPainter.text = TextSpan(
        text: bandKeys[i],
        style: TextStyle(
          color: activeBandIndex == i
              ? AppColors.primary
              : (isDarkMode ? const Color(0xFF8A9CAF) : const Color(0xFF4B5A64)),
          fontSize: 10,
          fontWeight: activeBandIndex == i ? FontWeight.bold : FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, height - padding + 4),
      );
    }

    if (points.isNotEmpty) {
      final Path path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        
        final double controlXOffset = (p1.dx - p0.dx) / 2;
        final Offset cp1 = Offset(p0.dx + controlXOffset, p0.dy);
        final Offset cp2 = Offset(p1.dx - controlXOffset, p1.dy);

        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }

      final double zeroY = _getBandY(0.0, height, padding);
      final Path fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, zeroY);
      fillPath.lineTo(points.first.dx, zeroY);
      fillPath.close();

      // Avoid withOpacity deprecation warning
      final fillGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x400054FF), // 25% opacity
          Color(0x000054FF), // 0% opacity
        ],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTRB(points.first.dx, padding, points.last.dx, height - padding),
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      final curvePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final glowPaint = Paint()
        ..color = const Color(0x590054FF) // 35% opacity
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, curvePaint);
    }

    for (int i = 0; i < points.length; i++) {
      final Offset pt = points[i];
      final bool isActive = activeBandIndex == i;

      final nodeGlowPaint = Paint()
        ..color = isActive ? const Color(0x800054FF) : const Color(0x330054FF) // 50% vs 20% opacity
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isActive ? 8.0 : 4.0);
      canvas.drawCircle(pt, isActive ? 14.0 : 10.0, nodeGlowPaint);

      final nodeBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      final nodeFillPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, isActive ? 7.0 : 5.5, nodeFillPaint);
      canvas.drawCircle(pt, isActive ? 7.0 : 5.5, nodeBorderPaint);
    }
  }

  double _getBandX(int index, double width, double padding) {
    return padding + index * (width - 2 * padding) / (bandKeys.length - 1);
  }

  double _getBandY(double gain, double height, double padding) {
    final double workableHeight = height - 2 * padding;
    final double normalized = (gain + 12.0) / 24.0;
    return height - padding - (normalized * workableHeight);
  }

  @override
  bool shouldRepaint(covariant _EqCurvePainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.activeBandIndex != activeBandIndex ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

class EqBandLevelMeter extends StatelessWidget {
  final Map<String, double> bands;
  final bool isDarkMode;

  const EqBandLevelMeter({
    super.key,
    required this.bands,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> bandKeys = [
      '60 Hz',
      '230 Hz',
      '910 Hz',
      '4 kHz',
      '14 kHz',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: bandKeys.map((freq) {
        final double dbValue = bands[freq] ?? 0.0;
        // Map -12.0 to +12.0 to 0.0 to 1.0 progress ratio
        final double progress = ((dbValue + 12.0) / 24.0).clamp(0.0, 1.0);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0x1A172033) : const Color(0x10F2F4F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.hairlineSoft.withAlpha(isDarkMode ? 40 : 20),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  freq,
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.charcoal,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 6),
                // Mini vertical level indicator bar
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.hairlineSoft.withAlpha(80),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 32 * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withAlpha(100),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dbValue > 0 ? '+' : ''}${dbValue.toStringAsFixed(1)}',
                  style: AppTypography.captionBold.copyWith(
                    color: dbValue == 0.0
                        ? AppColors.charcoal
                        : (dbValue > 0 ? const Color(0xFF00FF99) : const Color(0xFFFA3E3E)),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
