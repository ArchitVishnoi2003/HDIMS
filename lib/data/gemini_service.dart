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

  /// Generates a personalized routine/exercise/diet plan based on patient health data.
  /// Returns raw JSON string with keys: daily, exercise, diet.
  Future<String> generatePersonalizedPlan({
    required Map<String, dynamic> healthContext,
  }) async {
    if (_model == null) initialize();

    final context = StringBuffer();
    // Profile
    final profile = healthContext['profile'] as Map<String, dynamic>? ?? {};
    if (profile.isNotEmpty) {
      context.writeln('Patient Profile:');
      for (final e in profile.entries) {
        if (e.value != null && e.value.toString().isNotEmpty) {
          context.writeln('- ${e.key}: ${e.value}');
        }
      }
    }
    // Allergies
    final allergies = healthContext['allergies'] as List? ?? [];
    if (allergies.isNotEmpty) {
      context.writeln('\nAllergies:');
      for (final a in allergies) {
        context.writeln('- ${a['allergen'] ?? a}${a['severity'] != null ? ' (Severity: ${a['severity']})' : ''}');
      }
    }
    // Medications
    final medications = healthContext['medications'] as List? ?? [];
    if (medications.isNotEmpty) {
      context.writeln('\nCurrent Medications:');
      for (final m in medications) {
        context.writeln('- ${m['name'] ?? m} ${m['dosage'] != null ? '(${m['dosage']})' : ''}');
      }
    }
    // Chronic conditions
    final chronic = healthContext['chronicConditions'] as List? ?? [];
    if (chronic.isNotEmpty) {
      context.writeln('\nChronic Conditions:');
      for (final c in chronic) {
        context.writeln('- $c');
      }
    }
    // Medical history
    final history = healthContext['medicalHistory'] as String? ?? '';
    if (history.isNotEmpty) {
      context.writeln('\nMedical History: $history');
    }
    // Preferences
    final prefs = healthContext['preferences'] as Map<String, dynamic>? ?? {};
    if (prefs.isNotEmpty) {
      context.writeln('\nPatient Preferences:');
      for (final e in prefs.entries) {
        if (e.value != null && e.value.toString().isNotEmpty) {
          context.writeln('- ${e.key}: ${e.value}');
        }
      }
    }

    final prompt = '''
You are a healthcare wellness assistant. Based on the patient data below, generate a personalized daily routine, exercise plan, and diet plan.

$context

IMPORTANT: Respond ONLY with valid JSON (no markdown, no code fences). Use this exact structure:
{
  "daily": [
    {"time": "07:00 AM", "activity": "Wake up and hydrate"}
  ],
  "exercise": [
    {"name": "Walking", "duration": "30 minutes", "frequency": "Daily", "benefits": "Cardiovascular health", "instructions": "Brisk walk at moderate pace"}
  ],
  "diet": [
    {"meal": "Breakfast", "time": "8:00 AM", "food": "Oatmeal with fruits", "notes": "High fiber, low sugar"}
  ]
}

Rules:
- Generate 6-8 daily activities covering the full day
- Generate 4-6 exercises appropriate for the patient's age, weight, and conditions
- Generate 4-5 meals (breakfast, mid-morning snack, lunch, evening snack, dinner)
- AVOID any foods the patient is allergic to
- Strictly follow the patient's diet preference (no meat/fish for Vegetarian/Vegan, etc.)
- Match exercise intensity to the patient's fitness level and strength training comfort
- Incorporate the patient's specific goals into the plan
- Consider medication schedules and chronic conditions
- Keep exercise intensity appropriate for the patient's health status
- If patient has chronic conditions, tailor recommendations accordingly
- Return ONLY the JSON object, nothing else
''';

    final content = [Content.text(prompt)];
    try {
      final response = await _model!.generateContent(content);
      return response.text?.trim() ?? '{}';
    } on GenerativeAIException catch (_) {
      final effectiveKey =
          (Secrets.geminiApiKey.isNotEmpty) ? Secrets.geminiApiKey : _apiKey;
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
          _model =
              GenerativeModel(model: modelName, apiKey: effectiveKey);
          final response = await _model!.generateContent(content);
          return response.text?.trim() ?? '{}';
        } on GenerativeAIException {
          // try next
        }
      }
      return '{}';
    }
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


