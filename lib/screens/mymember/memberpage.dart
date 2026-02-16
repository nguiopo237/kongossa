// lib/presentation/pages/members_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../main.dart';
import '../../model/datamodel/membermodel.dart';
import '../../model/datamodel/user_model.dart';
import '../../sevice/member_service/member_service.dart';
import 'chatpage.dart';


class MembersPage extends StatefulWidget {
  const MembersPage({Key? key}) : super(key: key);

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> with SingleTickerProviderStateMixin {
  final MemberService _memberService = Get.find<MemberService>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'En ligne'),
            Tab(text: 'Abonnements'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // TabBarView avec les différents streams
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tous les membres
                _buildMembersStream(
                    Users.where("googleId" ,isNotEqualTo: AppUser.info?.googleId).snapshots().map((snapshot){
                      return  snapshot.docs
                          .map((doc) => MemberModel.fromFirestore(doc))
                          .toList();
                    })
                ),

                // Membres en ligne
                _buildMembersStream(
                  _memberService.getOnlineMembers(excludeUserId: currentUserId),
                ),

                // Abonnements
                _buildMembersStream(
                  _memberService.getFollowingMembers(currentUserId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher le stream des membres
  Widget _buildMembersStream(Stream<List<MemberModel>> stream) {
    return StreamBuilder<List<MemberModel>>(
      stream: stream,
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            // child: LoadingWidget(message: 'Chargement des membres...'),
          );
        }

        // Erreur
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Recharger
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        // Données reçues
        final members = snapshot.data ?? [];

        // Aucun membre trouvé
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun membre trouvé'
                      : 'Aucun membre disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Essayez un autre terme de recherche'
                      : 'Les membres apparaîtront ici',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Liste des membres
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];

              return MemberCard(
                member: member,
                onTap: () {
                  Get.to(ChatPage(
                    receiverId: member.googleId,
                    receiverName: member.displayName ?? member.username,
                    receiverPhoto: member.photoUrl,
                    // isOnline: true,
                  ),);

                },
              );
            },
          ),
        );
      },
    );
  }
}

// Carte d'un membre
class MemberCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onTap;

  const MemberCard({
    Key? key,
    required this.member,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar avec indicateur de statut
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: member.photoUrl != null
                        ? NetworkImage(member.photoUrl!)
                        : null,
                    child: member.photoUrl == null
                        ? Text(
                      (member.displayName ?? member.username)[0]
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                        : null,
                  ),
                  if (member.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Informations du membre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.displayName ?? member.username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isVerified)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue[400],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (member.status != null)
                      Text(
                        member.status!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.followersCount} abonnés',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!member.isOnline && member.lastSeen != null)
                          Expanded(
                            child: Text(
                              'Vu ${timeago.format(member.lastSeen!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flèche ou badge
              Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}