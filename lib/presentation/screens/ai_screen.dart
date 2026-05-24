import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

// ── Model ──
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

// ── State ──
class AiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool hasApiKey;
  final String? error;

  const AiState({
    this.messages = const [],
    this.isLoading = false,
    this.hasApiKey = false,
    this.error,
  });

  AiState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? hasApiKey,
    String? error,
  }) =>
      AiState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        hasApiKey: hasApiKey ?? this.hasApiKey,
        error: error,
      );
}

// ── Notifier ──
class AiNotifier extends StateNotifier<AiState> {
  AiNotifier() : super(const AiState()) {
    _loadApiKey();
  }

  static const _keyPref = 'gemini_api_key';
  String? _apiKey;
  ChatSession? _session;

  static const _systemPrompt = '''You are SIGMA — an elite emergency AI assistant embedded in an SOS Panic Button app designed for mountain and outdoor use.

Your specialties:
- Wilderness survival tactics (food, water, fire, shelter)
- Mountain & jungle navigation (compass, stars, terrain reading)
- Emergency first aid (hypothermia, altitude sickness, fractures, bleeding)
- Emergency signaling (whistle codes, mirror flashing, Morse SOS)
- Weather pattern reading and danger forecasting
- Local disaster response (earthquake, landslide, flash flood)

Tone: Calm, direct, military-style. Short answers. Prioritize life-saving info first.
Format: Use bullet points. Bold key actions. Keep it actionable.
Language: Respond in the same language as the user.
IMPORTANT: If asked something unrelated to emergencies/outdoors, politely redirect to your mission.''';

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyPref);
    if (key != null && key.isNotEmpty) {
      _apiKey = key;
      _initSession();
      state = state.copyWith(hasApiKey: true);
    }
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPref, key.trim());
    _apiKey = key.trim();
    _initSession();
    state = state.copyWith(hasApiKey: true, error: null);
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPref);
    _apiKey = null;
    _session = null;
    state = AiState();
  }

  void _initSession() {
    if (_apiKey == null) return;
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );
      _session = model.startChat();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize AI: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _session == null) return;

    final userMsg = ChatMessage(text: text.trim(), isUser: true, time: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _session!.sendMessage(Content.text(text.trim()));
      final reply = response.text ?? 'No response from SIGMA.';
      final aiMsg = ChatMessage(text: reply, isUser: false, time: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: ${e.toString().replaceAll('GenerativeAIException:', '').trim()}',
      );
    }
  }

  void clearChat() {
    _initSession(); // fresh session
    state = state.copyWith(messages: [], error: null);
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>(
  (ref) => AiNotifier(),
);

// ── Quick Prompts ──
const _quickPrompts = [
  ('🔥', 'Fire', 'How do I start a fire without a lighter in wet conditions?'),
  ('💧', 'Water', 'How do I find safe drinking water in the wilderness?'),
  ('🩹', 'First Aid', 'How do I treat a sprained ankle on a hike?'),
  ('🧭', 'Navigate', 'How do I navigate without a compass or GPS?'),
  ('🌡️', 'Hypothermia', 'What are the signs and treatment for hypothermia?'),
  ('📡', 'Signal SOS', 'What is the best way to signal for rescue?'),
];

// ── Screen ──
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showApiKeyInput = false;
  final _apiKeyCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    ref.read(aiProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);

    // Auto scroll on new messages
    if (state.messages.isNotEmpty) _scrollToBottom();

    return Column(
      children: [
        // ── Header ──
        _buildHeader(state),

        if (!state.hasApiKey || _showApiKeyInput) ...[
          _buildApiKeyPanel(),
        ] else ...[
          // ── Quick prompts (only when no messages) ──
          if (state.messages.isEmpty) _buildQuickPrompts(),

          // ── Chat area ──
          Expanded(child: _buildChatArea(state)),

          // ── Error bar ──
          if (state.error != null) _buildErrorBar(state.error!),

          // ── Input bar ──
          _buildInputBar(state),
        ],
      ],
    );
  }

  Widget _buildHeader(AiState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Sigma logo
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B00FF), Color(0xFFCC00FF)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Σ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SIGMA AI', style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2)),
              Text(
                state.hasApiKey ? '● ONLINE · Gemini 2.0 Flash' : '○ API KEY REQUIRED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                  color: state.hasApiKey ? AppColors.green : AppColors.yellow,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (state.hasApiKey) ...[
            if (state.messages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textDim, size: 20),
                tooltip: 'Clear chat',
                onPressed: () => ref.read(aiProvider.notifier).clearChat(),
              ),
            IconButton(
              icon: Icon(
                _showApiKeyInput ? Icons.close : Icons.key_outlined,
                color: AppColors.textDim,
                size: 20,
              ),
              tooltip: 'API Key settings',
              onPressed: () => setState(() => _showApiKeyInput = !_showApiKeyInput),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiKeyPanel() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B00FF), Color(0xFFCC00FF)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('Σ', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('SIGMA AI ASSISTANT', style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text(
              'Emergency survival AI powered by Gemini.\nEnter your Google AI Studio API key to activate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textDim, height: 1.6),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'AIza...',
                hintStyle: const TextStyle(fontFamily: 'monospace', color: AppColors.textDim),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF8B00FF)),
                ),
                prefixIcon: const Icon(Icons.key_outlined, color: AppColors.textDim, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B00FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (_apiKeyCtrl.text.trim().isNotEmpty) {
                    ref.read(aiProvider.notifier).saveApiKey(_apiKeyCtrl.text);
                    _apiKeyCtrl.clear();
                    setState(() => _showApiKeyInput = false);
                  }
                },
                child: const Text('ACTIVATE SIGMA', style: TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Get free API key at aistudio.google.com →',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B00FF), letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QUICK COMMANDS', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textDim, letterSpacing: 2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((p) => GestureDetector(
              onTap: () => ref.read(aiProvider.notifier).sendMessage(p.$3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B00FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B00FF).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.$1, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(p.$2, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFCC88FF))),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildChatArea(AiState state) {
    if (state.messages.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Σ', style: TextStyle(fontSize: 60, color: Color(0xFF3D0060))),
            const SizedBox(height: 8),
            const Text('SIGMA is ready', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textDim)),
            const Text('Ask me anything about survival & emergencies',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textDim)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == state.messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(state.messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B00FF), Color(0xFFCC00FF)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(child: Text('Σ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard', style: TextStyle(fontFamily: 'monospace')),
                    backgroundColor: AppColors.surface,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF1A0033)
                      : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isUser
                        ? const Color(0xFF8B00FF).withOpacity(0.4)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUser ? const Color(0xFFEECCFF) : AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B00FF), Color(0xFFCC00FF)]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(child: Text('Σ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotPulse(delay: 0),
                SizedBox(width: 4),
                _DotPulse(delay: 150),
                SizedBox(width: 4),
                _DotPulse(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⚠', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AiState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !state.isLoading,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask SIGMA about survival...',
                hintStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textDim),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: state.isLoading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: state.isLoading
                    ? null
                    : const LinearGradient(colors: [Color(0xFF8B00FF), Color(0xFFCC00FF)]),
                color: state.isLoading ? AppColors.border : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: state.isLoading
                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated typing dots ──
class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.delay / 600, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF8B00FF),
            shape: BoxShape.circle,
          ),
        ),
      );
}
