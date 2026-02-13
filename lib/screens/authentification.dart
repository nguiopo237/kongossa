import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../sevice/controlleur/authentification/auth_controlleur.dart';
import '../sevice/controlleur/sms_controller/sms_controlleur.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});


  TextEditingController number = TextEditingController();
  final SmsController smsController = Get.find<SmsController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  size: 70,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Bienvenue sur Kongossa',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Intel",
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Connectez-vous pour continuer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: "Intel",
                ),
              ),
              const SizedBox(height: 50),
              _buildPhoneInput(),
              const SizedBox(height: 50),
              // TextFormField(
              //   controller: number,
              //   keyboardType: TextInputType.number,
              //   decoration: InputDecoration(
              //     border: OutlineInputBorder(),
              //     hintText: "Entrez numero",
              //     suffixIcon: IconButton(onPressed: () {
              //
              //     }, icon: Icon(Icons.send))
              //   ),
              // ),

              const SizedBox(height: 50),
              // _buildResendButton(),
              _buildSendButton(),

              // Bouton Google
              Obx(() {
                if (authController.isGoogleSignInAvailable.value) {
                  return _buildGoogleSignInButton();
                } else {
                  return const Text(
                    'Google Sign-In non disponible',
                    style: TextStyle(color: Colors.red),
                  );
                }
              }),

              const SizedBox(height: 20),

              // Alternative : connexion email
              TextButton(
                onPressed: () => Get.toNamed('/email-login'),
                child: const Text(
                  'Se connecter avec email',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 30),

              // Indicateur de chargement
              Obx(() {
                if (authController.isLoading.value) {
                  return Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Connexion en cours...'),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              // Message d'erreur
              Obx(() {
                if (authController.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      authController.errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: authController.isLoading.value
          ? null
          : () => authController.signInWithGoogle(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/logo.png', // Ajoutez le logo Google dans assets
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Continuer avec Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: "Intel",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: number,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '06 12 34 56 78',
            prefixText: '+33 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Format: +33 6 12 34 56 78',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: smsController.isLoading.value
            ? null
            : () {
          if (number.text.isNotEmpty) {
            print("237${number.text}");
             smsController.sendVerificationSms("+237${number.text}");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Envoyer le code SMS'),
      ),
    );
  }
}
