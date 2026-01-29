import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WsService {
  WebSocketChannel? _channel;
  // Replace with your actual server IP/URL
  static const String _wsUrl = 'ws://10.0.2.2:8000/stream';
  
  final Function(Map<String, dynamic>)? onToolRequest;
  final Function(String)? onMessage;

  WsService({this.onToolRequest, this.onMessage});

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('WS Error: $error');
        },
        onDone: () {
          debugPrint('WS Closed');
        },
      );
    } catch (e) {
      debugPrint('WS Connection Error: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'android_tool') {
        onToolRequest?.call(data);
      } else if (data['message'] != null) {
        onMessage?.call(data['message']);
      }
    } catch (e) {
      // If it's just a string message
      onMessage?.call(message.toString());
    }
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void sendToolResult(Map<String, dynamic> result) {
    _channel?.sink.add(jsonEncode(result));
  }

  void dispose() {
    _channel?.sink.close();
  }
}
