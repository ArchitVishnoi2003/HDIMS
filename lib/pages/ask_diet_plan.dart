import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutterapp/data/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Storage key is per-user so different accounts on the same device stay isolated.
String _storageKey(String uid) => 'ai_chat_history_$uid';

class AskAIPage extends StatefulWidget {
  const AskAIPage({super.key});

  @override
  State<AskAIPage> createState() => _AskAIPageState();
}

class _AskAIPageState extends State<AskAIPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatItem> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(uid));
    if (raw == null || raw.isEmpty) return;
    try {
      final List decoded = jsonDecode(raw) as List;
      final items = decoded
          .map((m) => _ChatItem(
                role: m['role'] == 'user' ? _Role.user : _Role.assistant,
                text: m['text'] as String,
                timestamp: m['timestamp'] as int? ?? 0,
              ))
          .toList();
      if (mounted) {
        setState(() => _history.addAll(items));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = _history
        .map((m) => {
              'role': m.role.name,
              'text': m.text,
              'timestamp': m.timestamp,
            })
        .toList();
    await prefs.setString(_storageKey(uid), jsonEncode(data));
  }

  Future<void> _saveToFirestore(String prompt, String response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_chats')
          .add({
        'prompt': prompt,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content:
            const Text('Delete all chat history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await prefs.remove(_storageKey(uid));
      setState(() => _history.clear());
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    final userMsg = _ChatItem(
      role: _Role.user,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _loading = true;
      _history.add(userMsg);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final reply = await GeminiService().askDietPlan(prompt: text);
      final aiMsg = _ChatItem(
        role: _Role.assistant,
        text: reply,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      setState(() => _history.add(aiMsg));
      await _saveHistory();
      await _saveToFirestore(text, reply);
    } catch (e) {
      final errMsg = _ChatItem(
        role: _Role.assistant,
        text: 'Sorry, something went wrong: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      setState(() => _history.add(errMsg));
      await _saveHistory();
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Ask AI',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Clear chat',
              onPressed: _clearHistory,
            ),
        ],
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
            // Suggestion chips – shown only when chat is empty
            if (_history.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _suggestionChip('Create a 7-day vegetarian meal plan'),
                    _suggestionChip('Low-sodium breakfast ideas'),
                    _suggestionChip('Protein-rich snacks after workout'),
                    _suggestionChip('Diabetic-friendly dinner options'),
                  ],
                ),
              ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _history.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_loading && index == _history.length) {
                    return _typingBubble();
                  }
                  final item = _history[index];
                  return _messageBubble(item, item.role == _Role.user);
                },
              ),
            ),

            const Divider(height: 1),

            // Input bar
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    MediaQuery.of(context).viewInsets.bottom + 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText:
                                'Ask about diet, fitness or health…',
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
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : IconButton(
                              onPressed: _send,
                              icon: const Icon(Icons.send,
                                  color: Colors.white),
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

  // ── Chat bubble ───────────────────────────────────────────────────────────

  Widget _messageBubble(_ChatItem item, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            _avatar(Icons.health_and_safety, const Color(0xFF6C5CE7)),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6C5CE7) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      item.text,
                      style: const TextStyle(
                          color: Colors.white, height: 1.4, fontSize: 14),
                    )
                  : MarkdownBody(
                      data: item.text,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            color: Colors.black87,
                            height: 1.5,
                            fontSize: 14),
                        strong: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        em: const TextStyle(
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                            fontSize: 14),
                        h1: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        h2: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        h3: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        listBullet: const TextStyle(
                            color: Colors.black87, fontSize: 14),
                        blockquoteDecoration: BoxDecoration(
                          color:
                              const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: const Border(
                            left: BorderSide(
                                color: Color(0xFF6C5CE7), width: 4),
                          ),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser)
            _avatar(Icons.person, const Color(0xFF6C5CE7)),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _avatar(Icons.health_and_safety, const Color(0xFF6C5CE7)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'Thinking…',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
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

  Widget _suggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

enum _Role { user, assistant }

class _ChatItem {
  final _Role role;
  final String text;
  final int timestamp;

  const _ChatItem({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}
