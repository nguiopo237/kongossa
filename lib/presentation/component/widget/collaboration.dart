import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../config_App/colorsApp.dart';
import '../../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../image_component/image.dart';
import '../style/custum_text.dart';

// Modèle pour les compétences
class Competence {
  final String id;
  final String name;
  final String? icon;
  final String? category;

  Competence({
    required this.id,
    required this.name,
    this.icon,
    this.category,
  });

  factory Competence.fromJson(Map<String, dynamic> json) {
    return Competence(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'category': category,
    };
  }
}

// Modèle pour la collaboration
class CollaborationModel {
  final String id;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? message;

  CollaborationModel({
    required this.id,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.message,
  });

  factory CollaborationModel.fromJson(Map<String, dynamic> json) {
    return CollaborationModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'message': message,
    };
  }

  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'en_attente';
  bool get isAccepted => status.toLowerCase() == 'accepted' || status.toLowerCase() == 'accepté';
  bool get isRejected => status.toLowerCase() == 'rejected' || status.toLowerCase() == 'refusé';

  String get translatedStatus {
    if (isPending) return 'En attente';
    if (isAccepted) return 'Accepté';
    if (isRejected) return 'Refusé';
    return status;
  }

  Color get statusColor {
    if (isPending) return Colors.orange;
    if (isAccepted) return Colors.green;
    if (isRejected) return Colors.red;
    return Colors.grey;
  }
}

// Modèle pour l'utilisateur
class UserCollaborationModel {
  final String id;
  final String fullname;
  final String? username;
  final String? email;
  final String? photoUrl;
  final String? bannerUrl;
  final int countCollaborator;
  final int countFollowers;
  final int countFollowing;
  final List<Competence> competences;
  final CollaborationModel? collaboration;
  final bool isVerified;
  final String? bio;
  final String? location;
  final String? website;

  UserCollaborationModel({
    required this.id,
    required this.fullname,
    this.username,
    this.email,
    this.photoUrl,
    this.bannerUrl,
    this.countCollaborator = 0,
    this.countFollowers = 0,
    this.countFollowing = 0,
    this.competences = const [],
    this.collaboration,
    this.isVerified = false,
    this.bio,
    this.location,
    this.website,
  });

  factory UserCollaborationModel.fromJson(Map<String, dynamic> json) {
    // Traitement des compétences
    List<Competence> competencesList = [];
    // if (json['competences'] != null) {
    //   if (json['competences'] is List) {
    //     competencesList = (json['competences'] as List)
    //         .map((c) => Competence.fromJson(c is Map ? c : {'id': '', 'name': c.toString()}))
    //         .toList();
    //   } else if (json['competences'] is Map) {
    //     competencesList = [Competence.fromJson(json['competences'])];
    //   }
    // }

    // Traitement de la collaboration
    CollaborationModel? collaborationModel;
    if (json['collaboration'] != null) {
      collaborationModel = CollaborationModel.fromJson(
          json['collaboration'] is Map
              ? json['collaboration']
              : {'id': '', 'status': json['collaboration'].toString()}
      );
    }

    return UserCollaborationModel(
      id: json['id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ??
          json['name']?.toString() ??
          json['displayName']?.toString() ??
          '',
      username: json['username']?.toString() ?? json['userName']?.toString(),
      email: json['email']?.toString(),
      photoUrl: json['photoUrl']?.toString() ??
          json['avatar']?.toString() ??
          json['profileImage']?.toString(),
      bannerUrl: json['bannerUrl']?.toString() ?? json['coverImage']?.toString(),
      countCollaborator: json['countCollaborator'] ??
          json['collaboratorsCount'] ??
          json['collaborationsCount'] ??
          0,
      countFollowers: json['countFollowers'] ??
          json['followersCount'] ??
          0,
      countFollowing: json['countFollowing'] ??
          json['followingCount'] ??
          0,
      competences: competencesList,
      collaboration: collaborationModel,
      isVerified: json['isVerified'] ?? json['verified'] ?? false,
      bio: json['bio']?.toString(),
      location: json['location']?.toString(),
      website: json['website']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'bannerUrl': bannerUrl,
      'countCollaborator': countCollaborator,
      'countFollowers': countFollowers,
      'countFollowing': countFollowing,
      'competences': competences.map((c) => c.toJson()).toList(),
      'collaboration': collaboration?.toJson(),
      'isVerified': isVerified,
      'bio': bio,
      'location': location,
      'website': website,
    };
  }

  String get displayName => fullname.isNotEmpty ? fullname : (username ?? 'Utilisateur');
  String get initials => displayName.isNotEmpty
      ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
      : '?';
}

class Collaboratecard extends StatefulWidget {
  final String? username;
  final String? photoUrl;
  final VoidCallback? onClose;
  final VoidCallback? onSendAction;
  final VoidCallback? onTap;
  final UserCollaborationModel? user;
  final int? initialStatus;
  final bool isSearch;
  final bool showStats;
  final double? height;
  final double? width;
  final bool showActionButton;
  final Color? accentColor;
  final EdgeInsets? padding;

