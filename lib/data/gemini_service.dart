import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutterapp/const/secrets.dart';

class GeminiService {
  GeminiService._internal();

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  GenerativeModel? _model;

  void initialize({String modelName = 'gemini-2.5-flash'}) {
    if (_model != null) return;
    final effectiveKey = (Secrets.geminiApiKey.isNotEmpty) ? Secrets.geminiApiKey : _apiKey;
    if (effectiveKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is not set. Pass --dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }
    _model = GenerativeModel(model: modelName, apiKey: effectiveKey);
  }

  Future<String> askDietPlan({required String prompt}) async {
    if (_model == null) {
      initialize();
    }
    final content = [
      Content.text(
        'You are a helpful healthcare assistant. Provide safe, general nutrition guidance. '
        'Avoid diagnosing. Encourage consulting professionals for personalized advice.\n\n'
        'User prompt: $prompt',
      )
    ];
    try {
      final response = await _model!.generateContent(content);
      return response.text?.trim().isNotEmpty == true
          ? response.text!.trim()
          : 'Sorry, I could not generate a response.';
    } on GenerativeAIException catch (_) {
      // Fallback sequence for model availability differences
      final effectiveKey = (Secrets.geminiApiKey.isNotEmpty) ? Secrets.geminiApiKey : _apiKey;
      final candidates = <String>[
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.5-flash-preview-05-20',
        'gemini-2.5-pro-preview-06-05',
        'gemini-flash-latest',
        'gemini-2.0-flash',
        'gemini-1.5-flash',
        'gemini-1.5-flash-8b',
        'gemini-1.5-pro',
      ];
      for (final modelName in candidates) {
        try {
          _model = GenerativeModel(model: modelName, apiKey: effectiveKey);
          final response = await _model!.generateContent(content);
          return response.text?.trim().isNotEmpty == true
              ? response.text!.trim()
              : 'Sorry, I could not generate a response.';
        } on GenerativeAIException {
          // try next
        }
      }
      return 'Model not available for this key/region. Please check key restrictions or try later.';
    }
  }
}


