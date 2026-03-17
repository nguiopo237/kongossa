// lib/presentation/pages/members_page_tiktok.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/presentation/component/style/custum_text.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../main.dart';
import '../../model/datamodel/membermodel.dart';
import '../../model/datamodel/user_model.dart';
import '../../presentation/component/image_component/image.dart';
import '../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../sevice/member_service/member_service.dart';
import '../bussiness/bussinesspage.dart';
import 'chatpage.dart';

class MembersPageTikTok extends StatefulWidget {
  const MembersPageTikTok({Key? key}) : super(key: key);

  @override
  State<MembersPageTikTok> createState() => _MembersPageTikTokState();
}

class _MembersPageTikTokState extends State<MembersPageTikTok>
    with SingleTickerProviderStateMixin {
  final MemberService _memberService = Get.find<MemberService>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';

  String get currentUserId => AppUser.info?.googleId ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar personnalisée style TikTok
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Messages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              // Icône de création de message
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // Barre de recherche style TikTok (décommentée et corrigée)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[600]),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // TabBar style TikTok - CORRIGÉ
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[900]!, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    // CORRECTION: indicatorPadding doit être plus petit
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    // Alternative: si vous voulez plus d'espace, utilisez isScrollable
                    // isScrollable: true,
                    tabs: const [
                      Tab(text: 'Tous'),
                      Tab(text: 'En ligne'),
                      Tab(text: 'Abonnements'),
                    ],
                  ),
                ),
                // Ligne de séparation supplémentaire si nécessaire
                Container(height: 0.5, color: Colors.grey[900]),
              ],
            ),
          ),

          // TabBarView avec les différents streams
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tous les membres
                _buildMembersList(
                  stream:
                      Users.where(
                        "googleId",
                        isNotEqualTo: AppUser.info?.googleId,
                      ).snapshots().map(
                        (snapshot) => snapshot.docs
                            .map((doc) => MemberModel.fromFirestore(doc))
                            .toList(),
                      ),
                ),

                // Membres en ligne
                _buildMembersList(
                  stream:
                      Users.where(
                            "googleId",
                            isNotEqualTo: AppUser.info?.googleId,
                          )
                          .where("isOnline", isEqualTo: true)
                          .snapshots()
                          .map(
                            (snapshot) => snapshot.docs
                                .map((doc) => MemberModel.fromFirestore(doc))
                                .toList(),
                          ),
                ),

                // Abonnements - À CORRIGER selon votre logique métier
                _buildMembersList(
                  stream:
                      Users.where(
                        "googleId",
                        isNotEqualTo: AppUser.info?.googleId,
                      ).snapshots().map(
                        (snapshot) => snapshot.docs
                            .map((doc) => MemberModel.fromFirestore(doc))
                            .toList(),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la liste des membres
  Widget _buildMembersList({required Stream<List<MemberModel>> stream}) {
    return StreamBuilder<List<MemberModel>>(
      stream: stream,
      builder: (context, snapshot) {
        // État de chargement style TikTok
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        // Erreur
        if (snapshot.hasError) {
          print('Erreur StreamBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifie ta connexion',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final members = snapshot.data ?? [];

        // Filtrer par recherche
        final filteredMembers = _searchQuery.isEmpty
            ? members
            : members.where((member) {
                final name = (member.displayName ?? member.username)
                    .toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

        // Aucun membre trouvé
        if (filteredMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty
                      ? Icons.people_outline
                      : Icons.search_off,
                  size: 64,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'Aucun membre' : 'Aucun résultat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Les membres apparaîtront ici'
                      : 'Essaie avec un autre mot',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }

        // Liste des membres style TikTok
        return  ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) {
            final member = filteredMembers[index];
            return _buildTikTokMemberCard(member);
          },
        );
      },
    );
  }

  // Carte de membre style TikTok
  Widget _buildTikTokMemberCard(MemberModel member) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // print('Membre cliqué: ${member.googleId}');
            Get.to(
              () => ChatPageTikTok(
                receiverId: member.googleId,
                onesignalId: member.onesignalId,
                receiverName: member.displayName ?? member.username,
                receiverPhoto: member.photoUrl,
                isOnline: member.isOnline,
              ),
            );
          },
          splashColor: Colors.grey[800],
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar avec style TikTok
                Stack(
                  children: [
                    CustomImage(
                      // ignore: dead_code
                      source: member.photoUrl.toString() ?? "",
                      type: ImageType.circle,
                      width: 40,
                      height: 40,
                    ),
                    if (member.isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.displayName ?? member.username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.pink[400],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (member.status != null && member.status!.isNotEmpty)
                        Text(
                          member.status!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              // color: Colors.orange,
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    Sms.
                                    where(
                                          "senderId",
                                          whereIn: [
                                            AppUser.info!.googleId,
                                            member.googleId,
                                          ],
                                        )
                                        .where(
                                          "receiveId",
                                          whereIn: [
                                            member.googleId,
                                            AppUser.info!.googleId,
                                          ],
                                        )

                                        .orderBy("timestamp", descending: false)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.pink,
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Erreur de chargement',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Text("");
                                  }

                                  final messages = snapshot.data!.docs.last;
                                  final unreadDocs = snapshot.data!.docs.where((
                                    doc,
                                  ) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    return data['isRead'] == false && data['receiveId'] ==  AppUser.info!.googleId;
                                  }).toList();

                                  // Compter
                                  int unreadCount = unreadDocs.length;

                                  print(
                                    "📊 Total des messages: ${snapshot.data!.docs.length}",
                                  );
                                  print("🔴 Messages non lus: $unreadCount");

                                  // Afficher les messages non lus
                                  print("\n📩 MESSAGES NON LUS:");
                                  for (var doc in unreadDocs) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    print(
                                      "  • ${data['namesenderId']}: ${data['content']}",
                                    );
                                  }

                                  // int countUnread = item.where((element) => element["isRead"] == false).toList().length;
                                  //
                                  // print("📊 Messages non lus: $countUnread");
                                  // Scroll automatique quand de nouveaux messages arrivent

                                  DateTime dateTime =
                                      messages['timestamp'] != null
                                      ? (messages['timestamp'] as Timestamp)
                                            .toDate()
                                      : DateTime.now();
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30.w,
                                              child: Text(
                                                messages["content"],
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize:
                                                      messages["senderId"] ==
                                                          AppUser.info!.googleId
                                                      ? 12.sp
                                                      : 16.sp,
                                                  color:
                                                      messages["senderId"] ==
                                                          AppUser.info!.googleId
                                                      ? Colors.grey[600]
                                                      : Colors.blue,
                                                  fontWeight:
                                                      messages["senderId"] ==
                                                          AppUser.info!.googleId
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // if (!member.isOnline && member.lastSeen != null)

                                          ],
                                        ),
                                      ),

                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (unreadCount != 0)
                                            CircleAvatar(
                                              backgroundColor: Colors.red,
                                              radius: 12,
                                              child: CustomText(
                                                unreadCount.toString(),
                                                type: TextType.button,
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),

                                            Text(
                                              timeago.format(dateTime),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),


                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),

                          // Text(
                          //  '223',
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: Colors.grey[600],
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bouton message style TikTok
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
