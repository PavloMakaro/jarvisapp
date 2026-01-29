import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual server IP/URL
  static const String _baseUrl = 'http://10.0.2.2:8000'; // 10.0.2.2 for Android Emulator

  Future<String> sendChat(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<String> sendVoice(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/voice'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        return data['text'] ?? 'No text recognized';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}
