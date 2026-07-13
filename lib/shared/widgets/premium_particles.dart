import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config_App/colorsApp.dart';

/// Configuration d'un type de particule
class ParticleConfig {
  final Color color;
  final double minSize;
  final double maxSize;
  final double minSpeed;
  final double maxSpeed;
  final double opacity;
  final int count;

  const ParticleConfig({
    required this.color,
    this.minSize = 1.5,
    this.maxSize = 4.0,
    this.minSpeed = 0.3,
    this.maxSpeed = 1.2,
    this.opacity = 0.6,
    this.count = 30,
  });
}

/// Configurations prédéfinies pour différentes ambiances
class ParticleThemes {
  /// Particules dorées subtiles (splash, premium)
  static const gold = ParticleConfig(
    color: ColorApp.premiumGold,
    minSize: 1.0,
    maxSize: 3.5,
    minSpeed: 0.2,
    maxSpeed: 0.8,
    opacity: 0.5,
    count: 25,
  );

  /// Particules dorées intenses
  static const goldIntense = ParticleConfig(
    color: ColorApp.premiumGoldLight,
    minSize: 1.5,
    maxSize: 5.0,
    minSpeed: 0.3,
    maxSpeed: 1.0,
    opacity: 0.7,
    count: 40,
  );

  /// Particules violettes (créatif)
  static const purple = ParticleConfig(
    color: Color(0xFF9B59B6),
    minSize: 1.5,
    maxSize: 4.0,
    minSpeed: 0.3,
    maxSpeed: 0.9,
    opacity: 0.5,
    count: 35,
  );

  /// Particules cyan/bleu (futuriste)
  static const cyan = ParticleConfig(
    color: Color(0xFF25F4EE),
    minSize: 1.0,
    maxSize: 3.0,
    minSpeed: 0.2,
    maxSpeed: 0.7,
    opacity: 0.4,
    count: 20,
  );

  /// Mélange or + violet (premium luxe)
  static const goldPurple = ParticleConfig(
    color: ColorApp.premiumGold,
    minSize: 1.0,
    maxSize: 4.0,
    minSpeed: 0.2,
    maxSpeed: 0.8,
    opacity: 0.5,
    count: 45,
  );

  /// Particules minimalistes
  static const minimal = ParticleConfig(
    color: Colors.white,
    minSize: 0.5,
    maxSize: 2.0,
    minSpeed: 0.1,
    maxSpeed: 0.4,
    opacity: 0.3,
    count: 15,
  );
}

/// Particule individuelle
class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double wobble;
  double wobbleSpeed;
  final Color color;
  final Random _random;

  _Particle({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wobble,
    required this.wobbleSpeed,
    required Random random,
  }) : _random = random;

  void update(double width, double height, double deltaTime) {
    // Mouvement vertical vers le haut
    y -= speed * deltaTime * 60;

    // Mouvement de wobble (mouvement sinusoïdal horizontal)
    wobble += wobbleSpeed * deltaTime * 60;
    x += sin(wobble) * 0.5;

    // Réinitialiser quand la particule sort de l'écran
    if (y < -size) {
      y = height + size;
      x = _random.nextDouble() * width;
      size = _random.nextDouble() * 3.0 + 1.0;
      speed = _random.nextDouble() * 0.8 + 0.2;
      opacity = _random.nextDouble() * 0.4 + 0.2;
    }
  }
}

/// Widget de fond animé avec particules premium
class PremiumParticleBackground extends StatefulWidget {
  final Widget? child;
  final ParticleConfig config;
  final bool showGradient;

  const PremiumParticleBackground({
    super.key,
    this.child,
    this.config = ParticleThemes.gold,
    this.showGradient = true,
  });

  @override
  State<PremiumParticleBackground> createState() =>
      _PremiumParticleBackgroundState();
}

class _PremiumParticleBackgroundState extends State<PremiumParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  late ParticleConfig _config;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);
    _initParticles();
    _controller.repeat();
  }

  @override
  void didUpdateWidget(PremiumParticleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _config = widget.config;
      _particles.clear();
      _initParticles();
    }
  }

  void _initParticles() {
    for (int i = 0; i < _config.count; i++) {
      _particles.add(_Particle(
        color: _config.color,
        x: _random.nextDouble() * (Get?.width ?? 400),
        y: _random.nextDouble() * (Get?.height ?? 800),
        size: _random.nextDouble() * (_config.maxSize - _config.minSize) +
            _config.minSize,
        speed: _random.nextDouble() * (_config.maxSpeed - _config.minSpeed) +
            _config.minSpeed,
        opacity: _random.nextDouble() * _config.opacity * 0.5 + _config.opacity * 0.5,
        wobble: _random.nextDouble() * 2 * pi,
        wobbleSpeed: _random.nextDouble() * 0.03 + 0.01,
        random: _random,
      ));
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;

    if (mounted) {
      final size = context.size;
      if (size != null) {
        for (final particle in _particles) {
          particle.update(size.width, size.height, deltaTime);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Fond avec dégradé
            if (widget.showGradient)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _config.color.withValues(alpha: 0.04),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      radius: 1.5,
                      center: const Alignment(0.3, -0.3),
                    ),
                  ),
                ),
              ),
            // Particules
            Positioned.fill(
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  config: _config,
                ),
              ),
            ),
            // Contenu enfant
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

/// Painter qui dessine les particules
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final ParticleConfig config;

  _ParticlePainter({
    required this.particles,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );

      // Effet de glow (cercle plus grand et plus transparent)
      if (particle.size > 2.0) {
        final glowPaint = Paint()
          ..color = particle.color.withValues(
            alpha: particle.opacity * 0.3,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size * 2.5,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
