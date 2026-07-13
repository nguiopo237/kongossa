import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'dart:async'; // Added for Timer

import '../../../sevice/controlleur/firestore_collections_service.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../sevice/connection/connectionchecker.dart';
import 'package:kongossa/sevice/upload/upload.dart';
import 'package:kongossa/shared/widgets/widgets.dart';
import 'package:path/path.dart' as path;

import '../cloudinaryvideoplayer.dart';

class CreatePostPremiumScreen extends StatefulWidget {
  const CreatePostPremiumScreen({super.key});

  @override
  State<CreatePostPremiumScreen> createState() =>
      _CreatePostPremiumScreenState();
}

class _CreatePostPremiumScreenState extends State<CreatePostPremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final TextEditingController _postController = TextEditingController();
  final FocusNode _postFocusNode = FocusNode();

  // ADDED: Variables to optimize StreamBuilder
  late DocumentSnapshot? _userData;
  late StreamSubscription<QuerySnapshot>? _userStreamSubscription;
  bool _isLoadingUser = true;
  Timer? _textFieldTimer; // To prevent frequent rebuilds

  // UI state
  bool _hasContent = false;
  bool _isPublic = true;
  String _selectedAudience = 'Public';
  List<String> _attachedImages = [];
  List<String> sender = [];
  List<String> _attachedVideos = [];
  List<File> _attachedVideosfile = [];
  bool _hasLocation = false;
  String? _locationName = 'Paris, France';
  bool _tagPeople = false;
  List<String> _taggedPeople = ['Marie Dupont', 'Jean Martin'];
  bool _isFeeling = false;
  String? _selectedFeeling;
  bool _isPoll = false;
  int _charCount = 0;
  final int _maxChars = 280;

  // Options premium
  List<Map<String, dynamic>> _feelingOptions = [
    {'icon': '😊', 'label': 'create_post.happy'.tr, 'color': Colors.amber},
    {'icon': '😢', 'label': 'create_post.sad'.tr, 'color': Colors.blue},
    {'icon': '😎', 'label': 'create_post.cool'.tr, 'color': Colors.green},
    {'icon': '❤️', 'label': 'create_post.in_love'.tr, 'color': Colors.red},
    {'icon': '🤔', 'label': 'create_post.thoughtful'.tr, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // MODIFIED: Use a timer to prevent frequent rebuilds
    _postController.addListener(() {
      _textFieldTimer?.cancel();
      _textFieldTimer = Timer(const Duration(milliseconds: 100), () {
        _updateContent();
      });
    });

    // ADDED: Load user data once


    _animationController.forward();
  }

  // ADDED: Method to load user data
  void _loadUserData() {
    // Get data once instead of using StreamBuilder
    FirestoreCollectionsService.users.where('googleId', isEqualTo: AppUser.info?.googleId).snapshots().listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _userData = querySnapshot.docs.first;
          _isLoadingUser = false;
        });
      }
    }, onError: (error) {
      setState(() {
        _isLoadingUser = false;
      });
      debugPrint("Error loading user data: $error");
    });
  }

  @override
  void dispose() {
    _textFieldTimer?.cancel();
    _animationController.dispose();
    _postController.dispose();
    _postFocusNode.dispose();
    // _userStreamSubscription?.cancel(); // Nettoyer le stream
    super.dispose();
  }

  void _updateContent() {
    final hasContentNow = _postController.text.isNotEmpty ||
        _attachedImages.isNotEmpty ||
        _attachedVideos.isNotEmpty;

    if (_hasContent != hasContentNow) {
      setState(() {
        _charCount = _postController.text.length;
        _hasContent = hasContentNow;
      });
    } else {
      // Update only counter without unnecessary setState
      if (_charCount != _postController.text.length) {
        setState(() {
          _charCount = _postController.text.length;
        });
      }
    }
  }

  void _toggleAudience() {
    setState(() {
      _isPublic = !_isPublic;
      _selectedAudience = _isPublic ? 'create_post.audience_public'.tr : 'create_post.audience_friends'.tr;
    });
  }

  Future<void> _addImage() async {
    final pickedFile = await SelectImage.uploadMultipleImages();
    if (pickedFile != null && pickedFile.isNotEmpty) {
      for (var element in pickedFile) {
        debugPrint(element.path);
        setState(() {
          _attachedImages.add(element.path);
        });
      }
    }
  }
  NativeVideoCompressService compress = NativeVideoCompressService();

  Future<void> _addVideo() async {
    final pickedFile = await SelectImage.uploadMultipleVideo();
    if (pickedFile != null && pickedFile.isNotEmpty) {
      for (var element in pickedFile) {
        debugPrint(element.path);
        setState(() {
          _attachedVideos.add(element.path);
        });
      }
      // compress.compressLikeYouTube(pickedFile.first.path);
      // compressLikeYouTube()

    }
  }

  void _toggleLocation() {
    setState(() {
      _hasLocation = !_hasLocation;
    });
  }

  void _toggleFeeling() {
    setState(() {
      _isFeeling = !_isFeeling;
      if (!_isFeeling) {
        _selectedFeeling = null;
      }
    });
  }

  void _togglePoll() {
    setState(() {
      _isPoll = !_isPoll;
    });
  }

  void _selectFeeling(Map<String, dynamic> feeling) {
    setState(() {
      _selectedFeeling = feeling['label'];
    });
  }

  void _publishPost() async {
    final isConnected = await Connexioncheck.checkconnection();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("noconnect".tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_hasContent) {
      _showNotification('create_post.add_content'.tr, Colors.orange);
      return;
    }

    // Check if title is empty
    if (_postController.text.trim().isEmpty) {
      _showNotification('create_post.title_required'.tr, Colors.orange);
      return;
    }

    try {
      _animationController.reverse();

      // 🔍 CHECK: Does this title already exist?
      String postTitle = _postController.text.trim();

      // Query to check if a post with this title already exists
      QuerySnapshot existingPosts = await FirestoreCollectionsService.posts
          .where('postData.posttitle', isEqualTo: postTitle)
          .where('userData.googleId', isEqualTo: AppUser.info!.googleId) // Same user
          .get();
      debugPrint("suite de verification");

      debugPrint("suite de verification");

      if (existingPosts.docs.isNotEmpty) {
        // A post with this title already exists
        _showNotification('create_post.title_exists'.tr, Colors.orange);
        _animationController.forward(); // Annuler l'animation
        return;
      }

      // ✅ Si on arrive ici, le titre n'existe pas, on continue avec l'upload
      UniversalCloudinaryUploader _serviceall = UniversalCloudinaryUploader();
      List<String> uploadedUrls = [];

      if (_attachedVideos.isNotEmpty) {
        _attachedImages.clear();
        for (var element in _attachedVideos) {
          try {
            String originalName = path.basename(element);
            final url = await _serviceall.uploadAnyFile(
              filePath: element,
              folder: "kogossa_app/secure",
              fileName: originalName,
            );

            if (url != null) {
              uploadedUrls.add(url);
              debugPrint("✅ Image uploaded: $url");
            }
          } catch (e) {
            debugPrint("❌ Image upload error $element: $e");
          }
        }

        setState(() {
          sender = uploadedUrls;
        });
      }

      if (_attachedImages.isNotEmpty) {
        for (var element in _attachedImages) {
          try {
            String originalName = path.basename(element);
            final url = await _serviceall.uploadAnyFile(
              filePath: element,
              folder: "kogossa_app/secure",
              fileName: originalName,
            );

            if (url != null) {
              uploadedUrls.add(url);
              debugPrint("✅ Image uploaded: $url");
            }
          } catch (e) {
            debugPrint("❌ Image upload error $element: $e");
          }
        }

        setState(() {
          sender = uploadedUrls;
        });
      }

      final userData = {
        "email": AppUser.info!.email,
        "googleId": AppUser.info!.googleId,
        "name": AppUser.info!.displayName,
        "photoUrl": AppUser.info!.photoUrl,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
      };

      final postdata = {
        "posttitle": postTitle, // Utiliser la version trim() ici
        "imagepost": _attachedImages.isEmpty && _attachedVideos.isEmpty ? [] : _attachedImages.isNotEmpty ? sender : [],
        "videopost": _attachedVideos.isEmpty && sender.isEmpty ? [] : _attachedVideos.isNotEmpty ? sender : [],
        "likes": 0,
        "islike": false,
        "status": "published",
        "commentaire": [],
        "personlike": [],
        "allike": [],
        "createdAt": FieldValue.serverTimestamp(),
        "userId": AppUser.info!.googleId,
      };

      final postDocument = {
        "userData": userData,
        "postData": postdata,
        "timestamp": FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await FirestoreCollectionsService.posts.add(postDocument);
      debugPrint("✅ Post created with ID: ${docRef.id}");

      _showNotification('create_post.publish_success'.tr, Colors.green);

      // Reset
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _postController.clear();
          _attachedImages.clear();
          _attachedVideos.clear();
          sender.clear();
          _hasLocation = false;
          _tagPeople = false;
          _isFeeling = false;
          _selectedFeeling = null;
          _isPoll = false;
          _charCount = 0;
          _hasContent = false;
        });
        _animationController.forward();
      });

    } catch (e) {
      debugPrint("❌ Publish error: $e");
      _showNotification('create_post.publish_error'.tr, Colors.red);
      _animationController.forward();
    }
  }

  void _showNotification(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(colors: [Theme.of(context).colorScheme.outlineVariant!, Theme.of(context).colorScheme.outlineVariant!]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: isActive ? onPressed : null,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = activeColor ?? const Color(0xFF6366F1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [color, color.withValues(alpha: 0.8)]
                      : [Theme.of(context).colorScheme.outline!, Theme.of(context).colorScheme.outlineVariant!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCounter() {
    final percentage = _charCount / _maxChars;
    Color color;

    if (percentage < 0.7)
      color = Colors.green;
    else if (percentage < 0.9)
      color = Colors.orange;
    else
      color = Colors.red;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: percentage,
            strokeWidth: 3,
            backgroundColor: Theme.of(context).colorScheme.outlineVariant,
            color: color,
          ),
        ),
        Text(
          '${_maxChars - _charCount}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Scaffold(
            // extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: AnimatedOpacity(
                opacity: _fadeAnimation.value,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'create_post.title'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black, // Added for visibility
                  ),
                ),
              ),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: AnimatedOpacity(
                    opacity: _fadeAnimation.value,
                     duration: Duration(seconds: 3),
                    child: _buildCharacterCounter(),
                  ),
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Container(
              color: Colors.white, // Simplified for better performance
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      // physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Premium user header - OPTIMIZED
                          SizedBox(height: 2.h,),
                          _buildPremiumUserHeader(),
                          SizedBox(height: 2.h,),

                          // Zone de texte avec effet glassmorphism
                          _buildPremiumTextField(),

                          // Media content
                          if (_attachedImages.isNotEmpty ||
                              _attachedVideos.isNotEmpty)
                            _buildPremiumMediaGallery(),

                          // Options de publication premium
                          _buildPremiumOptions(),

                          // Selected feeling
                          if (_isFeeling && _selectedFeeling != null)
                            _buildSelectedFeeling(),

                          // Advanced settings
                          _buildAdvancedSettings(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),

                  // Barre d'actions premium

                ],
              ),
            ),
            bottomNavigationBar: _buildActionBar(),
            // floatingActionButton: Padding(
            //   padding:  EdgeInsets.only(bottom: 6.h),
            //   child: SizedBox(height: 10.h,child: _buildActionBar(),),
            // ),
            // floatingActionButtonLocation: FloatingActionButtonLocation.miniStartDocked,
          ),
        );
      },
    );
  }

  // MODIFIED: Optimized version without StreamBuilder in build
  Widget _buildPremiumUserHeader() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingUser)
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey,
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 20,
                            child: LinearProgressIndicator(),
                          ),
                          SizedBox(height: 5),
                          SizedBox(
                            width: 80,
                            height: 15,
                            child: LinearProgressIndicator(),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (_userData != null)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(18),

                            ),
                            child: CustomImage(type: ImageType.circle,source: _userData!["photoUrl"]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData!["name"] ?? 'create_post.user'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleAudience,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isPublic ? Icons.public : Icons.lock,
                                    size: 14,
                                    color:
                                    _isPublic ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedAudience,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'create_post.user',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'create_post.not_connected',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _hasContent
                ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest, // Changed for better contrast
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _postController,
          focusNode: _postFocusNode,
          maxLines: null,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'create_post.hint'.tr,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(
                Icons.edit_note_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMediaGallery() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.6),
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.collections,
                    color: Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'create_post.media'.tr + ' (${_attachedImages.length + _attachedVideos.length})',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_attachedImages.isNotEmpty) _buildImageGrid(),
            if (_attachedVideos.isNotEmpty) _buildVideoPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _attachedImages.length > 1 ? 2 : 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: _attachedImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                CustomImage(
                    source: _attachedImages[index],
                    type: ImageType.file,
                    width: 200,
                    height: 150
                ),
                // Image.network(
                //   _attachedImages[index],
                //   fit: BoxFit.cover,
                //   loadingBuilder: (context, child, loadingProgress) {
                //     if (loadingProgress == null) return child;
                //     return Container(
                //       color: Theme.of(context).colorScheme.surfaceContainerHighest,
                //       child: Center(
                //         child: CircularProgressIndicator(
                //           value: loadingProgress.expectedTotalBytes != null
                //               ? loadingProgress.cumulativeBytesLoaded /
                //               loadingProgress.expectedTotalBytes!
                //               : null,
                //           color: const Color(0xFF6366F1),
                //         ),
                //       ),
                //     );
                //   },
                // ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _attachedImages.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          Videoplayerpost(files: File(_attachedVideos.first.toString()),),

          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOptions() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.4),
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'create_post.enrich',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildPremiumOption(
                  icon: Icons.photo_camera,
                  label: 'create_post.photo'.tr,
                  onTap: _addImage,
                  isActive: _attachedImages.isNotEmpty,
                  activeColor: Colors.green,
                ),
                _buildPremiumOption(
                  icon: Icons.videocam,
                  label: 'create_post.video'.tr,
                  onTap: _addVideo,
                  isActive: _attachedVideos.isNotEmpty,
                  activeColor: Colors.purple,
                ),
                _buildPremiumOption(
                  icon: Icons.location_pin,
                  label: 'create_post.location'.tr,
                  onTap: _toggleLocation,
                  isActive: _hasLocation,
                  activeColor: Colors.red,
                ),
                _buildPremiumOption(
                  icon: Icons.emoji_emotions,
                  label: 'create_post.mood'.tr,
                  onTap: _toggleFeeling,
                  isActive: _isFeeling,
                  activeColor: Colors.amber,
                ),
                _buildPremiumOption(
                  icon: Icons.poll,
                  label: 'create_post.poll'.tr,
                  onTap: _togglePoll,
                  isActive: _isPoll,
                  activeColor: Colors.blue,
                ),
                _buildPremiumOption(
                  icon: Icons.tag,
                  label: 'create_post.people'.tr,
                  onTap: () {
                    setState(() {
                      _tagPeople = !_tagPeople;
                    });
                  },
                  isActive: _tagPeople,
                  activeColor: Colors.pink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFeeling() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.3),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          children: [
            const Text('😊', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'create_post.you_feel'.tr + '${_selectedFeeling!.toLowerCase()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'create_post.share_mood'.tr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () {
                setState(() {
                  _selectedFeeling = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.2),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.black, size: 20),
                SizedBox(width: 10),
                Text(
                  'create_post.advanced_settings',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingRow(
              icon: Icons.schedule,
              title: 'create_post.schedule'.tr,
              value: 'create_post.now'.tr,
              onTap: () {},
            ),
            _buildSettingRow(
              icon: Icons.comment,
              title: 'create_post.allow_comments'.tr,
              value: 'create_post.everyone'.tr,
              onTap: () {},
            ),
            _buildSettingRow(
              icon: Icons.share,
              title: 'create_post.allow_shares'.tr,
              value: 'create_post.everyone'.tr,
              onTap: () {},
            ),
            _buildSettingRow(
              icon: Icons.visibility,
              title: 'create_post.view_stats'.tr,
              value: 'create_post.enabled'.tr,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue[700], size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActionBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildGradientButton(
              text: 'create_post.publish'.tr,
              onPressed: _publishPost,
              isActive: _hasContent,
            ),
             const SizedBox(width: 15),
            // Container(
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).colorScheme.surfaceContainerHighest,
            //     borderRadius: BorderRadius.circular(15),
            //   ),
            //   child: IconButton(
            //     icon: const Icon(Icons.more_horiz, color: Colors.black54),
            //     onPressed: () {
            //
            //       // authController.getCurrentToken();
            //       authController.getFirebaseToken();
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:  EdgeInsets.symmetric(vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _hasContent ? _publishPost : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: _hasContent ? 5 : 0,
                ),
                child: const Text(
                  'Publier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}