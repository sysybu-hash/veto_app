// ============================================================
//  ChatScreen.dart — Citizen ↔ Lawyer messaging
//  VETO Legal Emergency App
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

// ── i18n ──────────────────────────────────────────────────────
const _i18n = {
  'he': {
    'title': 'שיחות',
    'newChat': 'שיחה חדשה',
    'noConversations': 'אין שיחות עדיין',
    'typeMessage': 'הקלד הודעה...',
    'send': 'שלח',
    'today': 'היום',
    'yesterday': 'אתמול',
    'loadingMore': 'טוען...',
    'deleteMsg': 'מחק הודעה',
    'you': 'אתה',
    'selectPartner': 'בחר שותף לשיחה',
    'noPartners': 'אין גורמים זמינים לשיחה',
    'back': 'חזור',
    'unread': 'הודעות שלא נקראו',
  },
  'en': {
    'title': 'Conversations',
    'newChat': 'New Chat',
    'noConversations': 'No conversations yet',
    'typeMessage': 'Type a message...',
    'send': 'Send',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'loadingMore': 'Loading...',
    'deleteMsg': 'Delete message',
    'you': 'You',
    'selectPartner': 'Select a partner to chat with',
    'noPartners': 'No available partners',
    'back': 'Back',
    'unread': 'Unread messages',
  },
  'ru': {
    'title': 'Беседы',
    'newChat': 'Новый чат',
    'noConversations': 'Нет разговоров',
    'typeMessage': 'Введите сообщение...',
    'send': 'Отправить',
    'today': 'Сегодня',
    'yesterday': 'Вчера',
    'loadingMore': 'Загрузка...',
    'deleteMsg': 'Удалить сообщение',
    'you': 'Вы',
    'selectPartner': 'Выберите собеседника',
    'noPartners': 'Нет доступных собеседников',
    'back': 'Назад',
    'unread': 'Непрочитанные',
  },
};

// ── Data models ───────────────────────────────────────────────
class _Conversation {
  final String partnerId, partnerName, partnerRole;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unreadCount;

  const _Conversation({
    required this.partnerId, required this.partnerName,
    required this.partnerRole, this.lastMessage,
    this.lastAt, required this.unreadCount,
  });

  factory _Conversation.fromJson(Map<String, dynamic> j) => _Conversation(
    partnerId: j['partnerId'] ?? j['partner_id'] ?? '',
    partnerName: j['partnerName'] ?? j['partner_name'] ?? '',
    partnerRole: j['partnerRole'] ?? j['partner_role'] ?? '',
    lastMessage: j['lastMessage'] as String?,
    lastAt: j['lastAt'] != null ? DateTime.tryParse(j['lastAt'] as String) : null,
    unreadCount: (j['unreadCount'] ?? j['unread_count'] ?? 0) as int,
  );
}

class _Message {
  final String id, senderId, senderRole, text;
  final DateTime createdAt;
  final bool isOwn;

  const _Message({
    required this.id, required this.senderId, required this.senderRole,
    required this.text, required this.createdAt, required this.isOwn,
  });

  factory _Message.fromJson(Map<String, dynamic> j, String myId) {
    final sid = j['sender_id'] ?? j['senderId'] ?? '';
    return _Message(
      id: j['_id'] ?? j['id'] ?? '',
      senderId: sid as String,
      senderRole: j['sender_role'] ?? j['senderRole'] ?? '',
      text: j['text'] ?? '',
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      isOwn: sid == myId,
    );
  }
}

class _Partner {
  final String id, name, role;
  const _Partner({required this.id, required this.name, required this.role});

  factory _Partner.fromJson(Map<String, dynamic> j) => _Partner(
    id: j['_id'] ?? j['id'] ?? '',
    name: j['full_name'] ?? j['name'] ?? '',
    role: j['role'] ?? '',
  );
}

