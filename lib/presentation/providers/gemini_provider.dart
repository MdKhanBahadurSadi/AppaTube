import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gemini_service.dart';

// Service provider
final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(),
);

// Chat messages provider
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [
    ChatMessage(
      text: 'হ্যালো আপু/ভাইয়া! 👋 আপ্পা এইখানে! '
            'গান নিয়া কিছু জানতে চাও? '
            'আপ্পারে জিগাও! হি হি হি 🎵',
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  Future<void> sendMessage(String text, GeminiService service) async {
    // Add user message
    state = [
      ...state,
      ChatMessage(text: text, isUser: true, time: DateTime.now()),
    ];

    // Get AI response
    final response = await service.sendMessage(text);
    
    // Add আপ্পা response
    state = [
      ...state,
      ChatMessage(text: response, isUser: false, time: DateTime.now()),
    ];
  }

  void clearChat(GeminiService service) {
    service.resetChat();
    state = [
      ChatMessage(
        text: 'হি হি হি! সব ভুইলা গেলাম! আবার কও! 🎵',
        isUser: false,
        time: DateTime.now(),
      ),
    ];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);
