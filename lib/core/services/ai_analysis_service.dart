import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiAnalysisService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  late final GenerativeModel _model;
  
  AiAnalysisService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2000,
      ),
    );
  }

  // ── 1. VIDEO SUMMARY (multi-level) ──────────────────────
  Future<VideoSummary?> generateSummary(
      String transcript, String videoTitle) async {
    try {
      final prompt = '''
You are analyzing a YouTube video titled: "$videoTitle"

Transcript:
$transcript

Generate THREE levels of summary in JSON format (no markdown, pure JSON):
{
  "thirtySeconds": "one paragraph, max 3 sentences",
  "twoMinutes": "detailed paragraph, 6-8 sentences covering main points",
  "detailed": "full structured summary with sections"
}
Return ONLY valid JSON, nothing else.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return VideoSummary(
        thirtySeconds: json['thirtySeconds'] ?? '',
        twoMinutes: json['twoMinutes'] ?? '',
        detailed: json['detailed'] ?? '',
      );
    } catch (e) {
      print('[AiAnalysisService] Summary error: $e');
      return null;
    }
  }

  // ── 2. KEY POINTS & ACTION ITEMS ────────────────────────
  Future<KeyPointsResult?> extractKeyPoints(
      String transcript, String videoTitle) async {
    try {
      final prompt = '''
Analyze this YouTube video transcript titled "$videoTitle":
$transcript

Return JSON only (no markdown):
{
  "keyPoints": ["point 1", "point 2", ...],
  "actionItems": ["action 1", "action 2", ...],
  "tips": ["tip 1", "tip 2", ...],
  "mainTopics": ["topic 1", "topic 2", ...]
}
Max 8 items per array. Be concise.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return KeyPointsResult(
        keyPoints: List<String>.from(json['keyPoints'] ?? []),
        actionItems: List<String>.from(json['actionItems'] ?? []),
        tips: List<String>.from(json['tips'] ?? []),
        mainTopics: List<String>.from(json['mainTopics'] ?? []),
      );
    } catch (e) {
      return null;
    }
  }

  // ── 3. SMART TIMESTAMPS ──────────────────────────────────
  Future<List<SmartTimestamp>> generateTimestamps(
      String transcript, String videoTitle) async {
    try {
      final prompt = '''
Analyze this timestamped transcript of "$videoTitle":
$transcript

Identify 5-8 most important moments/sections.
Return JSON array only:
[
  {"timeSeconds": 0, "label": "Introduction", "description": "brief desc"},
  {"timeSeconds": 120, "label": "Main Topic", "description": "brief desc"}
]
Use actual timestamps from the transcript. Return ONLY JSON array.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      return list.map((item) => SmartTimestamp(
        timeSeconds: (item['timeSeconds'] as num).toInt(),
        label: item['label'] ?? '',
        description: item['description'] ?? '',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // ── 4. LEARNING MODE ────────────────────────────────────
  Future<LearningContent?> generateLearningContent(
      String transcript, String videoTitle) async {
    try {
      final prompt = '''
Transform this educational video "$videoTitle" transcript into 
structured learning material.
Transcript: $transcript

Return JSON only:
{
  "structuredNotes": ["note 1", "note 2", ...],
  "flashcards": [
    {"question": "Q?", "answer": "A"},
    ...
  ],
  "revisionPoints": ["point 1", "point 2", ...],
  "difficulty": "beginner/intermediate/advanced",
  "estimatedReadTime": "X minutes"
}
Max 10 notes, 6 flashcards, 8 revision points.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return LearningContent(
        structuredNotes: List<String>.from(json['structuredNotes'] ?? []),
        flashcards: (json['flashcards'] as List? ?? [])
            .map((f) => Flashcard(
                  question: f['question'] ?? '',
                  answer: f['answer'] ?? '',
                ))
            .toList(),
        revisionPoints: List<String>.from(json['revisionPoints'] ?? []),
        difficulty: json['difficulty'] ?? 'intermediate',
        estimatedReadTime: json['estimatedReadTime'] ?? '5 minutes',
      );
    } catch (e) {
      return null;
    }
  }

  // ── 5. CHAT WITH VIDEO ───────────────────────────────────
  ChatSession startVideoChat(String transcript, String videoTitle) {
    final systemPrompt = '''
You are an AI assistant helping users understand a YouTube video.
Video Title: "$videoTitle"
Full Transcript:
$transcript

Answer questions based ONLY on the video content.
Be concise and helpful. If something is not in the video, say so.
''';
    return _model.startChat(history: [
      Content.text(systemPrompt),
      Content.model([TextPart('I have read the video transcript for "$videoTitle". Ask me anything about it!')]),
    ]);
  }

  Future<String> askAboutVideo(ChatSession chat, String question) async {
    try {
      final response = await chat.sendMessage(Content.text(question));
      return response.text ?? 'Could not generate response.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── 6. SMART FOLLOW-UP SUGGESTIONS ──────────────────────
  Future<List<String>> getFollowUpSuggestions(
      String videoTitle, List<String> mainTopics) async {
    try {
      final prompt = '''
A user just watched a YouTube video titled "$videoTitle"
covering these topics: ${mainTopics.join(', ')}.

Suggest 5 follow-up learning paths or related concepts.
Return JSON array of strings only:
["suggestion 1", "suggestion 2", ...]
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  // ── 7. TRANSLATION & SIMPLIFICATION ─────────────────────
  Future<String?> simplifyOrTranslate(
      String transcript,
      String videoTitle,
      String targetLanguage,
      bool simplify) async {
    try {
      final instruction = simplify
          ? 'Explain this video in very simple terms for a beginner.'
          : 'Summarize and translate this video content to $targetLanguage.';
      
      final prompt = '''
Video: "$videoTitle"
Transcript: ${transcript.substring(0, transcript.length.clamp(0, 3000))}

$instruction
Be clear and concise.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      return null;
    }
  }
}

// ── DATA MODELS ──────────────────────────────────────────

class VideoSummary {
  final String thirtySeconds;
  final String twoMinutes;
  final String detailed;
  const VideoSummary({
    required this.thirtySeconds,
    required this.twoMinutes,
    required this.detailed,
  });
}

class KeyPointsResult {
  final List<String> keyPoints;
  final List<String> actionItems;
  final List<String> tips;
  final List<String> mainTopics;
  const KeyPointsResult({
    required this.keyPoints,
    required this.actionItems,
    required this.tips,
    required this.mainTopics,
  });
}

class SmartTimestamp {
  final int timeSeconds;
  final String label;
  final String description;
  const SmartTimestamp({
    required this.timeSeconds,
    required this.label,
    required this.description,
  });
}

class LearningContent {
  final List<String> structuredNotes;
  final List<Flashcard> flashcards;
  final List<String> revisionPoints;
  final String difficulty;
  final String estimatedReadTime;
  const LearningContent({
    required this.structuredNotes,
    required this.flashcards,
    required this.revisionPoints,
    required this.difficulty,
    required this.estimatedReadTime,
  });
}

class Flashcard {
  final String question;
  final String answer;
  const Flashcard({required this.question, required this.answer});
}

final aiAnalysisServiceProvider = Provider<AiAnalysisService>(
  (ref) => AiAnalysisService(),
);
