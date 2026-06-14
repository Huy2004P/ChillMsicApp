import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/localization/localization_extension.dart';
import 'main_navigation_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _entryController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _letterSpacingAnimation;

  // List of particle configurations for 3D depth simulation
  final List<SplashParticle> _particles = List.generate(24, (index) {
    final random = math.Random(index);
    return SplashParticle(
      angle: random.nextDouble() * 2 * math.pi,
      radius: 80.0 + random.nextDouble() * 140.0,
      size: 2.0 + random.nextDouble() * 5.0,
      depth: -50.0 + random.nextDouble() * 150.0, // Z depth
      speed: 0.5 + random.nextDouble() * 1.5,
      color: index % 3 == 0 
          ? const Color(0xFF00FFCC).withAlpha(160) // Neon Teal
          : (index % 3 == 1 
              ? const Color(0xFF0054FF).withAlpha(160) // Cobalt Blue
              : const Color(0xFFFF007F).withAlpha(160)), // Neon Pink
    );
  });

  @override
  void initState() {
    super.initState();

    // Continuous 3D rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Intro entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );

    _letterSpacingAnimation = Tween<double>(begin: 14.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _entryController.forward();

    // Navigate to home after delay
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0D172E), // Deep space navy
              Color(0xFF04060A), // Near black
              Colors.black,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background atmospheric glows
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0054FF).withAlpha(45),
                      blurRadius: 100,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF007F).withAlpha(45),
                      blurRadius: 100,
                    ),
                  ],
                ),
              ),
            ),

            // 3D Parallax floating particles
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                final val = _rotationController.value * 2 * math.pi;
                return Stack(
                  children: _particles.map((p) {
                    // Compute particle position with Z depth perspective transformation
                    final currentAngle = p.angle + (val * p.speed * 0.1);
                    final x = math.cos(currentAngle) * p.radius;
                    final y = math.sin(currentAngle) * p.radius * 0.6; // Flatten circle to match 3D angle

                    return Center(
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015) // perspective
                          ..translate(x, y, p.depth),
                        child: Container(
                          width: p.size,
                          height: p.size,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: p.color.withAlpha(200),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Center content: 3D vinyl and glowing text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        // Custom matrix perspective rotation
                        final angleZ = _rotationController.value * 2 * math.pi;
                        final tiltX = 0.65; // Tilted towards the screen
                        final tiltY = -0.15; // Slightly rotated left

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // 3D Shadow underneath the vinyl
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015)
                                ..rotateX(tiltX)
                                ..rotateY(tiltY)
                                ..translate(0.0, 24.0, -25.0),
                              alignment: Alignment.center,
                              child: Container(
                                width: 176,
                                height: 176,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(180),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Opposing Orbiting Cyber Ring
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015)
                                ..rotateX(tiltX)
                                ..rotateY(tiltY)
                                ..rotateZ(-angleZ * 0.4), // opposite spin
                              alignment: Alignment.center,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00FFCC).withAlpha(60),
                                    width: 1.2,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Orbit nodes
                                    Positioned(
                                      top: 12,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF00FFCC),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFFF007F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Rotating Vinyl Disk
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015) // Perspective depth
                                ..rotateX(tiltX)
                                ..rotateY(tiltY)
                                ..rotateZ(angleZ), // Spin
                              alignment: Alignment.center,
                              child: const VinylDiskWidget(),
                            ),

                            // Static Shiny Gloss Reflection Overlay
                            IgnorePointer(
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0015)
                                  ..rotateX(tiltX)
                                  ..rotateY(tiltY), // Tilted but not spinning
                                alignment: Alignment.center,
                                child: const GlassShineOverlay(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 54),

                  // Glowing Branding Text
                  AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ChillMsic'.toUpperCase(),
                              style: AppTypography.heroDisplay.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: _letterSpacingAnimation.value,
                                shadows: [
                                  Shadows.neonGlow(const Color(0xFF0054FF), 12.0),
                                  Shadows.neonGlow(const Color(0xFFFF007F), 6.0),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Premium Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0054FF).withAlpha(25),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(0xFF0054FF).withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'PREMIUM AUDIO PLAYER',
                                style: AppTypography.captionBold.copyWith(
                                  color: const Color(0xFF00FFCC),
                                  fontSize: 8,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The Sound of Horizon',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white60,
                                fontSize: 10,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom API Copyright & Educational Disclaimer Footer
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('splash_copyright'),
                          textAlign: TextAlign.center,
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white70,
                            fontSize: 10.5,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('splash_disclaimer'),
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Particle model for 3D positioning
class SplashParticle {
  final double angle;
  final double radius;
  final double size;
  final double depth;
  final double speed;
  final Color color;

  const SplashParticle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.depth,
    required this.speed,
    required this.color,
  });
}

// High-fidelity Vinyl Disk representation
class VinylDiskWidget extends StatelessWidget {
  const VinylDiskWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF09090B),
        border: Border.all(
          color: const Color(0xFF27272A).withAlpha(120),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0054FF).withAlpha(60),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vinyl Grooves (thin concentric circles)
          ...List.generate(6, (index) {
            final double radiusOffset = 24.0 + (index * 11.0);
            return Container(
              width: radiusOffset * 2,
              height: radiusOffset * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(8 + (index % 2 * 6)),
                  width: 0.8,
                ),
              ),
            );
          }),

          // Center Label Sticker with App Icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1F2937).withAlpha(150),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0054FF).withAlpha(100),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/playstore.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Spindle hole
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black, // Spindle hole
                ),
              ),
            ],
          ),

          // Metallic / Neon Stylus Accent Dot
          Positioned(
            right: 48,
            top: 48,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00FFCC), // Neon Green/Teal dot
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Glassmorphism reflection overlay
class GlassShineOverlay extends StatelessWidget {
  const GlassShineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          colors: [
            Colors.white.withAlpha(45),
            Colors.white.withAlpha(15),
            Colors.transparent,
            Colors.white.withAlpha(20),
            Colors.white.withAlpha(50),
          ],
        ),
      ),
    );
  }
}

// Helper utility for neon text shadow
class Shadows {
  static Shadow neonGlow(Color color, double radius) {
    return Shadow(
      color: color.withAlpha(180),
      blurRadius: radius,
    );
  }
}
