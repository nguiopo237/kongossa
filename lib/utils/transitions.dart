import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Animated transitions utility between screens.
/// Uses native GetX transitions with premium durations and curves.
class AppTransitions {
  AppTransitions._();

  // ─── Durations ───
  static const Duration _fast = Duration(milliseconds: 250);
  static const Duration _normal = Duration(milliseconds: 350);
  static const Duration _slow = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════
  //  NAVIGATION METHODS
  // ═══════════════════════════════════════════════

  /// Standard right slide navigation (push)
  static void to<T>(Widget page) {
    Get.to<T>(
      () => page,
      transition: Transition.rightToLeft,
      duration: _normal,
    );
  }

  /// Premium fade navigation
  static void toPremium<T>(Widget page) {
    Get.to<T>(
      () => page,
      transition: Transition.fadeIn,
      duration: _slow,
    );
  }

  /// Zoom navigation
  static void toZoom<T>(Widget page) {
    Get.to<T>(
      () => page,
      transition: Transition.zoom,
      duration: _slow,
    );
  }

  /// Profile navigation with elegant slide
  static void toProfile<T>(Widget page) {
    Get.to<T>(
      () => page,
      transition: Transition.fadeIn,
      duration: _slow,
    );
  }

  /// Chat navigation with slide up
  static void toChat<T>(Widget page) {
    Get.to<T>(
      () => page,
      transition: Transition.downToUp,
      duration: _fast,
    );
  }

  /// Replace current route (no back navigation)
  static void off<T>(Widget page) {
    Get.off<T>(
      () => page,
      transition: Transition.fadeIn,
      duration: _normal,
    );
  }

  /// Replace all routes
  static void offAll<T>(Widget page) {
    Get.offAll<T>(
      () => page,
      transition: Transition.fadeIn,
      duration: _slow,
    );
  }

  // ═══════════════════════════════════════════════
  //  HERO TAGS
  // ═══════════════════════════════════════════════

  /// Creates a unique Hero tag for a user avatar
  static String heroAvatarTag(String userId) => 'hero_avatar_$userId';

  /// Creates a unique Hero tag for a post image
  static String heroPostImageTag(String postId) => 'hero_post_$postId';

  /// Creates a Hero widget for an avatar with gold glow effect
  static Widget heroAvatar({
    required String userId,
    required Widget child,
    Object? tagOverride,
  }) {
    return Hero(
      tag: tagOverride ?? heroAvatarTag(userId),
      flightShuttleBuilder: _goldFlightShuttle,
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      child: child,
    );
  }

  /// Creates a Hero widget for a post image
  static Widget heroPostImage({
    required String postId,
    required Widget child,
  }) {
    return Hero(
      tag: heroPostImageTag(postId),
      flightShuttleBuilder: _imageFlightShuttle,
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      child: child,
    );
  }

  /// Shuttle builder with gold fade effect for avatars
  static Widget _goldFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final heroWidget = direction == HeroFlightDirection.push
        ? fromHeroContext.widget
        : toHeroContext.widget;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37)
                    .withValues(alpha: 0.3 * animation.value),
                blurRadius: 10 * animation.value,
                spreadRadius: 2 * animation.value,
              ),
            ],
          ),
          child: Opacity(
            opacity: animation.value.clamp(0.6, 1.0),
            child: child,
          ),
        );
      },
      child: heroWidget,
    );
  }

  /// Shuttle builder for post images
  static Widget _imageFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final heroWidget = direction == HeroFlightDirection.push
        ? fromHeroContext.widget
        : toHeroContext.widget;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(12 * (1 - animation.value * 0.5)),
          child: child,
        );
      },
      child: heroWidget,
    );
  }
}


