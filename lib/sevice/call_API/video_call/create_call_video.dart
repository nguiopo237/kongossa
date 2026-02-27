import 'dart:convert';
import 'package:http/http.dart' as http;


class CreateCallVideo {

// Remplacez par votre token généré depuis le dashboard
  String token = "6c7af3b1-bddb-4689-accb-b2d57b303405";

  Future<String> createRoom() async {
    final http.Response httpResponse = await http.post(
      Uri.parse("https://api.videosdk.live/v2/rooms"),
      headers: {'Authorization': token},
    );
    // Extrait et retourne le roomId de la réponse JSON
    return json.decode(httpResponse.body)['roomId'];
  }
}