import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/video_model.dart';
import '../providers/ai_analysis_provider.dart';
import '../providers/player_provider.dart';
import '../../core/services/ai_analysis_service.dart';
import '../../core/services/audio_handler.dart';

class AiInsightsScreen extends ConsumerStatefulWidget {
  final VideoModel video;
  const AiInsightsScreen({super.key, required this.video});

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(aiAnalysisProvider.notifier).loadTranscript(widget.video.id);
      if (ref.read(aiAnalysisProvider).transcriptAvailable) {
        ref.read(aiAnalysisProvider.notifier).generateSummary(widget.video.title);
        ref.read(aiAnalysisProvider.notifier).extractKeyPoints(widget.video.title);
      }
    });
  }

  @override
  void dispose() {
    // Avoid resetting if it's just a rebuild, but the prompt says reset on dispose.
    // However, we should be careful if we navigate away and back.
    Future.microtask(() => ref.read(aiAnalysisProvider.notifier).reset());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAnalysisProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Insights',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AiAnalysisState state) {
    if (state.isLoadingTranscript) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.red),
            const SizedBox(height: 16),
            const Text('Analyzing video...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (state.transcriptError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.subtitles_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No transcript available',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('This video does not have captions',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (state.transcriptAvailable) {
      return DefaultTabController(
        length: 5,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.red, width: 3),
              ),
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Key Points'),
                Tab(text: 'Timestamps'),
                Tab(text: 'Learn'),
                Tab(text: 'Chat'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SummaryTab(videoTitle: widget.video.title),
                  _KeyPointsTab(videoTitle: widget.video.title),
                  _TimestampsTab(videoTitle: widget.video.title),
                  _LearningTab(videoTitle: widget.video.title),
                  _ChatTab(videoTitle: widget.video.title),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ════════════════════════════ TAB 1: SUMMARY ════════════════════════════

class _SummaryTab extends ConsumerWidget {
  final String videoTitle;
  const _SummaryTab({required this.videoTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLevelChip(ref, '30s', '30 sec'),
              const SizedBox(width: 8),
              _buildLevelChip(ref, '2min', '2 min'),
              const SizedBox(width: 8),
              _buildLevelChip(ref, 'detailed', 'Detailed'),
            ],
          ),
          const SizedBox(height: 20),
          if (state.isLoadingSummary)
            _buildShimmerSummary()
          else if (state.summary != null)
            _buildSummaryContent(state)
          else
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => ref.read(aiAnalysisProvider.notifier).generateSummary(videoTitle),
                child: const Text('Generate Summary', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(WidgetRef ref, String level, String label) {
    final selectedLevel = ref.watch(aiAnalysisProvider).selectedSummaryLevel;
    final isSelected = selectedLevel == level;

    return GestureDetector(
      onTap: () => ref.read(aiAnalysisProvider.notifier).setSummaryLevel(level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSummary() {
    return Column(
      children: List.generate(3, (index) => Container(
        height: 20,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }

  Widget _buildSummaryContent(AiAnalysisState state) {
    String content = '';
    if (state.selectedSummaryLevel == '30s') content = state.summary!.thirtySeconds;
    else if (state.selectedSummaryLevel == '2min') content = state.summary!.twoMinutes;
    else content = state.summary!.detailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(state.selectedSummaryLevel),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Colors.red, width: 3)),
          ),
          child: const Text(
            'Powered by Gemini AI',
            style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════ TAB 2: KEY POINTS ════════════════════════════

class _KeyPointsTab extends ConsumerWidget {
  final String videoTitle;
  const _KeyPointsTab({required this.videoTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisProvider);

    if (state.isLoadingKeyPoints) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    if (state.keyPoints == null) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => ref.read(aiAnalysisProvider.notifier).extractKeyPoints(videoTitle),
          child: const Text('Extract Key Points', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final kp = state.keyPoints!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKPSection('Key Points', kp.keyPoints, Colors.blue, Icons.circle, iconSize: 6),
        _buildKPSection('Action Items', kp.actionItems, Colors.green, Icons.check_circle_outline),
        _buildKPSection('Tips', kp.tips, Colors.amber, Icons.lightbulb_outline),
        
        const Text('Main Topics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kp.mainTopics.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(t, style: const TextStyle(color: Colors.red, fontSize: 12)),
          )).toList(),
        ),
        
        if (state.followUpSuggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Follow-up Learning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...state.followUpSuggestions.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
            title: Text(s, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          )),
        ],
      ],
    );
  }

  Widget _buildKPSection(String title, List<String> items, Color color, IconData icon, {double iconSize = 18}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 3))),
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(icon, color: color, size: iconSize),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(item, style: const TextStyle(color: Colors.grey, fontSize: 14))),
            ],
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ════════════════════════════ TAB 3: TIMESTAMPS ════════════════════════════

class _TimestampsTab extends ConsumerWidget {
  final String videoTitle;
  const _TimestampsTab({required this.videoTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisProvider);

    if (state.timestamps.isEmpty && !state.isLoadingTimestamps) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => ref.read(aiAnalysisProvider.notifier).generateTimestamps(videoTitle),
          child: const Text('Generate Smart Timestamps', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    if (state.isLoadingTimestamps) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.timestamps.length,
      itemBuilder: (context, index) {
        final ts = state.timestamps[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTime(ts.timeSeconds),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ts.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(ts.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline, color: Colors.red),
                onPressed: () {
                  final handler = ref.read(audioHandlerProvider);
                  handler.seek(Duration(seconds: ts.timeSeconds));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ════════════════════════════ TAB 4: LEARNING ════════════════════════════

class _LearningTab extends ConsumerWidget {
  final String videoTitle;
  const _LearningTab({required this.videoTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisProvider);

    if (state.learningContent == null && !state.isLoadingLearning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Learning Mode',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Transform this video into structured notes and flashcards',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => ref.read(aiAnalysisProvider.notifier).generateLearningContent(videoTitle),
                child: const Text('Generate Learning Content', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoadingLearning) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    final lc = state.learningContent!;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildDifficultyBadge(lc.difficulty),
                const Spacer(),
                Text(lc.estimatedReadTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const TabBar(
            indicatorColor: Colors.red,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Notes'),
              Tab(text: 'Flashcards'),
              Tab(text: 'Revision'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildNotesTab(lc.structuredNotes),
                _buildFlashcardsTab(lc.flashcards),
                _buildRevisionTab(lc.revisionPoints),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'beginner': color = Colors.green; break;
      case 'intermediate': color = Colors.orange; break;
      case 'advanced': color = Colors.red; break;
      default: color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(difficulty.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNotesTab(List<String> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Expanded(child: Text(notes[index], style: const TextStyle(color: Colors.grey, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab(List<Flashcard> flashcards) {
    if (flashcards.isEmpty) return const Center(child: Text('No flashcards', style: TextStyle(color: Colors.grey)));
    return Padding(
      padding: const EdgeInsets.all(32),
      child: PageView.builder(
        itemCount: flashcards.length,
        itemBuilder: (context, index) => _FlashcardWidget(flashcard: flashcards[index]),
      ),
    );
  }

  Widget _buildRevisionTab(List<String> points) {
    return _RevisionList(points: points);
  }
}

class _RevisionList extends StatefulWidget {
  final List<String> points;
  const _RevisionList({required this.points});

  @override
  State<_RevisionList> createState() => _RevisionListState();
}

class _RevisionListState extends State<_RevisionList> {
  late Set<int> checked;

  @override
  void initState() {
    super.initState();
    checked = {};
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.points.length,
      itemBuilder: (context, index) => ListTile(
        onTap: () => setState(() => checked.contains(index) ? checked.remove(index) : checked.add(index)),
        leading: Icon(
          checked.contains(index) ? Icons.check_box : Icons.check_box_outline_blank,
          color: checked.contains(index) ? Colors.red : Colors.grey,
        ),
        title: Text(
          widget.points[index],
          style: TextStyle(
            color: checked.contains(index) ? Colors.grey : Colors.white,
            decoration: checked.contains(index) ? TextDecoration.lineThrough : null,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  const _FlashcardWidget({required this.flashcard});

  @override
  State<_FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<_FlashcardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) _controller.forward();
    else _controller.reverse();
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildCardSide(widget.flashcard.question, 'QUESTION', Colors.white)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(widget.flashcard.answer, 'ANSWER', Colors.red),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(String text, String label, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(text, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Tap to flip', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════ TAB 5: CHAT ════════════════════════════

class _ChatTab extends ConsumerStatefulWidget {
  final String videoTitle;
  const _ChatTab({required this.videoTitle});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage([String? text]) {
    final message = text ?? _controller.text.trim();
    if (message.isEmpty) return;
    if (text == null) _controller.clear();
    
    ref.read(aiAnalysisProvider.notifier).sendChatMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAnalysisProvider);

    if (state.chatSession == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.chat_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () => ref.read(aiAnalysisProvider.notifier).initVideoChat(widget.videoTitle),
              child: const Text('Start Chatting About This Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            const Text('Or ask directly:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'What are the main points?',
                'Summarize in simple terms',
                'What should I learn from this?',
                'What are the key takeaways?',
              ].map((q) => ActionChip(
                backgroundColor: const Color(0xFF1A1A1A),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                label: Text(q, style: const TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  ref.read(aiAnalysisProvider.notifier).initVideoChat(widget.videoTitle);
                  ref.read(aiAnalysisProvider.notifier).sendChatMessage(q);
                },
              )).toList(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.chatMessages.length,
            itemBuilder: (context, index) {
              final msg = state.chatMessages[index];
              final isAI = msg.startsWith('AI:');
              final text = isAI ? msg.substring(3).trim() : msg.substring(4).trim();

              return Align(
                alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isAI ? const Color(0xFF1A1A1A) : Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isAI ? const Radius.circular(4) : const Radius.circular(16),
                      bottomRight: isAI ? const Radius.circular(16) : const Radius.circular(4),
                    ),
                  ),
                  child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              );
            },
          ),
        ),
        if (state.isChatLoading)
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Thinking...', style: TextStyle(color: Colors.grey, fontSize: 12))),
          ),
        _buildInputBar(),
      ],
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
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask about this video...',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
