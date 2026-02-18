import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  final String ?uid;
  final String ?mail;
  final String ?bio;
  final int likes;
  final bool isLiked;
  final String id;
  final int comments;
  final int shares;
  final String profileImage;
  final List<dynamic>? alllike;

   TikTokVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.username,
    required this.description,
    required this.music,
    this.likes = 0,
    this.isLiked = false,
    required this.id ,
    this.comments = 0,
    this.shares = 0,
    this.alllike ,
    required this.profileImage, this.uid, this.mail, this.bio,
  }) : super(key: key);

  @override
  _TikTokVideoPlayerState createState() => _TikTokVideoPlayerState();
}

class _TikTokVideoPlayerState extends State<TikTokVideoPlayer> with TickerProviderStateMixin  {

  @override
  bool get wantKeepAlive => true; //
  late VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture = Future.value();
  bool _isMuted = false;
  bool _isLiked = false;
  bool _showPlayPauseIcon = false;
  bool _isFollowing = false;
  int _likeCount = 0;
  Timer? _doubleTapTimer;
  bool _showHeartAnimation = false;
  Offset _heartPosition = Offset.zero;
  bool _isControllerReady = false;
  bool _isUsingCache = false;
  late AnimationController _pulseController;
  PostUpdateService service = PostUpdateService();


  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
    print("mon lien");
    print(widget.videoUrl);
    print("mon lien");
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializePlayer();
  }

  /// Nettoie l'URL des caractères indésirables
  String _cleanUrl(String url) {
    return url.trim().replaceAll(RegExp(r'^[\[\]"]+|[\[\]"]+$'), '');
  }

  /// Vérifie si la vidéo est en cache et retourne le fichier si disponible
  Future<File?> _getCachedVideo() async {
    final cleanUrl = _cleanUrl(widget.videoUrl);
    print("check video ");
    print(cleanUrl);
    print("check video ");
    final file = await DefaultCacheManager().getFileFromCache(cleanUrl);
    if ( file!=null) {
      debugPrint('✅ Vidéo trouvée en caches');
      print(file.file);
      print(file.file.path);
      debugPrint('✅ Vidéo trouvée en caches');
      return file.file;
    }else{
      debugPrint('✅ Vidéo pas trouvée en caches');

      return null;
    }


  }

  /// Télécharge la vidéo en arrière-plan pour le cache futur
  Future<void> _downloadVideoForCache() async {
    try {
      final cleanUrl = _cleanUrl(widget.videoUrl);
      await DefaultCacheManager().downloadFile(cleanUrl);
      debugPrint('⬇️ Vidéo téléchargée pour le cache');
      _refreshWithCachedVersion();
    } catch (e) {
      debugPrint('❌ Échec téléchargement cache: $e');
    }
  }

  /// Initialise le lecteur avec priorité au cache
  Future<void> _initializePlayer() async {

    try {
      final cleanUrl = _cleanUrl(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(cleanUrl));
      if (cleanUrl.isEmpty) {
        throw Exception('URL vidéo vide');
      }

      // ÉTAPE 1: Vérifier le cache en PRIORITÉ
      final cachedFile = await _getCachedVideo();

      // ÉTAPE 2: Initialiser le contrôleur (cache d'abord, réseau ensuite)
      if (cachedFile != null) {
        // ✅ VIDÉO EN CACHE - Lecture immédiate
        _controller = VideoPlayerController.file(cachedFile!);
        _isUsingCache = true;
        _controller.addListener(() {
          if (_controller.value.position == _controller.value.duration) {
            // La vidéo est finie, ne pas la rejouer automatiquement
            // Option 1: Ne rien faire (rester sur la dernière frame)
            // Option 2: Chercher une action personnalisée
            _onVideoEnded();
          }
        });

        debugPrint('🎬 Lecture depuis le CACHE');
      } else {
        // ⚠️ VIDÉO NON CACHÉE - Lecture en ligne + téléchargement
        _controller = VideoPlayerController.networkUrl(Uri.parse(cleanUrl),);
        _isUsingCache = false;
        _controller.addListener(() {
          if (_controller.value.position == _controller.value.duration) {
            // La vidéo est finie, ne pas la rejouer automatiquement
            // Option 1: Ne rien faire (rester sur la dernière frame)
            // Option 2: Chercher une action personnalisée
            _onVideoEnded();
          }
        });
        debugPrint('🌐 Lecture depuis le RÉSEAU');

        // Déclencher le téléchargement en arrière-plan pour la prochaine fois
        _downloadVideoForCache();
      }

      // ÉTAPE 3: Initialiser le lecteur
      _initializeVideoPlayerFuture = _controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(false);
            _controller.setVolume(_isMuted ? 0 : 1);
            _controller.play();
            _isControllerReady = true;
          });
        }
      });

    } catch (e) {
      debugPrint('💥 ERREUR CRITIQUE: $e');
      _handleInitializationError();
    }
  }

  // Future<bool> _onLikeButtonTapped(bool isLiked) async {
  //
  // }


  /// Gestionnaire d'erreur avec fallback
  void _handleInitializationError() {
    // Vidéo de secours
    const fallbackUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
    _controller = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _controller.setLooping(false);
          _controller.setVolume(_isMuted ? 0 : 1);
          _controller.play();
          _isControllerReady = true;
        });
      }
    });
  }

  /// Rafraîchir le lecteur si une meilleure source devient disponible
  Future<void> _refreshWithCachedVersion() async {
    if (_isUsingCache) return; // Déjà en cache

    final cachedFile = await _getCachedVideo();
    if (cachedFile != null && mounted) {
      final newController = VideoPlayerController.file(cachedFile);
      await newController.initialize();


      if (mounted) {
        setState(() {
          final oldController = _controller;
          _controller = newController;
          _controller.setLooping(false);
          _controller.setVolume(_isMuted ? 0 : 1);
          _controller.play();
          _isControllerReady = true;
          _isUsingCache = true;
          _initializeVideoPlayerFuture = Future.value();
          oldController.dispose();
        });

        debugPrint('🔄 Basculement vers version CACHE');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _showHeartAnimation = true;
      _isLiked =!widget.isLiked;

      service.toggleLike(postId: widget.id,isLiked:  _isLiked,like: widget.likes );
      // _likeCount += _isLiked ? 1 : -1;
    });
  }

  _handleDoubleTap() {
    setState(() {
      _showHeartAnimation = true;
      if (!_isLiked) {
        _isLiked = true;
        _likeCount += 1;
      }
      setState(() {
        _isLiked = !widget.isLiked;
        if (_isLiked) {
          _pulseController.forward().then((_) => _pulseController.reset());
        }
      });
      service.toggleLike(postId: widget.id,isLiked:  _isLiked,like: widget.likes );
      // service.toggleLike(widget.id, _isLiked);
      // return _isLiked;
    });

    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _showHeartAnimation = false;
      });
    });
  }