  const Collaboratecard({
    super.key,
    this.username,
    this.photoUrl,
    this.onClose,
    this.onSendAction,
    this.onTap,
    this.user,
    this.initialStatus = 0,
    this.isSearch = false,
    this.showStats = true,
    this.height,
    this.width,
    this.showActionButton = true,
    this.accentColor,
    this.padding,
  });

  @override
  State<Collaboratecard> createState() => _CollaboratecardState();
}

class _CollaboratecardState extends State<Collaboratecard> with SingleTickerProviderStateMixin {
  late int _status;
  UserCollaborationModel? _user;
  String _backgroundImagePath = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const int STATUS_NORMAL = 0;
  static const int STATUS_LOADING = 1;
  static const int STATUS_COLLABORATED = 2;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? STATUS_NORMAL;
    _user = widget.user;
    _initializeBackgroundImage();
    _checkInitialCollaborationStatus();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  void _initializeBackgroundImage() {
    if (s.assets.isNotEmpty) {
      s.assets.shuffle();
      _backgroundImagePath = s.assets.isNotEmpty ? s.assets.first : '';
    }
  }

  void _checkInitialCollaborationStatus() {
    if (_user?.collaboration?.isPending == true && _status == STATUS_NORMAL) {
      _status = STATUS_COLLABORATED;
    }
  }

  Future<void> sendCollaboration() async {
    if (_user == null) return;

    setState(() => _status = STATUS_LOADING);

    try {
      // Simulation d'appel API
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _status = STATUS_COLLABORATED;
          // Mise à jour du modèle utilisateur
          _user = _user?.copyWith(
            collaboration: CollaborationModel(
              id: DateTime.now().toString(),
              status: 'pending',
              createdAt: DateTime.now(),
            ),
          );
        });

        // Animation de succès
        _showSuccessFeedback();

