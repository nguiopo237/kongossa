
import "dart:convert";

import "package:http/http.dart" as http;



class Callapi{

 static String apikey = "";

  Future<String> getOpenRouterResponse(String input) async {
    const url = "https://openrouter.ai/api/v1/chat/completions";

    final headers = {
      "Authorization": "Bearer $apikey",
      "Content-Type": "application/json",
      // "HTTP-Referer": "YOUR_SITE_URL", // Optional but recommended
      // "X-Title": "YOUR_APP_NAME", // Optional but recommended
      //8465693687:AAGSAKJ2BXv8IG33lAbY9mgGIsbTz9Tm1o8
      //t.me/kmille_bot
    };

    final body = {
      "model": "openai/gpt-3.5-turbo", // Note: OpenRouter requires provider prefix
      "messages": [
        {
          "role": "user",
          "content": input,
        }
      ],
      "max_tokens": 100,
      "temperature": 0.7,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //  print(data);
        // sendMessagewithtelegram(message: data["choices"][0]["message"]["content"]);
        //  sendMessageViaBot(data["choices"][0]["message"]["content"]);
        //  await Telegram.send(username: '7762186629', message: 'Hello');
        // Corrected path to extract the response text
        return data["choices"][0]["message"]["content"];
      } else {
        print("Error response: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to get response: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error: $e");
      throw Exception("Network error: $e");
    }
  }


  // sendMessagewithtelegram({message})async{
  //   String url = "https://api.telegram.org/bot8465693687:AAGSAKJ2BXv8IG33lAbY9mgGIsbTz9Tm1o8/sendMessage?chat_id=7762186629&text=${message}";
  //   final response = await http.post(Uri.parse(url));
  //   print(response.body);
  //
  // }

  // Utilisez l'API Bot de Telegram via HTTP

  // Future<void> sendMessageViaBot(String message) async {
  //   final token = '8465693687:AAGSAKJ2BXv8IG33lAbY9mgGIsbTz9Tm1o8';
  //   final chatId = '7762186629';
  //
  //   final url = 'https://api.telegram.org/bot$token/sendMessage';
  //
  //   await http.post(
  //     Uri.parse(url),
  //     body: {
  //       'chat_id': chatId,
  //       'text': message,
  //     },
  //   );
  // }

}