void _onVideoEnded() {
  print('📹 Vidéo terminée - pas de boucle');
  // Vous pouvez afficher un message, un bouton, etc.
  // Mais NE PAS relancer _controller.play() automatiquement
}


  @override
  Widget build(BuildContext context) {
    // final Size screenSize = MediaQuery.of(context).size;
    // super.build(context);
    return Scaffold(
        resizeToAvoidBottomInset: false,
      body: VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (visibilityInfo) {
        if (!_isControllerReady) return;

        final visibleFraction = visibilityInfo.visibleFraction * 100;
        print("visibleFraction");
        print(visibleFraction);
        print("visibleFraction");
        if (visibleFraction==0.0) {
          _controller.pause();
        } else {
          _controller.play();
          // Essayer de passer en cache quand la vidéo est visible
          _refreshWithCachedVersion();
        }
      },
      child: GestureDetector(
        onDoubleTapDown: (details) {
          setState(() {
            _heartPosition = details.localPosition;
          });
        },
        onDoubleTap: _handleDoubleTap,
        onTap: () {
          if (!_isControllerReady) return;

          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
            _showPlayPauseIcon = true;
          });

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _showPlayPauseIcon = false;
              });
            }
          });
        },
        child: Stack(
          children: [
            // 📹 VIDEO PLAYER
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _controller.value.isInitialized) {
                  return SizedBox.expand(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        _buildReplayButton(),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isUsingCache
                                ? 'Chargement du cache...'
                                : 'Chargement...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),

            // 🎬 OVERLAY GRADIENT
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.7, 1.0],
                ),
              ),
            ),

            // 🔊 MUTE BUTTON
            Positioned(
              top:   widget.username!=""?60: 1.h,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  if (!_isControllerReady) return;
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
            ),

            // ▶️ PLAY/PAUSE OVERLAY
            if (_showPlayPauseIcon && _isControllerReady)
              Center(
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
              ),

            // ❤️ DOUBLE TAP HEART ANIMATION
            if (_showHeartAnimation&&widget.username!="")
              Positioned(
                left: _heartPosition.dx - 30,
                top: _heartPosition.dy - 30,
                child: TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, opacity, child) {
                    final safeOpacity = opacity.clamp(0.0, 1.0);
                    return Opacity(
                      opacity: safeOpacity,
                      child: Transform.scale(
                        scale: safeOpacity,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 60,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 📱 RIGHT SIDE ACTIONS
            if (widget.username!="")
              Positioned(
                right: 1.w,
                bottom: 1.h,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PROFILE IMAGE WITH FOLLOW
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          InkWell(onTap: () {
                            Get.to(PremiumProfileScreen (
                              userId: widget.uid ,
                              avatarUrl: widget.profileImage,
                              displayName: widget.username?? 'Utilisateur',
                              username: widget.username ?? 'Utilisateur',
                              mail: widget.mail,
                              bio: "${widget.bio ??"Créateur de contenu | Digital Creator ✨\nCollaborations"}  📩 ${widget.mail}",

                            ));
                          },

                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: CustomImage(
                                source: widget.profileImage,
                                type: ImageType.circle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ❤️ LIKE BUTTON
                    _buildActionButton(
                      icon: widget.alllike!.contains(AppUser.info!.googleId)? Icons.favorite : Icons.favorite_border,
                      color: widget.alllike!.contains(AppUser.info!.googleId)? Colors.red : Colors.white,
                      label: _formatCount(widget.likes),
                      onTap: _toggleLike,
                    ),
                    const SizedBox(height: 16),

                    // 💬 COMMENT BUTTON
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      color: Colors.white,
                      label: _formatCount(widget.comments),
                      onTap: () {
                        Future.microtask((){

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,  
                            backgroundColor: Colors.transparent,

                            shape:  RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.vertical(
                                  top: Radius.circular(30),
                                )),// ou true avec hauteur
                            // fixe
                            builder: (context) => ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                              child: SizedBox(
                                  height: Get.height/1.3,
                                  child: CommentModal(videoId: widget.id, videoTitle: '',)),
                            ),
                          );
                        });

                        // _controller.pause();
                        // WidgetComponent.getmodal(isScrollControlled: true,sectionview: SizedBox(
                        //     height: Get.height/1.4,
                        //     child: CommentModal(videoId: widget.id, videoTitle: '',)));
                      },
                    ),
                    const SizedBox(height: 16),

                    // 📤 SHARE BUTTON
                    _buildActionButton(
                      icon: Icons.reply,
                      color: Colors.white,
                      label: _formatCount(widget.shares),
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),

                    // 🎵 MUSIC DISC
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: CustomImage(
                          source: widget.profileImage,
                          type: ImageType.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 📝 VIDEO INFO BOTTOM LEFT
            if (widget.username!="")
              Positioned(
                left: 1.w,
                bottom: 1.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // USERNAME
                    GestureDetector(
                      onTap: () {},
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Suivre',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // DESCRIPTION
                    SizedBox(
                      width: Get.width * 0.7,
                      child: Text(
                        widget.description,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // MUSIC INFO
                    Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 14,
                        ),
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
              ),

            // ⏹️ BOTTOM PROGRESS BAR
            if (_isControllerReady)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.all(0),
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFFFF6B6B),
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildReplayButton() {
    // Ajouter un listener pour détecter la fin de la vidéo
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        // Si la vidéo est finie, afficher un bouton de replay
        if (value.position == value.duration && value.isPlaying == false) {
          return Container(
            color: Colors.black.withOpacity(0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: IconButton(
                    icon: Icon(Icons.replay, size: 50, color: Colors.white),
                    onPressed: () {
                      _controller.seekTo(Duration.zero);
                      _controller.play();
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}