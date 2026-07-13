import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config_App/colorsApp.dart';
import '../../sevice/controlleur/live_controller.dart';
import 'meeting/pre_join_screen.dart';
import 'go_live_screen.dart';

class LiveFeedScreen extends StatelessWidget {
  const LiveFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LiveController.to;
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              'En Direct',
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: gold),
            onPressed: () => Get.to(() => const GoLiveScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.activeLives.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              // ── Lives actifs ──
              if (controller.activeLives.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Text(
                      'Actifs · ${controller.activeLives.length}',
                      style: TextStyle(color: subtle, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 2.w,
                      crossAxisSpacing: 2.w,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LiveCard(
                        live: controller.activeLives[index],
                        gold: gold,
                        onSurface: onSurface,
                        subtle: subtle,
                        onTap: () => controller.joinLive(controller.activeLives[index].id),
                      ),
                      childCount: controller.activeLives.length,
                    ),
                  ),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 30.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off_rounded, size: 48, color: subtle.withValues(alpha: 0.4)),
                          SizedBox(height: 2.h),
                          Text('Aucun live en cours', style: TextStyle(color: subtle, fontSize: 16)),
                          SizedBox(height: 1.h),
                          Text('Soyez le premier à lancer un live !', style: TextStyle(color: subtle, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ── Lives passés ──
              if (controller.pastLives.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
                    child: Text(
                      'Replays',
                      style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PastLiveTile(
                      live: controller.pastLives[index],
                      gold: gold,
                      onSurface: onSurface,
                      subtle: subtle,
                    ),
                    childCount: controller.pastLives.length,
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final dynamic live;
  final Color gold;
  final Color onSurface;
  final Color subtle;
  final VoidCallback onTap;

  const _LiveCard({
    required this.live,
    required this.gold,
    required this.onSurface,
    required this.subtle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(        onTap: () {
        onTap();
        // Extract roomId from streamUrl (format: videosdk://<roomId>)
        final roomId = live.streamUrl?.replaceAll('videosdk://', '') ?? '';
        Get.to(() => PreJoinScreen(
          liveId: live.id,
          roomId: roomId,
          isHost: false,
          liveTitle: live.title,
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / placeholder
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image réelle ou placeholder
                    if (live.thumbnailUrl != null && live.thumbnailUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: live.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildThumbnailPlaceholder(gold),
                        errorWidget: (context, url, error) => _buildThumbnailPlaceholder(gold),
                      )
                    else
                      _buildThumbnailPlaceholder(gold),

                    // LIVE badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.2.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nombre de viewers
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.1.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, size: 10, color: Colors.white),
                            SizedBox(width: 1.w),
                            Text(
                              '${live.viewers}',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Infos
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    live.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 0.3.h),
                  Row(
                    children: [
                      CircleAvatar(radius: 8, backgroundImage: NetworkImage(live.hostAvatar)),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          live.hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subtle, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastLiveTile extends StatelessWidget {
  final dynamic live;
  final Color gold;
  final Color onSurface;
  final Color subtle;

  const _PastLiveTile({
    required this.live,
    required this.gold,
    required this.onSurface,
    required this.subtle,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = live.thumbnailUrl != null && live.thumbnailUrl.isNotEmpty;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 50,
          height: 50,
          child: hasThumbnail
              ? CachedNetworkImage(
                  imageUrl: live.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.play_circle_outline, color: gold, size: 24),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.play_circle_outline, color: gold, size: 24),
                  ),
                )
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.play_circle_outline, color: gold, size: 24),
                ),
        ),
      ),
      title: Text(
        live.title,
        style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${live.hostName} · ${live.duration}',
        style: TextStyle(color: subtle, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: subtle, size: 18),
      onTap: () {
        final roomId = live.streamUrl?.replaceAll('videosdk://', '') ?? '';
        Get.to(() => PreJoinScreen(
          liveId: live.id,
          roomId: roomId,
          isHost: false,
          liveTitle: live.title,
        ));
      },
    );
  }
}

/// Placeholder de fond pour la carte live (dégradé + icône TV).
Widget _buildThumbnailPlaceholder(Color gold) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [ColorApp.darkCharcoal, ColorApp.darkSurface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.live_tv_rounded, size: 36, color: gold.withValues(alpha: 0.3)),
    ),
  );
}
