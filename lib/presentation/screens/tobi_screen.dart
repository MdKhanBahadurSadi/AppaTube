import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gemini_provider.dart';

class TobiScreen extends ConsumerStatefulWidget {
  const TobiScreen({super.key});

  @override
  ConsumerState<TobiScreen> createState() => _TobiScreenState();
}

class _TobiScreenState extends ConsumerState<TobiScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    if (text == null) {
      _textController.clear();
    }
    
    setState(() => _isLoading = true);
    _scrollToBottom();

    await ref.read(chatProvider.notifier).sendMessage(
          messageText,
          ref.read(geminiServiceProvider),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE40000),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('src/appaagent.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আপ্পা',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                Text('সবসময় অনলাইন 🟢',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF666666)),
            onPressed: () {
              ref
                  .read(chatProvider.notifier)
                  .clearChat(ref.read(geminiServiceProvider));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          if (messages.length == 1 && !_isLoading) _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'আমার মনের ঘরেতে 🎵',
      'কালো কুকুরে',
      'মোবাইল দ্যাও 😴',
      'লেখতে বসো',
      'ভাত খাও 🎶'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) => GestureDetector(
          onTap: () => _sendMessage(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0000),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE40000).withOpacity(0.3)),
            ),
            child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFE40000),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(message.text,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFE40000),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('src/appaagent.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8, right: 60),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(message.text,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.5)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: const BoxDecoration(
              color: const Color(0xFFE40000),
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('src/appaagent.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8, right: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('কী বলবো তাই ভাবতেছি 🤔🤔 ',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                TypingIndicatorDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: const Color(0xFF0A0A0A),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'আপ্পাকে কিছু জিজ্ঞেস করো...',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isLoading ? const Color(0xFF333333) : const Color(0xFFE40000),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicatorDots extends StatefulWidget {
  const TypingIndicatorDots({super.key});

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true);
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(controller);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return FadeTransition(
          opacity: _animations[index],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE40000),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
