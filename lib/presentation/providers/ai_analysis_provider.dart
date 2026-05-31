import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/services/ai_analysis_service.dart';
import '../../core/services/transcript_service.dart';

class AiAnalysisState {
  final bool isLoadingTranscript;
  final bool isLoadingSummary;
  final bool isLoadingKeyPoints;
  final bool isLoadingTimestamps;
  final bool isLoadingLearning;
  final bool isChatLoading;

  final String? transcript;
  final bool transcriptAvailable;
  final String? transcriptError;

  final VideoSummary? summary;
  final KeyPointsResult? keyPoints;
  final List<SmartTimestamp> timestamps;
  final LearningContent? learningContent;
  final List<String> followUpSuggestions;
  final List<String> chatMessages; // alternating user/ai
  final ChatSession? chatSession;

  final String selectedSummaryLevel; // '30s', '2min', 'detailed'

  const AiAnalysisState({
    this.isLoadingTranscript = false,
    this.isLoadingSummary = false,
    this.isLoadingKeyPoints = false,
    this.isLoadingTimestamps = false,
    this.isLoadingLearning = false,
    this.isChatLoading = false,
    this.transcript,
    this.transcriptAvailable = false,
    this.transcriptError,
    this.summary,
    this.keyPoints,
    this.timestamps = const [],
    this.learningContent,
    this.followUpSuggestions = const [],
    this.chatMessages = const [],
    this.chatSession,
    this.selectedSummaryLevel = '30s',
  });

  AiAnalysisState copyWith({
    bool? isLoadingTranscript,
    bool? isLoadingSummary,
    bool? isLoadingKeyPoints,
    bool? isLoadingTimestamps,
    bool? isLoadingLearning,
    bool? isChatLoading,
    String? transcript,
    bool? transcriptAvailable,
    String? transcriptError,
    VideoSummary? summary,
    KeyPointsResult? keyPoints,
    List<SmartTimestamp>? timestamps,
    LearningContent? learningContent,
    List<String>? followUpSuggestions,
    List<String>? chatMessages,
    ChatSession? chatSession,
    String? selectedSummaryLevel,
  }) {
    return AiAnalysisState(
      isLoadingTranscript: isLoadingTranscript ?? this.isLoadingTranscript,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      isLoadingKeyPoints: isLoadingKeyPoints ?? this.isLoadingKeyPoints,
      isLoadingTimestamps: isLoadingTimestamps ?? this.isLoadingTimestamps,
      isLoadingLearning: isLoadingLearning ?? this.isLoadingLearning,
      isChatLoading: isChatLoading ?? this.isChatLoading,
      transcript: transcript ?? this.transcript,
      transcriptAvailable: transcriptAvailable ?? this.transcriptAvailable,
      transcriptError: transcriptError ?? this.transcriptError,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      timestamps: timestamps ?? this.timestamps,
      learningContent: learningContent ?? this.learningContent,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
      chatMessages: chatMessages ?? this.chatMessages,
      chatSession: chatSession ?? this.chatSession,
      selectedSummaryLevel: selectedSummaryLevel ?? this.selectedSummaryLevel,
    );
  }
}

class AiAnalysisNotifier extends Notifier<AiAnalysisState> {
  @override
  AiAnalysisState build() => const AiAnalysisState();

  // Load transcript first
  Future<void> loadTranscript(String videoId) async {
    state = state.copyWith(isLoadingTranscript: true, transcriptError: null);
    final service = ref.read(transcriptServiceProvider);
    final transcript = await service.getTranscript(videoId);
    if (transcript == null) {
      state = state.copyWith(
        isLoadingTranscript: false,
        transcriptAvailable: false,
        transcriptError: 'No transcript available for this video.',
      );
      return;
    }
    state = state.copyWith(
      isLoadingTranscript: false,
      transcript: transcript,
      transcriptAvailable: true,
    );
  }

  Future<void> generateSummary(String videoTitle) async {
    if (state.transcript == null) return;
    state = state.copyWith(isLoadingSummary: true);
    final service = ref.read(aiAnalysisServiceProvider);
    final summary = await service.generateSummary(
        state.transcript!, videoTitle);
    state = state.copyWith(isLoadingSummary: false, summary: summary);
  }

  Future<void> extractKeyPoints(String videoTitle) async {
    if (state.transcript == null) return;
    state = state.copyWith(isLoadingKeyPoints: true);
    final service = ref.read(aiAnalysisServiceProvider);
    final kp = await service.extractKeyPoints(
        state.transcript!, videoTitle);
    state = state.copyWith(isLoadingKeyPoints: false, keyPoints: kp);
    // Also get follow-up suggestions using main topics
    if (kp != null) {
      final suggestions = await service.getFollowUpSuggestions(
          videoTitle, kp.mainTopics);
      state = state.copyWith(followUpSuggestions: suggestions);
    }
  }

  Future<void> generateTimestamps(String videoTitle) async {
    if (state.transcript == null) return;
    state = state.copyWith(isLoadingTimestamps: true);
    final service = ref.read(aiAnalysisServiceProvider);
    final ts = await service.generateTimestamps(
        state.transcript!, videoTitle);
    state = state.copyWith(isLoadingTimestamps: false, timestamps: ts);
  }

  Future<void> generateLearningContent(String videoTitle) async {
    if (state.transcript == null) return;
    state = state.copyWith(isLoadingLearning: true);
    final service = ref.read(aiAnalysisServiceProvider);
    final lc = await service.generateLearningContent(
        state.transcript!, videoTitle);
    state = state.copyWith(isLoadingLearning: false, learningContent: lc);
  }

  void initVideoChat(String videoTitle) {
    if (state.transcript == null) return;
    final service = ref.read(aiAnalysisServiceProvider);
    final session = service.startVideoChat(
        state.transcript!, videoTitle);
    state = state.copyWith(
      chatSession: session,
      chatMessages: [
        'AI: I have analyzed this video. Ask me anything!',
      ],
    );
  }

  Future<void> sendChatMessage(String message) async {
    if (state.chatSession == null) return;
    state = state.copyWith(
      isChatLoading: true,
      chatMessages: [...state.chatMessages, 'You: $message'],
    );
    final service = ref.read(aiAnalysisServiceProvider);
    final response = await service.askAboutVideo(
        state.chatSession!, message);
    state = state.copyWith(
      isChatLoading: false,
      chatMessages: [...state.chatMessages, 'AI: $response'],
    );
  }

  void setSummaryLevel(String level) {
    state = state.copyWith(selectedSummaryLevel: level);
  }

  void reset() => state = const AiAnalysisState();
}

final aiAnalysisProvider =
    NotifierProvider<AiAnalysisNotifier, AiAnalysisState>(
  AiAnalysisNotifier.new,
);
