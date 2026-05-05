// ============================================================
//  Legal notebook editor — markdown, sources, Gemini chat
//  (VETO local notebook; open-in-browser remains for NotebookLM URL)
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/theme/veto_2026.dart';
import '../services/auth_service.dart';
import '../services/legal_notebook_api_service.dart';

class LegalNotebookEditorScreen extends StatefulWidget {
  const LegalNotebookEditorScreen({super.key, required this.notebookId});

  final String notebookId;

  @override
  State<LegalNotebookEditorScreen> createState() => _LegalNotebookEditorScreenState();
}

class _LegalNotebookEditorScreenState extends State<LegalNotebookEditorScreen>
    with SingleTickerProviderStateMixin {
  final _api = LegalNotebookApiService();
  final _auth = AuthService();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _chatCtrl = TextEditingController();
  late TabController _tabs;

  bool _loading = true;
  Map<String, dynamic>? _row;
  List<Map<String, dynamic>> _vaultFiles = const [];
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _tabs.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVaultFiles() async {
    try {
      final t = await _auth.getToken();
      if (t == null) return;
      final r = await http.get(
        Uri.parse('${AppConfig.baseUrl}/vault/files'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
      );
      if (r.statusCode != 200 || !mounted) return;
      final data = jsonDecode(r.body);
      final list = data is List ? data : (data['files'] ?? []);
      final out = <Map<String, dynamic>>[];
      for (final e in list as List) {
        final m = e as Map<String, dynamic>;
        out.add(m);
      }
      setState(() => _vaultFiles = out);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final row = await _api.getOne(widget.notebookId);
    if (!mounted) return;
    if (row == null) {
      setState(() {
        _row = null;
        _loading = false;
      });
      return;
    }
    _titleCtrl.text = '${row['name'] ?? ''}';
    _contentCtrl.text = '${row['content'] ?? ''}';
    setState(() {
      _row = row;
      _loading = false;
    });
    await _loadVaultFiles();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 900), () async {
      final id = widget.notebookId;
      final patched = await _api.patch(
        id,
        name: _titleCtrl.text.trim(),
        content: _contentCtrl.text,
      );
      if (patched != null && mounted) {
        setState(() => _row = patched);
      }
    });
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    setState(() {
      final cm = List<Map<String, dynamic>>.from(
        (_row?['chatMessages'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      cm.add({'role': 'user', 'text': text, 'at': DateTime.now().toIso8601String()});
      if (_row != null) _row = {..._row!, 'chatMessages': cm};
    });
    final res = await _api.chat(widget.notebookId, text);
    if (!mounted) return;
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat failed')),
      );
      await _load();
      return;
    }
    final nb = res['notebook'] as Map<String, dynamic>?;
    if (nb != null) {
      setState(() => _row = nb);
    }
  }

  Future<void> _addSource() async {
    var kind = 'text';
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    String? fileId = _vaultFiles.isEmpty
        ? null
        : '${_vaultFiles.first['_id'] ?? _vaultFiles.first['id']}';
    if (!mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: V26.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setS) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'הוספת מקור',
                      style: TextStyle(
                        fontFamily: V26.serif,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: V26.ink900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'text', label: Text('טקסט')),
                        ButtonSegment(value: 'url', label: Text('קישור')),
                        ButtonSegment(value: 'vault', label: Text('כספת')),
                      ],
                      selected: {kind},
                      onSelectionChanged: (s) => setS(() => kind = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'כותרת (אופציונלי)'),
                    ),
                    if (kind == 'text')
                      TextField(
                        controller: textCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'תוכן'),
                      ),
                    if (kind == 'url')
                      TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(labelText: 'URL'),
                      ),
                    if (kind == 'vault')
                      _vaultFiles.isEmpty
                          ? const Text('אין קבצים בכספת', style: TextStyle(color: V26.ink500))
                          : DropdownMenu<String>(
                              initialSelection: fileId,
                              label: const Text('קובץ'),
                              dropdownMenuEntries: [
                                for (final f in _vaultFiles)
                                  DropdownMenuEntry(
                                    value: '${f['_id'] ?? f['id']}',
                                    label: '${f['name']}',
                                  ),
                              ],
                              onSelected: (v) => setS(() => fileId = v),
                            ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('הוספה'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (ok == true) {
      Map<String, dynamic>? updated;
      if (kind == 'text') {
        updated = await _api.addSource(
          widget.notebookId,
          kind: 'text',
          title: titleCtrl.text.trim(),
          text: textCtrl.text,
        );
      } else if (kind == 'url') {
        updated = await _api.addSource(
          widget.notebookId,
          kind: 'url',
          title: titleCtrl.text.trim(),
          url: urlCtrl.text.trim(),
        );
      } else if (kind == 'vault' && fileId != null) {
        updated = await _api.addSource(
          widget.notebookId,
          kind: 'vault',
          title: titleCtrl.text.trim(),
          vaultFileId: fileId,
        );
      }
      titleCtrl.dispose();
      urlCtrl.dispose();
      textCtrl.dispose();
      if (updated != null && mounted) setState(() => _row = updated);
    } else {
      titleCtrl.dispose();
      urlCtrl.dispose();
      textCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: V26.navy600)),
      );
    }
    if (_row == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('מחברת')),
        body: const Center(child: Text('לא נמצא')),
      );
    }

    final sources = (_row!['sources'] as List<dynamic>?) ?? [];
    final chat = (_row!['chatMessages'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: V26.paper,
      appBar: AppBar(
        backgroundColor: V26.surface,
        foregroundColor: V26.ink900,
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(
            fontFamily: V26.serif,
            fontWeight: FontWeight.w700,
            color: V26.ink900,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'שם מחברת',
          ),
          onChanged: (_) => _scheduleSave(),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: V26.navy600,
          tabs: const [
            Tab(text: 'עורך'),
            Tab(text: 'מקורות'),
            Tab(text: 'צ׳אט'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'רענון',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: V26.ink900,
                height: 1.45,
              ),
              decoration: const InputDecoration(
                hintText: '# Markdown\n\nכתבו הערות…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => _scheduleSave(),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _addSource,
                  icon: const Icon(Icons.add),
                  label: const Text('מקור חדש'),
                  style: FilledButton.styleFrom(backgroundColor: V26.navy600),
                ),
              ),
              const SizedBox(height: 12),
              if (sources.isEmpty)
                const Text('אין מקורות', style: TextStyle(color: V26.ink500))
              else
                ...sources.map((s) {
                  final m = s as Map<String, dynamic>;
                  final sid = '${m['_id']}';
                  final k = m['kind'];
                  return Card(
                    child: ListTile(
                      title: Text('${m['title'] ?? k}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$k · $sid', style: const TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: V26.emerg),
                        onPressed: () async {
                          final u = await _api.removeSource(widget.notebookId, sid);
                          if (u != null && mounted) setState(() => _row = u);
                        },
                      ),
                    ),
                  );
                }),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Text(
                      'סטטוס: ${_row!['status'] ?? '—'}',
                      style: const TextStyle(color: V26.ink500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: chat.length,
                  itemBuilder: (ctx, i) {
                    final m = chat[i] as Map<String, dynamic>;
                    final user = m['role'] == 'user';
                    return Align(
                      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
                        decoration: BoxDecoration(
                          color: user ? V26.navy600.withValues(alpha: 0.12) : V26.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: V26.hairline),
                        ),
                        child: Text(
                          '${m['text'] ?? ''}',
                          style: TextStyle(color: user ? V26.ink900 : V26.ink700, height: 1.35),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.paddingOf(context).bottom + 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatCtrl,
                        decoration: const InputDecoration(
                          hintText: 'שאלה לפי המקורות…',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    IconButton(
                      onPressed: _sendChat,
                      icon: const Icon(Icons.send_rounded, color: V26.navy600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