        widget.onSendAction?.call();
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi collaboration: $e');
      if (mounted) {
        setState(() => _status = STATUS_NORMAL);
        _showErrorSnackbar('Erreur lors de l\'envoi de la collaboration');
      }
    }
  }

  Future<void> cancelCollaboration() async {
    if (_user == null) return;

    setState(() => _status = STATUS_LOADING);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _status = STATUS_NORMAL;
          _user = _user?.copyWith(collaboration: null);
        });

        _showSuccessFeedback(message: 'Collaboration annulée');
        widget.onClose?.call();
      }
    } catch (e) {
      debugPrint('❌ Erreur annulation collaboration: $e');
      if (mounted) {
        setState(() => _status = STATUS_COLLABORATED);
        _showErrorSnackbar('Erreur lors de l\'annulation de la collaboration');
      }
    }
  }

  void _showSuccessFeedback({String message = 'Collaboration envoyée'}) {
    Get.snackbar(
      'Succès',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(2.w),
      borderRadius: 10,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(2.w),
      borderRadius: 10,
    );
  }

  String _getButtonText() {
    if (widget.isSearch) return '';

    if (_user?.collaboration != null) {
      return _user!.collaboration!.isPending
          ? "Annuler la demande"
          : "Collaborer";
    }
    return "Collaborer";
  }

  Color _getButtonColor() {
    if (_status == STATUS_NORMAL || _status == STATUS_LOADING) {
      if (_user?.collaboration?.isPending == true) {
        return Colors.white;
      }
      return widget.accentColor ?? ColorApp.primary;
    }
    return Colors.white;
  }

  Color _getButtonTextColor() {
    if (_status == STATUS_NORMAL) {
      if (_user?.collaboration?.isPending == true) {
        return Colors.red;
      }
      return Colors.white;
    }
    return _status == STATUS_COLLABORATED ? (widget.accentColor ?? ColorApp.error) : Colors.white;
  }

  Widget _buildButton() {
    if (_status == STATUS_LOADING) {
      return Center(
        child: SizedBox(
          height: 4.w,
          width: 4.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _user?.collaboration?.isPending == true ? Colors.red : Colors.white,
            ),
          ),
        ),
      );
    }

    if (_status == STATUS_COLLABORATED) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 4.w,
            color: Colors.orange,
          ),
          SizedBox(width: 1.w),
          Flexible(
            child: CustomText(
              _user?.collaboration?.translatedStatus ?? "En attente",
              type: TextType.bodySmall,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return CustomText(
      _getButtonText(),
      type: TextType.bodySmall,
      maxLines: 1,
    );
  }

  Widget _buildVerifiedBadge() {
    if (!(_user?.isVerified ?? false)) return const SizedBox.shrink();

    return Positioned(
      top: 7.h,
      right: 32.w,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(0.8.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 3.5.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    if (!widget.showStats) return const SizedBox.shrink();

    return Positioned(
      top: 20.h,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              value: _user?.countCollaborator ?? 0,
              label: "",
              icon: Icons.people,
            ),
            Container(
              height: 2.5.h,
              width: 1,
              color: Colors.grey.shade300,
            ),
            _buildStatItem(
              value: _user?.countFollowers ?? 0,
              label: "",
              icon: Icons.follow_the_signs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required int value, required String label, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 4.w, color: Colors.grey.shade600),

        ],
        Column( 
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius:10,
              backgroundColor: Colors.red,
              child: CustomText(
                _formatNumber(value),
                type: TextType.headlineLarge,
                style: TextStyle(color: Colors.white,fontSize: 12.sp),
                // fontWeight: FontWeight.bold,
              ),
            ),
            CustomText(
              label,
              type: TextType.quote,
              style: TextStyle(color: Colors.white),
              // color: Colors.grey.shade600,
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap ?? () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: widget.height ?? 29.h,
            width: widget.width ?? 48.w,
            padding: widget.padding,
            margin: EdgeInsets.all(1.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Bannière de fond
                  _buildBannerBackground(),

                  // Overlay gradient pour meilleure lisibilité
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.02),
                          Colors.white.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),

                  // Avatar
                  Positioned(
                    top: 2.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildAvatar(),
                    ),
                  ),

                  // Badge vérifié
                  _buildVerifiedBadge(),

                  // Informations utilisateur
                  Positioned(
                    top: 12.h,
                    left: 2.w,
                    right: 2.w,
                    child: _buildUserInfo(),
                  ),

                  // Statistiques

                  _buildStats(),

                  // Bouton d'action
                  if (widget.showActionButton) _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 8.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.accentColor ?? ColorApp.primary,
              (widget.accentColor ?? ColorApp.primary).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: _backgroundImagePath.isNotEmpty
              ? DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage(_backgroundImagePath),
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
          )
              : null,
        ),
        child: _user!.bannerUrl != null
            ? CustomImage(
          source: _user!.bannerUrl!,
          type: ImageType.banner,
          width: double.infinity,
          height: 8.h,
          fit: BoxFit.cover,
        )
            : null,
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomImage(
        source: widget.photoUrl ?? _user?.photoUrl ?? '',
        type: ImageType.avatar,
        width: 20.w,
        height: 20.w,
        backgroundColor: Colors.grey.shade200,
        placeholder: CircleAvatar(
          radius: 7.w,
          backgroundColor: (widget.accentColor ?? ColorApp.primary).withOpacity(0.2),
          child: Text(
            _user?.initials ?? '?',
            style: TextStyle(
              fontSize: 7.w,
              fontWeight: FontWeight.bold,
              color: widget.accentColor ?? ColorApp.primary,
            ),
          ),
        ),
        errorWidget: CircleAvatar(
          radius: 7.w,
          backgroundColor: Colors.grey.shade200,
          child: Text(
            _user?.initials ?? '?',
            style: TextStyle(
              fontSize: 7.w,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          _user?.displayName ?? "Utilisateur",
          type: TextType.titleLarge,
          // fontWeight: FontWeight.bold,
          maxLines: 1,
          // textAlign: TextAlign.center,
        ),
        if (widget.username != null || _user?.username != null)
          Padding(
            padding: EdgeInsets.only(top: 0.3.h),
            child: CustomText(
              '@${widget.username ?? _user?.username ?? ""}',
              type: TextType.bodySmall,
              // color: Colors.grey.shade600,
              maxLines: 1,
              // textAlign: TextAlign.center,
            ),
          ),
        if (_user?.competences.isNotEmpty ?? false)
          Padding(
            padding: EdgeInsets.only(top: 0.3.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: (widget.accentColor ?? ColorApp.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                _user!.competences.first.name,
                type: TextType.bodySmall,
                // color: widget.accentColor ?? ColorApp.primary,
                maxLines: 1,
                // // textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Positioned(
      bottom: 1.5.h,
      left: 15,
      right: 15,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 4.h,
        child: ElevatedButton(
          onPressed: _status != STATUS_LOADING
              ? () {
            if (_user?.collaboration?.isPending == true) {
              cancelCollaboration();
            } else {
              sendCollaboration();
            }
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(),
            foregroundColor: _getButtonTextColor(),
            side: _user?.collaboration?.isPending == true
                ? BorderSide(color: widget.accentColor ?? Colors.red)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: _status == STATUS_LOADING ? 0 : 2,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
          ),
          child: _buildButton(),
        ),
      ),
    );
  }
}

// Extension pour copier l'objet user
extension UserCollaborationModelCopy on UserCollaborationModel {
  UserCollaborationModel copyWith({
    String? id,
    String? fullname,
    String? username,
    String? email,
    String? photoUrl,
    String? bannerUrl,
    int? countCollaborator,
    int? countFollowers,
    int? countFollowing,
    List<Competence>? competences,
    CollaborationModel? collaboration,
    bool? isVerified,
    String? bio,
    String? location,
    String? website,
  }) {
    return UserCollaborationModel(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      countCollaborator: countCollaborator ?? this.countCollaborator,
      countFollowers: countFollowers ?? this.countFollowers,
      countFollowing: countFollowing ?? this.countFollowing,
      competences: competences ?? this.competences,
      collaboration: collaboration ?? this.collaboration,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
    );
  }
}