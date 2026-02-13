import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:kongossa/config_App/colorsApp.dart';
import 'package:kongossa/presentation/component/widget/widget_component.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'dart:math';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../sevice/upload/select_image.dart';
import 'package:path/path.dart' as path;

import '../../../sevice/upload/upload_cloud.dart';
import '../style/custum_text.dart';

class PremiumMediaSelector extends StatefulWidget {
  final Function(MediaSource) onSourceSelected;
  final String? title;
  final String? description;

  const PremiumMediaSelector({
    super.key,
    required this.onSourceSelected,
    this.title = "Ajouter une photo",
    this.description = "Choisissez la source de l'image",
  });

  @override
  State<PremiumMediaSelector> createState() => _PremiumMediaSelectorState();
}

enum MediaSource { camera, gallery }

class _PremiumMediaSelectorState extends State<PremiumMediaSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  MediaSource? _hoveredSource;
  UniversalCloudinaryUploader _serviceall = UniversalCloudinaryUploader();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -10,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSourceTap(MediaSource source) {
    _controller.reverse().then((_) {
      widget.onSourceSelected(source);
    });
  }

  void _onSourceHover(MediaSource? source) {
    setState(() {
      _hoveredSource = source;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorApp.background.withOpacity(0.95),
                ColorApp.background.withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête avec animation
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - _controller.value) * 30),
                          child: Opacity(
                            opacity: _controller.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // Icône animée
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [ColorApp.primary1, ColorApp.primary2],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorApp.primary1.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_camera,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Titre
                          Text(
                            widget.title!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ColorApp.primary3,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Description
                          Text(
                            widget.description!,
                            style: TextStyle(
                              fontSize: 16,
                              color: ColorApp.primary3.withOpacity(0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Options de sélection
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSourceCard(
                          source: MediaSource.camera,
                          icon: Icons.camera_alt_rounded,
                          title: "Caméra",
                          subtitle: "Prendre une photo",
                          color: Colors.blue,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                        ),

                        // const SizedBox(width: 24),
                        _buildSourceCard(
                          source: MediaSource.gallery,
                          icon: Icons.photo_library_rounded,
                          title: "Galerie",
                          subtitle: "Choisir une image",
                          color: Colors.purple,
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton annuler
                  MouseRegion(
                    onEnter: (_) => _onSourceHover(null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                        color: Colors.transparent,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _controller.reverse().then((_) {
                            Navigator.of(context).pop();
                          }),
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.grey.withOpacity(0.1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            child: Text(
                              "Annuler",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorApp.primary3.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required MediaSource source,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Gradient gradient,
  }) {
    final isHovered = _hoveredSource == source;

    return MouseRegion(
      onEnter: (_) => _onSourceHover(source),
      onExit: (_) => _onSourceHover(null),
      child: GestureDetector(
        // onTap: () => _onSourceTap(source),
        onTap: () async {
          print(source.name);
          final pickedFile = await SelectImage.takeAndUploadPhoto(
            iscamera: source.name == "camera" ? true : false,
          );

          if (pickedFile != null) {
            updateimage() async {
              String originalName = path.basename(pickedFile.path);
              print(originalName);
              print(pickedFile.path);
              print("pickedFile.path 1");
              //  await _services.uploadImageSigned(imageFile: File(pickedFile.path));
              final url = await _serviceall.uploadAnyFile(
                filePath: pickedFile.path,
                folder: "kogossa_app/secure",
                fileName: originalName,
              );
              if (url != null) {
                print("pickedFile.path 2");
                print(url);
                print("pickedFile.path 2");
                QuerySnapshot querySnapshot = await Users.where(
                  'googleId',
                  isEqualTo: AppUser.info?.googleId,
                ).get();
                Users.doc(
                  querySnapshot.docs.first.id,
                ).update({'photoUrl': "${url}"});
              }
            }

            WidgetComponent.getdialog(
              sectionview: Container(
                child: Stack(
                  children: [
                    Image.file(pickedFile),
                    Positioned(bottom: 1.h,
                      right: 1.w,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.until((route) => !(Get.isDialogOpen==true || Get.isBottomSheetOpen==true));
                          updateimage();
                        },
                        child:CustomText("valider",   type: TextType.button,),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          width: isHovered ? 170 : 160,
          height: isHovered ? 200 : 190,
          decoration: BoxDecoration(
            gradient: isHovered
                ? gradient
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered
                  ? color.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: isHovered ? 2 : 1,
            ),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Effet de particules sur hover
              if (isHovered)
                Positioned.fill(child: _ParticleEffect(color: color)),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône avec animation
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isHovered ? 70 : 60,
                        height: isHovered ? 70 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHovered
                              ? Colors.white
                              : color.withOpacity(0.1),
                          boxShadow: [
                            if (isHovered)
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: isHovered ? 32 : 28,
                          color: isHovered ? color : color.withOpacity(0.8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Titre
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isHovered ? Colors.white : ColorApp.primary3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sous-titre
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isHovered
                            ? Colors.white.withOpacity(0.9)
                            : ColorApp.primary3.withOpacity(0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Indicateur de sélection
                    if (isHovered)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Effet de particules animées
class _ParticleEffect extends StatefulWidget {
  final Color color;

  const _ParticleEffect({required this.color});

  @override
  State<_ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<_ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Créer des particules
    for (int i = 0; i < 15; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * 200,
          y: _random.nextDouble() * 200,
          size: _random.nextDouble() * 4 + 2,
          speed: _random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            controllerValue: _particleController.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class Particle {
  double x, y;
  double size;
  double speed;
  double angle;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  }) : angle = Random().nextDouble() * 2 * pi;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double controllerValue;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.controllerValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      // Animation des particules
      final offsetX = sin(controllerValue * 2 * pi + particle.angle) * 10;
      final offsetY = cos(controllerValue * 2 * pi + particle.angle) * 10;

      canvas.drawCircle(
        Offset(particle.x + offsetX, particle.y + offsetY),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true;
  }
}

// Utilisation dans une Bottom Sheet Premium
Future<MediaSource?> showPremiumMediaSelector(BuildContext context) {
  return showModalBottomSheet<MediaSource>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        color: Colors.black.withOpacity(0.4),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withOpacity(0.2),
            BlendMode.darken,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              PremiumMediaSelector(
                onSourceSelected: (source) {
                  Navigator.of(context).pop(source);
                },
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        ),
      );
    },
  );
}

// Utilisation dans un Dialog Premium
Future<MediaSource?> showPremiumMediaDialog(BuildContext context) {
  return showDialog<MediaSource>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: PremiumMediaSelector(
          onSourceSelected: (source) {
            Navigator.of(context).pop(source);
          },
        ),
      );
    },
  );
}
