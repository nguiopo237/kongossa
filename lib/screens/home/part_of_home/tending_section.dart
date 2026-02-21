import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../presentation/component/image_component/image.dart';
import '../../../presentation/component/style/custum_text.dart';

// Modèle pour les tendances
class TrendingTopicCard {
  final String id;
  final String title;
  final String category;
  final String description;
  final int engagement;
  final int posts;
  final double growth; // Pourcentage de croissance
  final List<String> hashtags;
  final String? imageUrl;
  final Color? gradientStart;
  final Color? gradientEnd;
  final List<TrendingTopicCard>? relatedTopics;
  final bool isSponsored;
  final bool isBreaking;

  TrendingTopicCard({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.engagement,
    required this.posts,
    required this.growth,
    required this.hashtags,
    this.imageUrl,
    this.gradientStart,
    this.gradientEnd,
    this.relatedTopics,
    this.isSponsored = false,
    this.isBreaking = false,
  });

  String get formattedEngagement {
    if (engagement >= 1000000) {
      return '${(engagement / 1000000).toStringAsFixed(1)}M';
    } else if (engagement >= 1000) {
      return '${(engagement / 1000).toStringAsFixed(1)}K';
    }
    return engagement.toString();
  }

  String get formattedPosts {
    if (posts >= 1000000) {
      return '${(posts / 1000000).toStringAsFixed(1)}M';
    } else if (posts >= 1000) {
      return '${(posts / 1000).toStringAsFixed(1)}K';
    }
    return posts.toString();
  }

  String get growthSymbol => growth >= 0 ? '+' : '';

  Color get growthColor => growth >= 0 ? Colors.green : Colors.red;
}

// Widget principal de découverte des tendances
class PremiumTrendsSection extends StatefulWidget {
  final VoidCallback? onTopicSelected;
  final VoidCallback? onSeeAll;
  final String? userId;

  const PremiumTrendsSection({
    super.key,
    this.onTopicSelected,
    this.onSeeAll,
    this.userId,
  });

  @override
  State<PremiumTrendsSection> createState() => _PremiumTrendsSectionState();
}

