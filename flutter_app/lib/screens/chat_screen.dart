import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../services/android_tools.dart';
import '../services/audio_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final AudioService _audioService = AudioService();
  bool _isTyping = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final wsService = Provider.of<WsService>(context, listen: false);
    final androidTools = Provider.of<AndroidTools>(context, listen: false);

    // Re-initialize WsService callbacks here or in a better place
    // Since WsService is provided, we might need to set callbacks on it if it's a singleton or similar
    // But Provider returns a new instance or the same instance. 
    // Let's assume we can set callbacks. 
    // Ideally WsService should expose a stream, but for simplicity:
    
    // Note: In a real app, we'd use a StreamBuilder or similar.
    // Here we will hack it slightly by creating a new WsService or modifying it to accept callbacks if not already connected.
    // Actually, the provider creates it. We should probably have a method to set listener.
    // But the WsService I wrote takes callbacks in constructor. 
    // Let's modify WsService usage or just create a new one here? 
    // No, Provider is better. Let's assume we can't easily change callbacks on the fly with that implementation.
    // I will modify WsService in my mind to allow setting callbacks, or just use it directly here.
    // Actually, let's just instantiate WsService here for simplicity of the "State" owning the connection logic for this screen.
    // Or better, let's use the one from Provider but we need to handle the callbacks.
    
    // Let's just create a local WsService for this screen to ensure callbacks work as expected with setState.
    // The Provider was a good idea for global state, but for this simple app, local is fine.
    // However, I already put it in Provider.
    // Let's ignore the Provider for WsService and create it here to be safe and simple.
    
    _initWs();
  }

  late WsService _wsService;

  void _initWs() {
    final androidTools = Provider.of<AndroidTools>(context, listen: false);
    
    _wsService = WsService(
      onMessage: (msg) {
        setState(() {
          _isTyping = false;
          // Check if last message is from bot, if so append, else create new
          if (_messages.isNotEmpty && !_messages.last['isUser']) {
             _messages.last['message'] += msg; // Simple streaming append
          } else {
            _messages.add({'message': msg, 'isUser': false});
          }
        });
        _scrollToBottom();
      },
      onToolRequest: (req) async {
        final tool = req['tool'];
        final args = req['args'] as Map<String, dynamic>;
        final result = await androidTools.executeTool(tool, args);
        _wsService.sendToolResult(result);
      },
    );
    _wsService.connect();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final text = _controller.text;
    _controller.clear();

    setState(() {
      _messages.add({'message': text, 'isUser': true});
      _isTyping = true;
    });
    _scrollToBottom();

    final apiService = Provider.of<ApiService>(context, listen: false);
    // We can use API or WS. Prompt says REST for chat.
    final response = await apiService.sendChat(text);
    
    setState(() {
      _isTyping = false;
      _messages.add({'message': response, 'isUser': false});
    });
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioService.stopRecording();
      setState(() => _isRecording = false);
      
      if (path != null) {
        setState(() {
          _messages.add({'message': '🎤 Voice Message', 'isUser': true});
          _isTyping = true;
        });
        
        final apiService = Provider.of<ApiService>(context, listen: false);
        final response = await apiService.sendVoice(path);
        
        setState(() {
          _isTyping = false;
          _messages.add({'message': response, 'isUser': false});
        });
        _scrollToBottom();
      }
    } else {
      await _audioService.startRecording();
      setState(() => _isRecording = true);
    }
  }

  @override
  void dispose() {
    _wsService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jarvis'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageBubble(
                  message: msg['message'],
                  isUser: msg['isUser'],
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(), // Simple typing indicator
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  color: _isRecording ? Colors.red : Colors.grey,
                  onPressed: _toggleRecording,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: const Color(0xFF2E2E2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
