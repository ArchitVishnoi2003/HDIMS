import 'package:flutter/material.dart';
import 'package:flutterapp/data/gemini_service.dart';

class AskAIPage extends StatefulWidget {
  const AskAIPage({super.key});

  @override
  State<AskAIPage> createState() => _AskAIPageState();
}

class _AskAIPageState extends State<AskAIPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatItem> _history = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _history.add(_ChatItem(role: _Role.user, text: text));
      _controller.clear();
    });

    try {
      final gemini = GeminiService();
      final reply = await gemini.askDietPlan(prompt: text);
      setState(() {
        _history.add(_ChatItem(role: _Role.assistant, text: reply));
      });
    } catch (e) {
      setState(() {
        _history.add(_ChatItem(role: _Role.assistant, text: 'Error: $e'));
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFEFF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Suggestions
            if (_history.isEmpty) Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _suggestionChip('Create a 7‑day vegetarian meal plan'),
                  _suggestionChip('Low‑sodium breakfast ideas'),
                  _suggestionChip('Protein-rich snacks after workout'),
                  _suggestionChip('Diabetic-friendly dinner options'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_loading && index == _history.length) {
                    return _typingBubble();
                  }
                  final item = _history[index];
                  final isUser = item.role == _Role.user;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser)
                        _avatar(Icons.health_and_safety, const Color(0xFF6C5CE7)),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF6C5CE7) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            item.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (isUser)
                        _avatar(Icons.person, const Color(0xFF6C5CE7)),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything about diet, fitness or health…',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _send(),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6C5CE7),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : IconButton(
                              onPressed: _send,
                              icon: const Icon(Icons.send, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _controller.text = text;
        _send();
      },
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _avatar(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _typingBubble() {
    return Row(
      children: [
        _avatar(Icons.health_and_safety, const Color(0xFF6C5CE7)),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text('Thinking…'),
        ),
      ],
    );
  }
}

enum _Role { user, assistant }

class _ChatItem {
  final _Role role;
  final String text;
  _ChatItem({required this.role, required this.text});
}