class _PremiumTrendsSectionState extends State<PremiumTrendsSection>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimation;
  late Animation<double> _headerFadeAnimation;
  late TabController _tabController;

  String selectedFilter = 'Tous';
  final List<String> filters = [
    'Tous',
    'Actualités',
    'Tech',
    'Sports',
    'Culture',
    'Business',
  ];

  // Données simulées
  final List<TrendingTopicCard> trendingTopics = [
    TrendingTopicCard(
      id: '1',
      title: 'Coupe d\'Afrique 2025',
      category: 'Sports',
      description: 'La CAN 2025 bat tous les records d\'audience en Afrique',
      engagement: 2500000,
      posts: 850000,
      growth: 156,
      hashtags: ['#CAN2025', '#Afrique', '#Football'],
      imageUrl:
          'https://images.pexels.com/photos/274422/pexels-photo-274422.jpeg',
      gradientStart: Colors.orange,
      gradientEnd: Colors.red,
      isBreaking: true,
      relatedTopics: [
        TrendingTopicCard(
          id: '1a',
          title: 'Finale',
          category: 'Sports',
          description: '',
          engagement: 890000,
          posts: 320000,
          growth: 89,
          hashtags: ['#FinaleCAN'],
          imageUrl: null,
        ),
      ],
    ),
    TrendingTopicCard(
      id: '2',
      title: 'IA Générative',
      category: 'Technologie',
      description: 'Les nouvelles avancées en intelligence artificielle',
      engagement: 1800000,
      posts: 620000,
      growth: 234,
      hashtags: ['#IA', '#Tech', '#Innovation'],
      imageUrl:
          'https://media.istockphoto.com/id/2207142074/photo/generative-ai-artificial-intelligence-generate-document-and-business-files-intelligent.jpg?s=1024x1024&w=is&k=20&c=JmJLUcwlfwAdCheqUwvrIHg5lYACEqWuHbAH64eqLfI=',
      gradientStart: Colors.purple,
      gradientEnd: Colors.blue,
      relatedTopics: [
        TrendingTopicCard(
          id: '2a',
          title: 'ChatGPT 5',
          category: 'Tech',
          description: '',
          engagement: 750000,
          posts: 280000,
          growth: 167,
          hashtags: ['#ChatGPT'],
          imageUrl: null,
        ),
      ],
    ),
    TrendingTopicCard(
      id: '3',
      title: 'Réforme Économique',
      category: 'Actualités',
      description: 'Nouvelles mesures économiques annoncées',
      engagement: 3200000,
      posts: 1100000,
      growth: 89,
      hashtags: ['#Économie', '#Réforme', '#Développement'],
      imageUrl:
          'https://images.pexels.com/photos/8140286/pexels-photo-8140286.jpeg',
      gradientStart: Colors.teal,
      gradientEnd: Colors.green,
      isBreaking: true,
    ),
    TrendingTopicCard(
      id: '4',
      title: 'Festival de Cannes',
      category: 'Culture',
      description: 'Le festival de Cannes dévoile sa sélection',
      engagement: 950000,
      posts: 310000,
      growth: 45,
      hashtags: ['#Cannes2025', '#Cinéma', '#Festival'],
      imageUrl:
          'https://images.pexels.com/photos/784712/pexels-photo-784712.jpeg',
      gradientStart: Colors.amber,
      gradientEnd: Colors.deepOrange,
      isSponsored: true,
    ),
    TrendingTopicCard(
      id: '5',
      title: 'Startup Africa',
      category: 'Business',
      description: 'La tech africaine lève des fonds records',
      engagement: 560000,
      posts: 185000,
      growth: 312,
      hashtags: ['#Startup', '#AfricaTech', '#Innovation'],
      imageUrl:
          'https://images.pexels.com/photos/3894383/pexels-photo-3894383.jpeg',
      gradientStart: Colors.indigo,
      gradientEnd: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _headerAnimation, curve: Curves.easeOut));
    _tabController = TabController(length: filters.length, vsync: this);
    _headerAnimation.forward();
  }

  @override
  void dispose() {
    _headerAnimation.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(child: _buildMainTrends()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Découvrir',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Les sujets du moment',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 5.w, color: Colors.blue),
                  SizedBox(width: 1.w),
                  Text(
                    'Tendances',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedFilter = filter);
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue,
              checkmarkColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainTrends() {
    return Container(
      height: 45.h,
      padding: EdgeInsets.all(2.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: trendingTopics.length,
        itemBuilder: (context, index) {
          final trend = trendingTopics[index];
          return Container(
            width: 75.w,
            margin: EdgeInsets.only(right: 3.w),
            child: _buildTrendCard(trend),
          );
        },
      ),
    );
  }

  Widget _buildTrendCard(TrendingTopicCard trend) {
    return InkWell(
      onTap: () => _showTrendDetail(trend),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              trend.gradientStart ?? Colors.blue,
              trend.gradientEnd ?? Colors.purple,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: (trend.gradientStart ?? Colors.blue).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image de fond en overlay
            if (trend.imageUrl != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),

                  child: CustomImage(
                    source: trend.imageUrl!,type: ImageType.cachedNetwork,
                    fit: BoxFit.cover,
                  ),

                  // child: Image.network(
                  //   trend.imageUrl!,
                  //   fit: BoxFit.cover,
                  //   color: Colors.black.withOpacity(0.4),
                  //   colorBlendMode: BlendMode.darken,
                  // ),
                ),
              ),

            // Contenu
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec badges
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            trend.category,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (trend.isBreaking)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 2.w,
                                      height: 2.w,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      'BREAKING',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (trend.isSponsored)
                              Container(
                                margin: EdgeInsets.only(left: 2.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Sponsorisé',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Titre
                  Text(
                    trend.title,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // SizedBox(height: 0.5.h),

                  // Description
                  Text(
                    trend.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // SizedBox(height: 1.5.h),

                  // Statistiques
                  Expanded(
                    child: Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.rocket_launch,
                          value: trend.formattedEngagement,
                          label: 'engagements',
                        ),
                        SizedBox(width: 4.w),
                        _buildStatItem(
                          icon: Icons.chat_bubble_outline,
                          value: trend.formattedPosts,
                          label: 'posts',
                        ),
                        SizedBox(width: 4.w),
                        _buildStatItem(
                          icon: Icons.trending_up,
                          value: '${trend.growthSymbol}${trend.growth}%',
                          label: 'croissance',
                          valueColor: trend.growthColor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 1.5.h),

                  // Hashtags
                  Wrap(
                    spacing: 2.w,
                    children: trend.hashtags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Sujets associés
                  if (trend.relatedTopics != null &&
                      trend.relatedTopics!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'À découvrir aussi',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          SizedBox(
                            height: 8.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: trend.relatedTopics!.length,
                              itemBuilder: (context, index) {
                                final related = trend.relatedTopics![index];
                                return Container(
                                  width: 30.w,
                                  margin: EdgeInsets.only(right: 2.w),
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        related.title,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${related.formattedPosts} posts',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.7),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: widget.onSeeAll,
            icon: Icon(Icons.explore, size: 5.w, color: Colors.blue),
            label: Text(
              'Voir toutes les tendances',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.arrow_forward, size: 5.w, color: Colors.blue),
        ],
      ),
    );
  }

  void _showTrendDetail(TrendingTopicCard trend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrendDetailSheet(trend: trend),
    );
  }
}

// Bottom Sheet de détail d'une tendance
class _TrendDetailSheet extends StatelessWidget {
  final TrendingTopicCard trend;

  const _TrendDetailSheet({required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 15.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            trend.gradientStart ?? Colors.blue,
                            trend.gradientEnd ?? Colors.purple,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 6.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trend.title,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            trend.category,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Stats détaillées
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailStat(
                        value: trend.formattedEngagement,
                        label: 'Engagements',
                        icon: Icons.rocket_launch,
                      ),
                      _buildDetailStat(
                        value: trend.formattedPosts,
                        label: 'Posts',
                        icon: Icons.chat,
                      ),
                      _buildDetailStat(
                        value: '${trend.growth}%',
                        label: 'Croissance',
                        icon: Icons.trending_up,
                        color: trend.growthColor,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),

                // Graphique de tendance (simulé)
                Container(
                  height: 15.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: CustomPaint(
                    painter: _TrendChartPainter(
                      gradientColors: [
                        trend.gradientStart ?? Colors.blue,
                        trend.gradientEnd ?? Colors.purple,
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Posts populaires
                Text(
                  'Posts populaires',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 2.h),

                ...List.generate(3, (index) => _buildPopularPost(index)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat({
    required String value,
    required String label,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 6.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPopularPost(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 5.w,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, size: 5.w, color: Colors.grey.shade600),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Utilisateur ${index + 1}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Post sur la tendance ${trend.title}...',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Icon(Icons.favorite_border, size: 5.w, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

// Paint personnalisé pour le graphique de tendance
class _TrendChartPainter extends CustomPainter {
  final List<Color> gradientColors;

  _TrendChartPainter({required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // Création d'une courbe de tendance simulée
    for (double x = 0; x <= size.width; x += size.width / 20) {
      double y =
          size.height * 0.8 -
          (size.height * 0.6) *
              (0.5 + 0.5 * (x / size.width)) *
              (1 + 0.3 * (x / size.width));
      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
