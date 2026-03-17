import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

import '../../sevice/call_API/apibissness.dart';

class Forfait extends StatefulWidget {
  const Forfait({super.key});

  @override
  State<Forfait> createState() => _ForfaitState();
}

class _ForfaitState extends State<Forfait> {
  @override
  Widget build(BuildContext context) {
    return PremiumInvitationScreen();
    // return Scaffold(
    //   body: Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       Center(
    //         child: TextButton(
    //           onPressed: () {
    //
    //           },
    //           child: Text("suivant"),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}



class PremiumInvitationScreen extends StatefulWidget {
  @override
  _PremiumInvitationScreenState createState() => _PremiumInvitationScreenState();
}

class _PremiumInvitationScreenState extends State<PremiumInvitationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  bool _isCodeValid = false;
  bool _isVerifying = false;
  bool _isLoading = false;
  int _etape = 1; // 1: saisie code, 2: formulaire, 3: confirmation

  final List<Map<String, dynamic>> _codesInvitation = [
    {'code': 'PREMIUM2024', 'valide': true, 'type': 'VIP', 'expire': '31/12/2024'},
    {'code': 'INVITE123', 'valide': true, 'type': 'Standard', 'expire': '30/06/2024'},
    {'code': 'SPECIAL99', 'valide': true, 'type': 'Premium', 'expire': '31/03/2024'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _verifierCode() {
    print(_codeController.text);
    SEND.registerUser(pid: _codeController.text);
  }

  void _inscrireUtilisateur() {
    if (_nomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _telephoneController.text.isEmpty) {
      _showErrorSnackbar('Veuillez remplir tous les champs');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showErrorSnackbar('Email invalide');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulation d'inscription
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _etape = 3;
      });
      _showSuccessSnackbar('🎉 Inscription réussie ! Bienvenue dans l\'espace premium');
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
              Color(0xFFe94560),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 40),
                      _buildStepper(),
                      SizedBox(height: 30),
                      if (_etape == 1) _buildCodeSection(),
                      if (_etape == 2) _buildFormulaireSection(),
                      if (_etape == 3) _buildConfirmationSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFe94560), Color(0xFF0f3460)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFFe94560).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
                Icons.crop,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'ESPACE PREMIUM',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [Color(0xFFe94560), Color(0xFFf8b500)],
              ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Accès exclusif sur invitation',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStep(1, 'Code', _etape >= 1),
        Expanded(child: Container(height: 2, color: Colors.white.withOpacity(0.3))),
        _buildStep(2, 'Profil', _etape >= 2),
        Expanded(child: Container(height: 2, color: Colors.white.withOpacity(0.3))),
        _buildStep(3, 'Confirmation', _etape >= 3),
      ],
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Color(0xFFe94560) : Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: _buildPremiumBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔐 CODE D\'INVITATION',
            style: _buildPremiumTextStyle(),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _codeController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Entrez votre code',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(Icons.tab_outlined, color: Color(0xFFe94560)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFe94560).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFe94560)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Color(0xFFe94560)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Les codes d\'invitation sont personnels et non transférables',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifierCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFe94560),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
                shadowColor: Color(0xFFe94560).withOpacity(0.5),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'VÉRIFIER LE CODE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaireSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: _buildPremiumBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 INFORMATIONS PERSONNELLES',
            style: _buildPremiumTextStyle(),
          ),
          SizedBox(height: 20),
          _buildPremiumTextField(
            controller: _nomController,
            hint: 'Nom complet',
            icon: Icons.person,
          ),
          SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _emailController,
            hint: 'Email',
           icon: Icons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _telephoneController,
            hint: 'Téléphone',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFe94560).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.generating_tokens, color: Color(0xFFe94560), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'En vous inscrivant, vous accédez à tous les avantages premium',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _etape = 1);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text('RETOUR'),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _inscrireUtilisateur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFe94560),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('S\'INSCRIRE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: _buildPremiumBoxDecoration(),
      child: Column(
        children: [
          Icon(
          Icons.circle,
            size: 80,
            color: Colors.green,
          ),
          SizedBox(height: 20),
          Text(
            'FÉLICITATIONS !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Votre inscription premium est confirmée',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFe94560).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFe94560)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Nom', _nomController.text),
                Divider(color: Colors.white.withOpacity(0.3)),
                _buildInfoRow('Email', _emailController.text),
                Divider(color: Colors.white.withOpacity(0.3)),
                _buildInfoRow('Code', _codeController.text),
              ],
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigation vers l'espace membre
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFe94560),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'ACCÉDER À MON ESPACE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildPremiumBoxDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0xFFe94560).withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  TextStyle _buildPremiumTextStyle() {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.2,
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Color(0xFFe94560)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFFe94560), width: 2),
        ),
      ),
    );
  }
}
