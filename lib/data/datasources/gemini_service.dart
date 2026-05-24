import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _systemPrompt = '''
You are an emergency survival assistant named SIGMA (Mobile Emergency Information System).
Assist the user in outdoor emergency situations with guidance on:
- Basic first aid
- Navigation and orientation
- Survival techniques
- Emergency communication

RULES:
- ALWAYS answer in English
- Short, clear, and actionable (maximum 5 points)
- Prioritize human life and safety above all else
- If the situation is critical, always suggest calling emergency services (911, 112) or Search & Rescue
- Never suggest actions that worsen the condition
''';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chat;

  void init(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      safetySettings: [
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.low),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      ],
    );
    _chat = _model!.startChat();
  }

  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      return _offlineFallback(message);
    }

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'No response from AI.';
    } catch (e) {
      return _offlineFallback(message);
    }
  }

  // ── Offline fallback tips ──
  String _offlineFallback(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('hipotermia') || lower.contains('kedinginan') || lower.contains('dingin') ||
        lower.contains('hypothermia') || lower.contains('cold') || lower.contains('freezing')) {
      return '❄ HYPOTHERMIA:\n'
          '1. Move to a sheltered place out of the wind\n'
          '2. Replace wet clothing, wrap in sleeping bag/jacket\n'
          '3. Drink warm liquids (no alcohol)\n'
          '4. Move the body slowly to generate heat\n'
          '5. 🚨 Call Search & Rescue or emergency services immediately';
    }

    if (lower.contains('tersesat') || lower.contains('hilang') || lower.contains('arah') ||
        lower.contains('lost') || lower.contains('direction') || lower.contains('navigation') || lower.contains('compass')) {
      return '🧭 LOST:\n'
          '1. STOP — Stop, Think, Observe, Plan (remain calm, do not panic)\n'
          '2. Activate SOS and send GPS coordinates\n'
          '3. Stay in an open area to be easily visible\n'
          '4. Make signals: 3x fire/mirror/whistle (international emergency code)\n'
          '5. If you have a compass: look for downhill flowing water sources';
    }

    if (lower.contains('cedera') || lower.contains('jatuh') || lower.contains('kaki') || lower.contains('patah') ||
        lower.contains('injury') || lower.contains('fall') || lower.contains('leg') || lower.contains('fracture') || lower.contains('wound') || lower.contains('hurt')) {
      return '🦴 PHYSICAL INJURY:\n'
          '1. Do not move if you suspect neck or spinal injury\n'
          '2. Stop bleeding by applying firm pressure with a clean cloth\n'
          '3. Immobilize the injured limb with a stick + cloth (splint)\n'
          '4. Elevate the injured area\n'
          '5. 🚨 Activate SOS and call emergency services (911/112)';
    }

    if (lower.contains('dehidrasi') || lower.contains('air') || lower.contains('haus') ||
        lower.contains('dehydration') || lower.contains('water') || lower.contains('thirsty')) {
      return '💧 DEHYDRATION:\n'
          '1. Drink water slowly and continuously\n'
          '2. Stream/rainwater must be boiled/purified first\n'
          '3. Avoid drinking stagnant water\n'
          '4. Warning signs: no urination for >8 hours, fainting\n'
          '5. Stay in the shade, conserve energy';
    }

    if (lower.contains('gigit') || lower.contains('ular') || lower.contains('binatang') ||
        lower.contains('bite') || lower.contains('snake') || lower.contains('animal') || lower.contains('sting')) {
      return '🐍 ANIMAL BITE:\n'
          '1. Do not suck or cut the bite wound\n'
          '2. Immobilize the bitten area (keep it still)\n'
          '3. Position the wound below heart level\n'
          '4. Note the snake\'s characteristics (color, head shape) if safe to do so\n'
          '5. 🚨 Call emergency services immediately — antivenom must be given quickly';
    }

    return '⚠ OFFLINE MODE — General Emergency Tips:\n'
        '1. Prioritize safety — do not panic\n'
        '2. Activate SOS and send GPS coordinates\n'
        '3. Contact emergency services (911/112) or Search & Rescue\n'
        '4. Conserve phone battery for communication\n'
        '5. Stay in a safe, visible location\n\n'
        '🔴 For AI responses: an active internet connection is required';
  }

  void resetChat() {
    _chat = _model?.startChat();
  }
}

// Chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

// Providers
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class AiChatNotifier extends StateNotifier<List<ChatMessage>> {
  final GeminiService _service;

  AiChatNotifier(this._service) : super([
    ChatMessage(
      content: '⚕ Hello! I am SIGMA, your emergency survival assistant. Ask me about first aid, navigation, or survival tips. I work offline with cached responses when there is no connection.',
      isUser: false,
      timestamp: DateTime.now(),
    )
  ]);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    state = [...state, ChatMessage(content: message, isUser: true, timestamp: DateTime.now())];
    _isLoading = true;

    final response = await _service.sendMessage(message);
    _isLoading = false;

    state = [...state, ChatMessage(content: response, isUser: false, timestamp: DateTime.now())];
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, List<ChatMessage>>(
  (ref) => AiChatNotifier(ref.read(geminiServiceProvider)),
);
