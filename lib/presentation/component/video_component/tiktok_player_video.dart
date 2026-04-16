import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../screens/profil_screen.dart';
import '../../../sevice/upload/upload_post.dart';
import '../image_component/image.dart';
import '../widget/widget_component.dart';
import 'comment_video.dart';

class TikTokVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String username;
  final String description;
  final String music;
  final String? uid;
  final String? mail;
  final String? bio;
  final int likes;
  final bool isLiked;
  final bool start;
  final String id;
  final int comments;
  final int shares;
  final VoidCallback? onSeekStarted;
  final VoidCallback? onSeekEnded;
  final String profileImage;
  final List<dynamic>? alllike;
  final List<dynamic>? allsee;

  const TikTokVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.username,
    required this.description,
    required this.music,
    this.likes = 0,
    this.isLiked = false,
    this.onSeekStarted, // Nouveau paramètre
    this.onSeekEnded, // Nouveau paramètre
    required this.id,
    this.comments = 0,
    this.shares = 0,
    this.start = false,
    this.alllike,
    this.allsee,
    required this.profileImage,
    this.uid,
    this.mail,
    this.bio,
  }) : super(key: key);

  @override
  _TikTokVideoPlayerState createState() => _TikTokVideoPlayerState();
}

class _TikTokVideoPlayerState extends State<TikTokVideoPlayer>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // GlobalKey pour référencer cette instance
  static final GlobalKey<_TikTokVideoPlayerState> fullscreenKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  late VideoPlayerController _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isMuted = false;
  bool _isLiked = false;
  bool _issee = false;
  bool _showPlayPauseIcon = false;
  bool _isFollowing = false;
  int _likeCount = 0;
  Timer? _doubleTapTimer;
  bool _showHeartAnimation = false;
  Offset _heartPosition = Offset.zero;
  bool _isControllerReady = false;
  bool _isUsingCache = false;
  late AnimationController _pulseController;
  final PostUpdateService service = PostUpdateService();
  StreamSubscription? _visibilitySubscription;
  bool _isDisposed = false;
  Timer? _replayTimer;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
    _isLiked = widget.alllike?.contains(AppUser.info?.googleId) ?? false;
    _issee = widget.allsee?.contains(AppUser.info?.googleId) ?? false;

    debugPrint("📹 Initialisation vidéo: ${widget.videoUrl}");

    _pulseController =
        AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        )..addListener(() {
          if (mounted) setState(() {});
        });

    _initializePlayer();
  }

  /// Nettoie l'URL des caractères indésirables
  String _cleanUrl(String url) {
    return url.trim().replaceAll(RegExp(r'^[\[\]"]+|[\[\]"]+$'), '');
  }

  /// Vérifie si la vidéo est en cache
  Future<File?> _getCachedVideo() async {
    try {
      final cleanUrl = _cleanUrl(widget.videoUrl);
      final fileInfo = await DefaultCacheManager().getFileFromCache(cleanUrl);

      if (fileInfo != null && fileInfo.file.existsSync()) {
        debugPrint('✅ Vidéo trouvée en cache');
        return fileInfo.file;
      }
      debugPrint('❌ Vidéo non trouvée en cache');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur vérification cache: $e');
      return null;
    }
  }

  /// Télécharge la vidéo pour le cache
  Future<void> _downloadVideoForCache() async {
    try {
      final cleanUrl = _cleanUrl(widget.videoUrl);
      await DefaultCacheManager().downloadFile(cleanUrl);
      debugPrint('⬇️ Vidéo téléchargée pour le cache');
    } catch (e) {
      debugPrint('❌ Échec téléchargement cache: $e');
    }
  }

  /// Initialise le lecteur vidéo
  Future<void> _initializePlayer() async {
    if (_isDisposed) return;

    try {
      final cleanUrl = _cleanUrl(widget.videoUrl);

      if (cleanUrl.isEmpty) {
        throw Exception('URL vidéo vide');
      }

      // Vérifier le cache d'abord
      final cachedFile = await _getCachedVideo();

      if (cachedFile != null && mounted) {
        // Lecture depuis le cache
        _controller = VideoPlayerController.file(cachedFile);
        _isUsingCache = true;
        debugPrint('🎬 Lecture depuis le CACHE');
      } else {
        // Lecture depuis le réseau
        _controller = VideoPlayerController.networkUrl(Uri.parse(cleanUrl));
        _isUsingCache = false;
        debugPrint('🌐 Lecture depuis le RÉSEAU');

        // Téléchargement en arrière-plan
        _downloadVideoForCache();
      }

      // Ajouter les listeners
      _controller.addListener(_onVideoControllerListener);

      // Initialiser
      _initializeVideoPlayerFuture = _controller
          .initialize()
          .then((_) {
            if (mounted && !_isDisposed) {
              setState(() {
                _controller.setLooping(false);
                _controller.setVolume(_isMuted ? 0 : 1);
                widget.start == false
                    ? _controller.pause()
                    : _controller.play();

                _isControllerReady = true;
              });
            }
          })
          .catchError((error) {
            debugPrint('💥 Erreur initialisation: $error');
            if (mounted && !_isDisposed) {
              _handleInitializationError();
            }
          });
    } catch (e) {
      debugPrint('💥 ERREUR CRITIQUE: $e');
      if (mounted && !_isDisposed) {
        _handleInitializationError();
      }
    }
  }

  void _onVideoControllerListener() {
    if (!mounted || _isDisposed) return;

    // Détecter la fin de la vidéo
    if (_controller.value.position == _controller.value.duration &&
        _controller.value.isPlaying == false) {
      print("video terminée");


      // Vidéo terminée, on laisse l'UI gérer l'affichage du bouton replay
      setState(() {});
    }
  }

  /// Gestionnaire d'erreur avec fallback
  void _handleInitializationError() {
    const fallbackUrl =
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

    _controller = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
    _controller.addListener(_onVideoControllerListener);

    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      if (mounted && !_isDisposed) {
        setState(() {
          _controller.setLooping(false);
          _controller.setVolume(_isMuted ? 0 : 1);
          _isControllerReady = true;
        });
      }
    });
  }

  /// Passe à la version en cache si disponible
  Future<void> _refreshWithCachedVersion() async {
    if (_isUsingCache || !mounted || _isDisposed) return;

    final cachedFile = await _getCachedVideo();
    if (cachedFile != null && mounted && !_isDisposed) {
      final oldPosition = _controller.value.position;
      final wasPlaying = _controller.value.isPlaying;

      final newController = VideoPlayerController.file(cachedFile);
      await newController.initialize();

      if (mounted && !_isDisposed) {
        setState(() {
          final oldController = _controller;
          _controller = newController;
          _controller.addListener(_onVideoControllerListener);
          _controller.setLooping(widget.start == false ? false : true);
          _controller.setVolume(_isMuted ? 0 : 1);
          _controller.seekTo(oldPosition);
          if (wasPlaying) _controller.play();
          _isControllerReady = true;
          _isUsingCache = true;

          oldController.removeListener(_onVideoControllerListener);
          oldController.dispose();
        });

        debugPrint('🔄 Basculement vers version CACHE');
      }
    }
  }

  void _toggleLike() {
    if (!mounted) return;

    setState(() {
      _showHeartAnimation = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    service.toggleLike(
      postId: widget.id,
      // isLiked: _isLiked,
      // like: widget.likes,
    );
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (!mounted) return;

    setState(() {
      _heartPosition = details.localPosition;
      _showHeartAnimation = true;

      if (!_isLiked) {
        _isLiked = true;
        _likeCount += 1;
        _pulseController.forward().then((_) => _pulseController.reset());
      }
    });

    service.toggleLike(
      postId: widget.id,
      // isLiked: true,
      // like: widget.likes,
    );

    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  void _onVideoEnded() {
    debugPrint('📹 Vidéo terminée');
    // L'UI affichera automatiquement le bouton replay
  }

  // Méthode pour ouvrir le plein écran
  void _openFullscreen() {
    Get.to(
      () => FullscreenVideoPlayer(controller: _controller, state: this),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    )?.then((_) {
      // Au retour, rien à faire car on garde le même contrôleur
      if (mounted && !_isDisposed) {
        setState(() {}); // Rafraîchir l'UI si nécessaire
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _doubleTapTimer?.cancel();
    _replayTimer?.cancel();
    _visibilitySubscription?.cancel();
    _pulseController.dispose();

    if (_controller.value.isInitialized) {
      _controller.removeListener(_onVideoControllerListener);
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Pour AutomaticKeepAliveClientMixin

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: VisibilityDetector(
        key: Key('visibility_${widget.id}'),
        onVisibilityChanged: (visibilityInfo) {
          if (!_isControllerReady || _isDisposed) return;

          final visibleFraction = visibilityInfo.visibleFraction;

          if (visibleFraction < 1) {
            // Vidéo presque invisible
            if (_controller.value.isPlaying) {
              _controller.pause();
            }
          } else {
            // Vidéo visible
            if (!_controller.value.isPlaying) {
              _controller.play();
              service.togglesee(
                postId: widget.id,
                // isLiked: _isLiked,
                // like: widget.likes,
              );
              print("visibleFraction");
              print(visibleFraction);
              print("visibleFraction");
            }
            // Essayer de passer en cache
            _refreshWithCachedVersion();
          }
        },
        child: GestureDetector(
          onDoubleTapDown: (details) => _handleDoubleTap(details),
          onTap: () {
            if (!_isControllerReady || _isDisposed) return;

            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
              _showPlayPauseIcon = true;
            });

            _replayTimer?.cancel();
            _replayTimer = Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _showPlayPauseIcon = false;
                });
              }
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 📹 VIDÉO
              _buildVideoPlayer(),

              // 🎬 OVERLAY GRADIENT
              _buildGradientOverlay(),

              // 🔊 BOUTON MUTE
              if (widget.username.isNotEmpty) _buildMuteButton(),

              // ▶️ OVERLAY PLAY/PAUSE
              if (_showPlayPauseIcon && _isControllerReady)
                _buildPlayPauseOverlay(),

              // ❤️ ANIMATION DOUBLE TAP
              if (_showHeartAnimation && widget.username.isNotEmpty)
                _buildHeartAnimation(),

              // 📱 ACTIONS CÔTÉ DROIT
              if (widget.username.isNotEmpty) _buildRightActions(),

              // 📝 INFORMATIONS CÔTÉ GAUCHE
              if (widget.username.isNotEmpty) _buildLeftInfo(),

              // BOUTON PLEIN ÉCRAN
              if (widget.start == false)
                Positioned(
                  right: 1.w,
                  bottom: 1.h,
                  child: IconButton(
                    onPressed: _openFullscreen,
                    icon: Icon(Icons.fullscreen, color: Colors.white),
                    iconSize: 30,
                  ),
                ),

              // ⏹️ BARRE DE PROGRESSION
              if (_isControllerReady) _buildProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _controller.value.isInitialized) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: Stack(children: [VideoPlayer(_controller)]),
              ),
            ),
          );
        } else {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    _isUsingCache ? 'Chargement du cache...' : 'Chargement...',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          stops: const [0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return Positioned(
      top: widget.username.isNotEmpty ? 60 : 1.h,
      right: 16,
      child: GestureDetector(
        onTap: () {
          if (!_isControllerReady || _isDisposed) return;
          setState(() {
            _isMuted = !_isMuted;
            _controller.setVolume(_isMuted ? 0 : 1);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return Center(
      child: AnimatedOpacity(
        opacity: _showPlayPauseIcon ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _controller.value.isPlaying ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildHeartAnimation() {
    return Positioned(
      left: _heartPosition.dx - 30,
      top: _heartPosition.dy - 30,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: value,
              child: const Icon(Icons.favorite, color: Colors.red, size: 60),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 1.w,
      bottom: 1.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileSection(),
           SizedBox(height: 2.h),
          buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            label: _formatCount(_likeCount),
            onTap: _toggleLike,
          ),
          SizedBox(height: 2.h),
          buildActionButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.white,
            label: _formatCount(widget.comments),
            onTap: _openComments,
          ),
          SizedBox(height: 2.h),
          buildActionButton(
            icon: Icons.reply,
            color: Colors.white,
            label: _formatCount(widget.shares),
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          _buildMusicDisc(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: _navigateToProfile,
      child: Stack(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CustomImage(
              source: widget.profileImage,
              type: ImageType.circle,
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: Users.where(
              'googleId',
              isEqualTo: widget.uid,
            ).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final userDoc = snapshot.data!.docs.first;
              final userData = userDoc.data() as Map<String, dynamic>;
              final followers = userData['allfollow'] as List? ?? [];
              final isFollowing = followers.contains(AppUser.info?.googleId);
              return
              Visibility(
                visible: widget.uid != AppUser.info?.googleId && isFollowing==false,
                child: Positioned(
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        service.addfollowuser(postId: widget.uid!);
                        setState(() {
                          _isFollowing = !_isFollowing;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.transparent
                              : const Color(0xFFFF6B6B),
                          border: _isFollowing
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isFollowing ? 'Suivi' : '+',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              // SizedBox(height: 1.h),
            },
          ),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicDisc() {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: CustomImage(source: widget.profileImage, type: ImageType.circle),
      ),
    );
  }

  Widget _buildLeftInfo() {
    return Positioned(
      left: 1.w,
      bottom: 1.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: Row(
              children: [
                Text(
                  '@${widget.username}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 6,
                //     vertical: 2,
                //   ),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFFF6B6B),
                //     borderRadius: BorderRadius.circular(4),
                //   ),
                //   child: Text(
                //     'Suivre',
                //     style: GoogleFonts.montserrat(
                //       color: Colors.white,
                //       fontSize: 11,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: Get.width * 0.7,
            child: Text(
              widget.description,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                widget.music,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ BARRE DE PROGRESSION ÉPAISSE ET AMÉLIORÉE
  Widget _buildProgressBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _controller,
        builder: (context, value, child) {
          final position = value.position;
          final duration = value.duration;

          if (duration == Duration.zero) return const SizedBox.shrink();

          final progress = duration.inMilliseconds > 0
              ? position.inMilliseconds / duration.inMilliseconds
              : 0.0;

          return StatefulBuilder(
            builder: (context, setState) {
              bool _isDragging = false;
              double _dragProgress = 0.0;
              Offset _dragPosition = Offset.zero;

              return GestureDetector(
                onTapDown: (TapDownDetails details) {
                  print("pression 2.0");
                  setState(() {
                    _isDragging = true;
                    _dragPosition = details.localPosition;
                  });
                  widget.onSeekStarted?.call();

                  final renderBox = context.findRenderObject() as RenderBox;
                  final localX = details.localPosition.dx;
                  final width = renderBox.size.width;
                  final newProgress = (localX / width).clamp(0.0, 1.0);
                  _dragProgress = newProgress;

                  final newPosition = Duration(
                    milliseconds: (duration.inMilliseconds * newProgress)
                        .round(),
                  );
                  _controller.seekTo(newPosition);

                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() => _isDragging = false);
                      widget.onSeekEnded?.call();
                    }
                  });
                },
                onHorizontalDragStart: (details) {
                  print("pression 1.0");
                  setState(() {
                    _isDragging = true;
                    _dragPosition = details.localPosition;
                  });
                  widget.onSeekStarted?.call();
                },
                onHorizontalDragUpdate: (details) {
                  print("pression 3.0");
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localX = details.localPosition.dx;
                  final width = renderBox.size.width;
                  final newProgress = (localX / width).clamp(0.0, 1.0);
                  _dragProgress = newProgress;
                  _dragPosition = details.localPosition;

                  final newPosition = Duration(
                    milliseconds: (duration.inMilliseconds * newProgress)
                        .round(),
                  );
                  _controller.seekTo(newPosition);

                  setState(() => _isDragging = true);
                },
                onHorizontalDragEnd: (details) {
                  print("pression 4.0");
                  setState(() => _isDragging = false);
                  widget.onSeekEnded?.call();
                },
                child: Container(
                  height: _isDragging ? 60.0 : 30.0,
                  // Zone de toucher plus grande
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Affichage du temps pendant le drag
                      if (_isDragging)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF6B6B),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFFFF6B6B),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(
                                  Duration(
                                    milliseconds:
                                        (duration.inMilliseconds *
                                                _dragProgress)
                                            .round(),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '/',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Barre de progression principale (ÉPAISSE)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _isDragging == true ? 12.0 : 3.0,
                        // Barre plus épaisse
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width:
                                  MediaQuery.of(context).size.width *
                                  (_isDragging ? _dragProgress : progress),
                              height: _isDragging == true ? 12.0 : 6.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isDragging
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF6B6B,
                                          ).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Boule de progression pendant le drag
                      if (_isDragging)
                        Positioned(
                          left: _dragPosition.dx - 10,
                          bottom: 20,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Méthode utilitaire pour formater la durée
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SizedBox(
          height: Get.height / 1.3,
          child: CommentModal(videoId: widget.id, videoTitle: ''),
        ),
      ),
    );
  }

  void _navigateToProfile() {
    Get.to(
      () => PremiumProfileScreen(
        userId: widget.uid,
        avatarUrl: widget.profileImage,
        displayName: widget.username,
        username: widget.username,
        mail: widget.mail,
        bio:
            widget.bio ??
            "Créateur de contenu | Digital Creator ✨\nCollaborations 📩 ${widget.mail}",
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// WIDGET POUR LE PLEIN ÉCRAN
class FullscreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;
  final _TikTokVideoPlayerState state;

  const FullscreenVideoPlayer({
    Key? key,
    required this.controller,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // S'assurer que la vidéo joue en plein écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.value.isPlaying) {
        controller.play();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo en plein écran
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),

          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                stops: const [0.7, 1.0],
              ),
            ),
          ),

          // Bouton de fermeture
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Get.back();
              },
            ),
          ),

          // Bouton mute
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                state.setState(() {
                  state._isMuted = !state._isMuted;
                  controller.setVolume(state._isMuted ? 0 : 1);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state._isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Barre de progression
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.all(0),
              colors: const VideoProgressColors(
                playedColor: Color(0xFFFF6B6B),
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white24,
              ),
            ),
          ),

          // Tap pour play/pause
          GestureDetector(
            onTap: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }

              // Afficher brièvement l'icône play/pause
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Icon(
                    controller.value.isPlaying ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 30,
                  ),
                  duration: const Duration(milliseconds: 500),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
