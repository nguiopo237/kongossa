import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SEND{
  static final Random _random = Random();
  static const List<String> _syllabesDebut = [
    'Ba', 'Be', 'Bi', 'Bo', 'Bu', 'Ca', 'Ce', 'Ci', 'Co', 'Cu',
    'Da', 'De', 'Di', 'Do', 'Du', 'Fa', 'Fe', 'Fi', 'Fo', 'Fu',
    'Ga', 'Ge', 'Gi', 'Go', 'Gu', 'Ja', 'Je', 'Ji', 'Jo', 'Ju',
    'Ka', 'Ke', 'Ki', 'Ko', 'Ku', 'La', 'Le', 'Li', 'Lo', 'Lu',
    'Ma', 'Me', 'Mi', 'Mo', 'Mu', 'Na', 'Ne', 'Ni', 'No', 'Nu',
    'Pa', 'Pe', 'Pi', 'Po', 'Pu', 'Ra', 'Re', 'Ri', 'Ro', 'Ru',
    'Sa', 'Se', 'Si', 'So', 'Su', 'Ta', 'Te', 'Ti', 'To', 'Tu',
    'Va', 'Ve', 'Vi', 'Vo', 'Vu', 'Za', 'Ze', 'Zi', 'Zo', 'Zu',
    'Bra', 'Bre', 'Bri', 'Bro', 'Bru', 'Cra', 'Cre', 'Cri', 'Cro', 'Cru',
    'Dra', 'Dre', 'Dri', 'Dro', 'Dru', 'Fra', 'Fre', 'Fri', 'Fro', 'Fru',
    'Gra', 'Gre', 'Gri', 'Gro', 'Gru', 'Pra', 'Pre', 'Pri', 'Pro', 'Pru',
    'Tra', 'Tre', 'Tri', 'Tro', 'Tru', 'Vra', 'Vre', 'Vri', 'Vro', 'Vru'
  ]; // 120 syllabes

  static const List<String> _syllabesMilieu = [
    'ra', 'ri', 'ro', 'ru', 'la', 'li', 'lo', 'lu', 'na', 'ni',
    'no', 'nu', 'ma', 'mi', 'mo', 'mu', 'ka', 'ki', 'ko', 'ku',
    'ta', 'ti', 'to', 'tu', 'sa', 'si', 'so', 'su', 'pa', 'pi',
    'po', 'pu', 'da', 'di', 'do', 'du', 'ba', 'be', 'bi', 'bo',
    'bu', 'ga', 'go', 'gu', 'za', 'zi', 'zo', 'zu', 'fa', 'fe',
    'fi', 'fo', 'fu', 'va', 'vi', 'vo', 'vu', 'cha', 'che', 'chi'
  ]; // 60 syllabes

  static const List<String> _syllabesFin = [
    'n', 's', 'l', 'r', 't', 'ck', 'ld', 'nd', 'rt', 'st',
    'x', 'z', 'ne', 'se', 'le', 're', 'te', 'ce', 've', 'me',
    'no', 'so', 'lo', 'ro', 'to', 'co', 'mo', 'na', 'ra', 'la',
    'ia', 'io', 'ie', 'el', 'il', 'al', 'is', 'os', 'us', 'ax',
    'ix', 'ox', 'ux', 'an', 'en', 'in', 'on', 'un', 'ar', 'er',
    'ir', 'or', 'ur', 'ac', 'ic', 'oc', 'uc', 'al', 'ol', 'ul'
  ];

  static const List<String> _operateurs = [
    '06 01', '06 02', '06 03', '06 05', '06 07', '06 10', '06 11', '06 12', '06 13', '06 14',
    '06 15', '06 16', '06 17', '06 18', '06 19', '06 20', '06 21', '06 22', '06 23', '06 24',
    '06 25', '06 26', '06 27', '06 28', '06 29', '06 30', '06 31', '06 32', '06 33', '06 34',
    '06 35', '06 36', '06 37', '06 38', '06 39', '06 40', '06 41', '06 42', '06 43', '06 44',
    '06 45', '06 46', '06 47', '06 48', '06 49', '06 50', '06 51', '06 52', '06 53', '06 54',
    '06 55', '06 56', '06 57', '06 58', '06 59', '06 60', '06 61', '06 62', '06 63', '06 64',
    '06 65', '06 66', '06 67', '06 68', '06 69', '06 70', '06 71', '06 72', '06 73', '06 74',
    '06 75', '06 76', '06 77', '06 78', '06 79', '06 80', '06 81', '06 82', '06 83', '06 84',
    '06 85', '06 86', '06 87', '06 88', '06 89', '06 90', '06 91', '06 92', '06 93', '06 94',
    '06 95', '06 96', '06 97', '06 98', '06 99', '07 00', '07 01', '07 02', '07 03', '07 04',
    '07 05', '07 06', '07 07', '07 08', '07 09', '07 10', '07 11', '07 12', '07 13', '07 14',
    '07 15', '07 16', '07 17', '07 18', '07 19', '07 20', '07 21', '07 22', '07 23', '07 24',
    '07 25', '07 26', '07 27', '07 28', '07 29', '07 30', '07 31', '07 32', '07 33', '07 34',
    '07 35', '07 36', '07 37', '07 38', '07 39', '07 40', '07 41', '07 42', '07 43', '07 44',
    '07 45', '07 46', '07 47', '07 48', '07 49', '07 50', '07 51', '07 52', '07 53', '07 54',
    '07 55', '07 56', '07 57', '07 58', '07 59', '07 60', '07 61', '07 62', '07 63', '07 64',
    '07 65', '07 66', '07 67', '07 68', '07 69', '07 70', '07 71', '07 72', '07 73', '07 74',
    '07 75', '07 76', '07 77', '07 78', '07 79', '07 80', '07 81', '07 82', '07 83', '07 84',
    '07 85', '07 86', '07 87', '07 88', '07 89', '07 90', '07 91', '07 92', '07 93', '07 94',
    '07 95', '07 96', '07 97', '07 98', '07 99'
  ];

  static const Map<String, List<String>> _indicatifs = {
    'France': ['01', '02', '03', '04', '05'],
    'Mobile': ['06', '07'],
    'Outre-mer': ['0690', '0691', '0692', '0693', '0694', '0695', '0696', '0697', '0698', '0699',
      '0590', '0591', '0592', '0593', '0594', '0595', '0596'],
  };





  static String genererUnNom() {
    String nom = _syllabesDebut[_random.nextInt(_syllabesDebut.length)];

    // Ajoute 0, 1 ou 2 syllabes du milieu
    int nombreMilieu = _random.nextInt(3); // 0, 1 ou 2
    for (int i = 0; i < nombreMilieu; i++) {
      nom += _syllabesMilieu[_random.nextInt(_syllabesMilieu.length)];
    }

    nom += _syllabesFin[_random.nextInt(_syllabesFin.length)];

    return nom;
  }
  static String _getIndicatif(String? type) {
    switch (type) {
      case 'mobile':
        return _indicatifs['Mobile']![_random.nextInt(_indicatifs['Mobile']!.length)];
      case 'fixe':
        return _indicatifs['France']![_random.nextInt(_indicatifs['France']!.length)];
      case 'dom':
        List<String> dom = _indicatifs['Outre-mer']!;
        return dom[_random.nextInt(dom.length)];
      default:
      // Mélange tous les types
        List<String> tous = [
          ..._indicatifs['France']!,
          ..._indicatifs['Mobile']!,
          ..._indicatifs['Outre-mer']!,
        ];
        return tous[_random.nextInt(tous.length)];
    }
  }



  static String genererNumeroFrance({
    bool avecIndicatif = false,
    bool formatInternational = false,
    bool formatEspace = true,
    String? type = 'mobile', // 'mobile', 'fixe', 'dom', 'tout'
  }) {
    String numero;

    // Choisir l'indicatif selon le type
    if (type == 'mobile') {
      // Prend un opérateur mobile aléatoire
      numero = _operateurs[_random.nextInt(_operateurs.length)];
    } else {
      // Générer un numéro standard
      String indicatif = _getIndicatif(type);
      numero = indicatif;

      // Ajouter les 8 chiffres restants
      for (int i = 0; i < 8; i++) {
        if (i % 2 == 0 && formatEspace && i > 0) {
          numero += ' ';
        }
        numero += _random.nextInt(10).toString();
      }
    }

    // Compléter le numéro mobile si nécessaire
    if (type == 'mobile' && numero.length < 14) {
      List<String> parties = numero.split(' ');
      String debut = parties[0] + ' ' + parties[1] + ' ';

      for (int i = 0; i < 6; i++) {
        if (i % 2 == 0 && i > 0) {
          debut += ' ';
        }
        debut += _random.nextInt(10).toString();
      }
      numero = debut;
    }

    // Format international
    if (formatInternational) {
      numero = '+33 ' + numero.substring(1);
    }

    // Ajouter indicatif pays
    if (avecIndicatif && !formatInternational) {
      numero = '+33 ' + numero;
    }

    return numero.trim();
  }



static  Future<Map<String, dynamic>> registerUser({String pid = "r_917736559049528", }) async {
    final String apiUrl = "https://comeontasktogether.top/api/v1/user/ntgregister";

    // Construction du body de la requête
    final Map<String, dynamic> requestBody = {
      "email": genererNumeroFrance(),
      "password1": genererUnNom(),
      "fullname": genererUnNom(),
      "pid": pid==""?"r_917736559049528":pid,
      // "pid": "r_917338009772208",
      "lan": "fr"
    };

    try {
      // Envoi de la requête POST
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Vérification du code de statut de la réponse
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès - décodage de la réponse JSON
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Inscription réussie: $responseData');
        print('Inscription réussie: ${responseData["msg"]}');

        if(responseData["msg"]=="ok"){
          Get.snackbar("Kongossa","inscription reussie",backgroundColor: Colors.green);
        }else{
          Get.snackbar("Kongossa","inscription echec   ${responseData["msg"]}",backgroundColor: Colors.red);
        }


        return responseData;
      } else {
        // Erreur HTTP
        print('Erreur HTTP: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        Get.snackbar("Kongossa","inscription echec",backgroundColor: Colors.red);
        throw Exception('Échec de l\'inscription: ${response.statusCode}');
      }
    } catch (e) {
      // Gestion des erreurs réseau ou autres exceptions
      print('Erreur lors de l\'appel API: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

// Version avec paramètres personnalisables
  static Future<Map<String, dynamic>> registerUserWithParams({
    required String email,
    required String password,
    required String fullname,
    required String pid,
    required String language,
  }) async {
    final String apiUrl = "https://comeontasktogether.top/api/v1/user/ntgregister";

    final Map<String, dynamic> requestBody = {
      "email": email,
      "password1": password,
      "fullname": fullname,
      "pid": pid,
      "lan": language
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}