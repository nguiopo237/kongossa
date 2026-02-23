// lib/presentation/pages/premium_page_tiktok.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../model/datamodel/user_model.dart';
// import '../component/style/custum_text.dart';
// import '../component/image_component/image.dart';

class PremiumPageTikTok extends StatefulWidget {
  const PremiumPageTikTok({Key? key}) : super(key: key);

  @override
  State<PremiumPageTikTok> createState() => _PremiumPageTikTokState();
}

class _PremiumPageTikTokState extends State<PremiumPageTikTok>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPlan = 'monthly'; // monthly, yearly, lifetime

  // Plans premium
  final List<PremiumPlan> _plans = [
    PremiumPlan(
      id: 'basic',
      name: 'Kongossa Basic',
      icon: Icons.star,
      color: Colors.pink,
      monthlyPrice: 2.99,
      yearlyPrice: 29.99,
      lifetimePrice: null,
      features: [
        'Messages illimités',
        'Audio jusqu\'à 2 min',
        'Thèmes exclusifs (5)',
        'Badge profil Basic',
        'Support prioritaire',
      ],
      popular: false,
    ),
    PremiumPlan(
      id: 'pro',
      name: 'Kongossa Pro ⭐',
      icon: Icons.diamond,
      color: Colors.purple,
      monthlyPrice: 5.99,
      yearlyPrice: 59.99,
      lifetimePrice: 149.99,
      features: [
        'Tout du Basic',
        'Audio jusqu\'à 10 min',
        'Vidéos dans le chat',
        'Thèmes illimités',
        'Badge profil Pro',
        'Statistiques de chat',
        'Mode invisible',
        'Annulation de message',
      ],
      popular: true,
    ),
    PremiumPlan(
      id: 'elite',
      name: 'Kongossa Elite 👑',
      icon: Icons.emoji_events,
      color: Colors.amber,
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      lifetimePrice: 299.99,
      features: [
        'Tout du Pro',
        'Audio/vidéo illimités',
        'Effets spéciaux messages',
        'Priorité dans les recherches',
        'Badge profil Elite animé',
        'Support 24/7 dédié',
        'Early access nouvelles features',
        'Personnalisation avancée',
      ],
      popular: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =  false;
    final premiumUntil = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar style TikTok
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.black,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  isPremium ? Icons.diamond : Icons.star,
                  color: isPremium ? Colors.amber : Colors.pink,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              if (isPremium)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.pink, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Header avec statut utilisateur
          SliverToBoxAdapter(
            child: _buildUserStatusHeader(isPremium, premiumUntil),
          ),

          // Tabs : Découvrir / Mon abonnement
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[900]!, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.pink,
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: 'Découvrir'),
                  Tab(text: 'Mon abonnement'),
                ],
              ),
            ),
          ),

          // Contenu principal
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1 : Découvrir les plans
                _buildDiscoverTab(),
                // Tab 2 : Gestion abonnement
                _buildManageSubscriptionTab(isPremium, premiumUntil),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Header avec statut utilisateur
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildUserStatusHeader(bool isPremium, DateTime? premiumUntil) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
          colors: [Colors.pink, Colors.purple, Colors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium ? Colors.amber.withOpacity(0.5) : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPremium ? Icons.diamond : Icons.star_border,
                  color: isPremium ? Colors.amber : Colors.pink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Membre Premium' : 'Version Gratuite',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? premiumUntil != null
                          ? 'Valide jusqu\'au ${_formatDate(premiumUntil)}'
                          : 'Abonnement actif'
                          : 'Débloque tous les avantages',
                      style: TextStyle(
                        fontSize: 13,
                        color: isPremium ? Colors.white70 : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Upgrade'),
                ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            _buildFeaturePreview(),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Aperçu des features pour les utilisateurs gratuits
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildFeaturePreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMiniFeature(Icons.mic, 'Audio 10min'),
        _buildMiniFeature(Icons.videocam, 'Vidéos chat'),
        _buildMiniFeature(Icons.palette, 'Thèmes ∞'),
        _buildMiniFeature(Icons.visibility_off, 'Mode invisible'),
      ],
    );
  }

  Widget _buildMiniFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.pink),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Tab 1 : Découvrir les plans premium
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Toggle durée d'abonnement
        _buildDurationToggle(),

        // Liste des plans
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              return _buildPlanCard(_plans[index]);
            },
          ),
        ),

        // Footer avec garanties
        _buildPremiumFooter(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Toggle Monthly/Yearly/Lifetime
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildDurationToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildDurationOption('monthly', 'Mensuel'),
          _buildDurationOption('yearly', 'Annuel -20%'),
          _buildDurationOption('lifetime', 'À vie'),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String value, String label) {
    final isSelected = _selectedPlan == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Carte de plan premium
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildPlanCard(PremiumPlan plan) {
    final price = _getPriceForPlan(plan);
    final period = _getPeriodForSelectedPlan();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: plan.popular
            ? LinearGradient(
          colors: [
            plan.color.withOpacity(0.2),
            Colors.grey[900]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: plan.popular ? null : Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.popular ? plan.color : Colors.grey[800]!,
          width: plan.popular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header de la carte
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (plan.popular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.pink, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PLUS POPULAIRE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (plan.popular) const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: plan.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(plan.icon, color: plan.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$price / $period',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: plan.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des features
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: plan.features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Bouton d'action
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleSubscribe(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.popular ? plan.color : Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  true == true
                      ? 'Changer de plan'
                      : 'Commencer maintenant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Footer avec garanties
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildPremiumFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGuaranteeIcon(Icons.lock, 'Paiement sécurisé'),
              const SizedBox(width: 24),
              _buildGuaranteeIcon(Icons.refresh, 'Annulation anytime'),
              const SizedBox(width: 24),
              _buildGuaranteeIcon(Icons.support, 'Support 24/7'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'En souscrivant, vous acceptez nos Conditions et Politique de confidentialité',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Tab 2 : Gestion de l'abonnement
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildManageSubscriptionTab(bool isPremium, DateTime? premiumUntil) {
    if (!isPremium) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.diamond_outlined,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun abonnement actif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvre nos plans premium',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Voir les plans'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Carte statut actuel
        _buildCurrentSubscriptionCard(premiumUntil),
        const SizedBox(height: 16),

        // Options de gestion
        _buildManageOptions(),
        const SizedBox(height: 16),

        // Historique des paiements
        _buildPaymentHistory(),
        const SizedBox(height: 16),

        // FAQ Premium
        _buildPremiumFAQ(),
      ],
    );
  }

  Widget _buildCurrentSubscriptionCard(DateTime? premiumUntil) {
    final currentPlan = _plans.firstWhere(
          (p) => p.id == ('pro'),
      orElse: () => _plans[1],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.pink, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(currentPlan.icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPlan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    premiumUntil != null
                        ? 'Jusqu\'au ${_formatDate(premiumUntil)}'
                        : 'Abonnement actif',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Messages',
                  '∞',
                  Icons.chat_bubble,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Audio max',
                  currentPlan.id == 'elite' ? 'Illimité' : '10 min',
                  Icons.mic,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Thèmes',
                  currentPlan.id == 'basic' ? '5' : '∞',
                  Icons.palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildManageOption(
            Icons.credit_card,
            'Méthode de paiement',
            'Visa •••• 4242',
                () {},
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildManageOption(
            Icons.notifications,
            'Renouvellement',
            'Automatique',
                () {},
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildManageOption(
            Icons.receipt_long,
            'Factures',
            'Voir l\'historique',
                () {},
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildManageOption(
            Icons.cancel,
            'Annuler l\'abonnement',
            'Valide jusqu\'à la fin',
                () => _showCancelDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildManageOption(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[400],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive ? Colors.red[300] : Colors.grey[500],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des paiements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildFakePayments().map((payment) => _buildPaymentRow(payment)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildFakePayments() {
    return [
      {'date': DateTime.now().subtract(const Duration(days: 30)), 'amount': 5.99, 'plan': 'Pro Mensuel'},
      {'date': DateTime.now().subtract(const Duration(days: 60)), 'amount': 5.99, 'plan': 'Pro Mensuel'},
      {'date': DateTime.now().subtract(const Duration(days: 90)), 'amount': 5.99, 'plan': 'Pro Mensuel'},
    ];
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment['plan'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                _formatDate(payment['date']),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${payment['amount']}€',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFAQ() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Puis-je annuler à tout moment ?',
            'Oui, tu peux annuler ton abonnement à tout moment. Tu conserveras l\'accès aux fonctionnalités premium jusqu\'à la fin de ta période payée.',
          ),
          _buildFAQItem(
            'Comment changer de plan ?',
            'Rends-toi dans l\'onglet "Découvrir" et sélectionne le nouveau plan. La différence de prix sera ajustée au prorata.',
          ),
          _buildFAQItem(
            'Paiement sécurisé ?',
            'Absolument. Tous les paiements sont traités via des plateformes certifiées PCI-DSS. Nous ne stockons jamais tes informations bancaires.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: Colors.pink,
        collapsedIconColor: Colors.grey,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────
  double _getPriceForPlan(PremiumPlan plan) {
    switch (_selectedPlan) {
      case 'yearly':
        return plan.yearlyPrice;
      case 'lifetime':
        return plan.lifetimePrice ?? plan.yearlyPrice * 3;
      default:
        return plan.monthlyPrice;
    }
  }

  String _getPeriodForSelectedPlan() {
    switch (_selectedPlan) {
      case 'yearly':
        return 'an';
      case 'lifetime':
        return 'à vie';
      default:
        return 'mois';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleSubscribe(PremiumPlan plan) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Tu vas souscrire au plan ${plan.name}\n\nPrix: ${_getPriceForPlan(plan)}€ / ${_getPeriodForSelectedPlan()}',
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          _processPayment(plan);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
        child: const Text('Confirmer'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Annuler'),
      ),
    );
  }

  void _processPayment(PremiumPlan plan) {
    // TODO: Intégrer ton système de paiement (Stripe, in-app purchases, etc.)
    Get.snackbar(
      'Succès',
      'Abonnement ${plan.name} activé !',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // Mettre à jour Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(AppUser.info?.googleId)
        .update({
      'isPremium': true,
      'premiumPlan': plan.id,
      'premiumUntil': FieldValue.serverTimestamp(), // À calculer selon la période
    });
  }

  void _showCancelDialog() {
    Get.defaultDialog(
      title: 'Annuler l\'abonnement',
      middleText: 'Es-tu sûr de vouloir annuler ?\n\nTu conserveras l\'accès premium jusqu\'à la fin de ta période payée.',
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          _cancelSubscription();
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('Oui, annuler'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Garder'),
      ),
    );
  }

  void _cancelSubscription() {
    // TODO: Appeler ton backend pour annuler l'abonnement
    Get.snackbar(
      'Annulé',
      'Ton abonnement ne se renouvellera pas',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Modèle de plan premium
// ─────────────────────────────────────────────────────────────────────
class PremiumPlan {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double monthlyPrice;
  final double yearlyPrice;
  final double? lifetimePrice;
  final List<String> features;
  final bool popular;

  PremiumPlan({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.lifetimePrice,
    required this.features,
    this.popular = false,
  });
}