// ── Screen ────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  /// Optional: jump directly into a thread with this partner ID
  final String? initialPartnerId;
  final String? initialPartnerName;

  const ChatScreen({super.key, this.initialPartnerId, this.initialPartnerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _auth = AuthService();

  List<_Conversation> _conversations = [];
  bool _loadingConvs = true;

  // Active thread
  String? _activePartnerId;
  String? _activePartnerName;
  List<_Message> _messages = [];
  bool _loadingMsgs = false;
  bool _sending = false;
  int _page = 1;
  bool _hasMore = true;

  String _myId = '';
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  String _t(String key) {
    final code = context.read<AppLanguageController>().code;
    return _i18n[code]?[key] ?? _i18n['en']![key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _initMyId();
    _loadConversations();
    _scrollCtrl.addListener(_onScroll);
    _listenToSocket();
    if (widget.initialPartnerId != null) {
      _activePartnerId = widget.initialPartnerId;
      _activePartnerName = widget.initialPartnerName ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages(reset: true));
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initMyId() async {
    final token = await _auth.getToken();
    if (token == null) return;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;
      final payload = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)))
          as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _myId = (decoded['userId'] ?? decoded['id'] ?? decoded['sub'] ?? '') as String);
    } catch (_) {}
  }

  void _listenToSocket() {
    // Refresh conversations and active thread every 30s as a fallback
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadConversations(silent: true);
      if (mounted && _activePartnerId != null) _loadMessages(reset: true, silent: true);
    });
  }

  Future<String?> get _token async => _auth.getToken();

  // ── Load conversations ────────────────────────────────────────
  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _loadingConvs = true);
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/chat/conversations'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['conversations'] ?? data['data'] ?? []);
        setState(() => _conversations = (list as List)
            .map((e) => _Conversation.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (_) {}
    if (mounted && !silent) setState(() => _loadingConvs = false);
  }

  // ── Load messages ──────────────────────────────────────────────
  Future<void> _loadMessages({bool reset = false, bool silent = false}) async {
    if (_activePartnerId == null) return;
    if (!silent) setState(() => _loadingMsgs = true);
    if (reset) { _page = 1; _hasMore = true; }

    try {
      final tok = await _token;
      if (tok == null) return;
      final uri = Uri.parse(
          '${AppConfig.baseUrl}/chat/messages/$_activePartnerId?page=$_page');
      final res = await http.get(
        uri,
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['messages'] ?? []);
        final parsed = (list as List)
            .map((e) => _Message.fromJson(e as Map<String, dynamic>, _myId))
            .toList();
        setState(() {
          if (reset) {
            _messages = parsed;
          } else {
            _messages = [..._messages, ...parsed];
          }
          _hasMore = parsed.length >= 50;
        });
        if (reset) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } catch (_) {}
    if (mounted && !silent) setState(() => _loadingMsgs = false);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 60 && _hasMore && !_loadingMsgs) {
      _page++;
      _loadMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent > 0) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Send message ───────────────────────────────────────────────
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _activePartnerId == null) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/chat/messages'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'receiver_id': _activePartnerId, 'text': text}),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final msg = body['message'] ?? body;
        if (msg is Map) {
          setState(() => _messages.add(
              _Message.fromJson(msg as Map<String, dynamic>, _myId)));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        _loadConversations(silent: true);
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  // ── Delete message ─────────────────────────────────────────────
  Future<void> _deleteMessage(_Message msg) async {
    if (!msg.isOwn) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/chat/messages/${msg.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() => _messages.removeWhere((m) => m.id == msg.id));
      }
    } catch (_) {}
  }

  // ── New chat partner picker ────────────────────────────────────
  Future<void> _showNewChatPicker() async {
    List<_Partner> partners = [];
    bool loading = true;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: VetoPalette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loading) {
            _loadPartners().then((list) {
              if (ctx.mounted) setS(() { partners = list; loading = false; });
            });
          }
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            maxChildSize: 0.85,
            minChildSize: 0.3,
            expand: false,
            builder: (_, sc) => Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: VetoPalette.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(_t('newChat'),
                    style: const TextStyle(color: VetoPalette.text,
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : partners.isEmpty
                        ? Center(child: Text(_t('noPartners'),
                            style: const TextStyle(color: VetoPalette.textMuted)))
                        : ListView.builder(
                            controller: sc,
                            itemCount: partners.length,
                            itemBuilder: (_, i) {
                              final p = partners[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      VetoPalette.primary.withValues(alpha: 0.15),
                                  child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          color: VetoPalette.primary,
                                          fontWeight: FontWeight.w700)),
                                ),
                                title: Text(p.name,
                                    style: const TextStyle(color: VetoPalette.text)),
                                subtitle: Text(p.role,
                                    style: const TextStyle(
                                        color: VetoPalette.textMuted, fontSize: 12)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _activePartnerId = p.id;
                                    _activePartnerName = p.name;
                                    _messages = [];
                                  });
                                  _loadMessages(reset: true);
                                },
                              );
                            },
                          ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<List<_Partner>> _loadPartners() async {
    try {
      final tok = await _token;
      if (tok == null) return [];
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/chat/partners'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['partners'] ?? []);
        return (list as List)
            .map((e) => _Partner.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: LayoutBuilder(builder: (_, constraints) {
          final isWide = constraints.maxWidth > 720;
          if (isWide) {
            return Row(children: [
              SizedBox(width: 320, child: _buildConversationList()),
              const VerticalDivider(width: 1, color: VetoPalette.border),
              Expanded(child: _activePartnerId == null
                  ? _buildEmptyThread()
                  : _buildThread()),
            ]);
          }
          // Narrow: show thread if active, else show list
          if (_activePartnerId != null) {
            return _buildThread(showBackButton: true);
          }
          return _buildConversationList(showAppBar: true);
        }),
      ),
    );
  }

  // ── Conversation list panel ────────────────────────────────────
  Widget _buildConversationList({bool showAppBar = false}) {
    return Scaffold(
      backgroundColor: VetoPalette.bg,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: VetoPalette.darkBg,
              title: Text(_t('title'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _showNewChatPicker,
                  tooltip: _t('newChat'),
                ),
              ],
            )
          : AppBar(
              backgroundColor: VetoPalette.darkBg,
              title: Text(_t('title'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: BackButton(color: Colors.white,
                  onPressed: () => Navigator.of(context).pop()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _showNewChatPicker,
                  tooltip: _t('newChat'),
                ),
              ],
            ),
      body: _loadingConvs
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: VetoPalette.textSubtle.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(_t('noConversations'),
                        style: const TextStyle(
                            color: VetoPalette.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _showNewChatPicker,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_t('newChat')),
                      style: FilledButton.styleFrom(
                          backgroundColor: VetoPalette.primary),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: VetoPalette.border),
                    itemBuilder: (_, i) => _buildConvTile(_conversations[i]),
                  ),
                ),
    );
  }

  Widget _buildConvTile(_Conversation c) {
    final isActive = c.partnerId == _activePartnerId;
    final initial = c.partnerName.isNotEmpty ? c.partnerName[0].toUpperCase() : '?';
    final ts = c.lastAt != null ? _formatTs(c.lastAt!) : '';

    return ListTile(
      selected: isActive,
      selectedTileColor: VetoPalette.primary.withValues(alpha: 0.08),
      tileColor: Colors.transparent,
      leading: CircleAvatar(
        backgroundColor: VetoPalette.primary.withValues(alpha: 0.15),
        child: Text(initial,
            style: const TextStyle(
                color: VetoPalette.primary, fontWeight: FontWeight.w700)),
      ),
      title: Row(children: [
        Expanded(
          child: Text(c.partnerName,
              style: const TextStyle(
                  color: VetoPalette.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Text(ts, style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
      ]),
      subtitle: c.lastMessage != null
          ? Text(c.lastMessage!,
              style: TextStyle(
                  color: c.unreadCount > 0
                      ? VetoPalette.text
                      : VetoPalette.textMuted,
                  fontSize: 13,
                  fontWeight: c.unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
          : null,
      trailing: c.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: VetoPalette.primary,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${c.unreadCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            )
          : null,
      onTap: () {
        setState(() {
          _activePartnerId = c.partnerId;
          _activePartnerName = c.partnerName;
          _messages = [];
        });
        _loadMessages(reset: true);
      },
    );
  }

  // ── Empty thread placeholder ───────────────────────────────────
  Widget _buildEmptyThread() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forum_outlined,
              size: 64,
              color: VetoPalette.textSubtle.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(_t('selectPartner'),
              style: const TextStyle(
                  color: VetoPalette.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showNewChatPicker,
            icon: const Icon(Icons.add_rounded),
            label: Text(_t('newChat')),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
          ),
        ]),
      );

  // ── Message thread panel ───────────────────────────────────────
  Widget _buildThread({bool showBackButton = false}) {
    return Scaffold(
      backgroundColor: VetoPalette.bg,
      appBar: AppBar(
        backgroundColor: VetoPalette.darkBg,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => setState(() {
                  _activePartnerId = null;
                  _activePartnerName = null;
                }),
              )
            : null,
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: VetoPalette.primary.withValues(alpha: 0.2),
            child: Text(
              (_activePartnerName?.isNotEmpty == true)
                  ? _activePartnerName![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: VetoPalette.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_activePartnerName ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _loadMessages(reset: true),
          ),
        ],
      ),
      body: Column(children: [
        // Loading more indicator
        if (_loadingMsgs && _messages.isNotEmpty)
          const LinearProgressIndicator(
              color: VetoPalette.primary, minHeight: 2),
        // Messages list
        Expanded(
          child: _loadingMsgs && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final showDate = i == 0 ||
                        !_sameDay(_messages[i - 1].createdAt, msg.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _buildDateSeparator(msg.createdAt),
                        _buildMessageBubble(msg),
                      ],
                    );
                  },
                ),
        ),
        // Input bar
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (_sameDay(dt, now)) {
      label = _t('today');
    } else if (_sameDay(dt, now.subtract(const Duration(days: 1)))) {
      label = _t('yesterday');
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: VetoPalette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: const TextStyle(
                  color: VetoPalette.textSubtle, fontSize: 11)),
        ),
        const Expanded(child: Divider(color: VetoPalette.border)),
      ]),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final time =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: msg.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: msg.isOwn
            ? () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: VetoPalette.surface,
                    title: Text(_t('deleteMsg'),
                        style: const TextStyle(color: VetoPalette.text)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel',
                            style: TextStyle(color: VetoPalette.textMuted)),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteMessage(msg);
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: VetoPalette.emergency),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                )
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: msg.isOwn
                ? VetoPalette.primary
                : VetoPalette.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(msg.isOwn ? 16 : 4),
              bottomRight: Radius.circular(msg.isOwn ? 4 : 16),
            ),
            border: msg.isOwn
                ? null
                : Border.all(color: VetoPalette.border),
          ),
          child: Column(
            crossAxisAlignment: msg.isOwn
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(msg.text,
                  style: TextStyle(
                      color: msg.isOwn ? Colors.white : VetoPalette.text,
                      fontSize: 14,
                      height: 1.45)),
              const SizedBox(height: 3),
              Text(time,
                  style: TextStyle(
                      color: msg.isOwn
                          ? Colors.white.withValues(alpha: 0.65)
                          : VetoPalette.textSubtle,
                      fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: VetoPalette.darkBg,
        border: Border(top: BorderSide(color: VetoPalette.border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            style: const TextStyle(color: VetoPalette.text, fontSize: 14),
            maxLines: 4,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _t('typeMessage'),
              hintStyle: const TextStyle(color: VetoPalette.textMuted),
              filled: true,
              fillColor: VetoPalette.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FilledButton(
            onPressed: _sending ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: VetoPalette.primary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              minimumSize: const Size(48, 48),
            ),
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTs(DateTime dt) {
    final now = DateTime.now();
    if (_sameDay(dt, now)) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) {
      return _t('yesterday');
    }
    return '${dt.day}/${dt.month}';
  }
}
