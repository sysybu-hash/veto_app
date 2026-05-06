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
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
import '../widgets/citizen_mockup_shell.dart';

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
  late final Future<String?> _citizenChromeFuture = _auth.getStoredRole();

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
  Timer? _conversationPoll;

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
    _conversationPoll?.cancel();
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
    // Refresh conversations and active thread every 30s as a fallback (not a socket stream).
    _conversationPoll?.cancel();
    _conversationPoll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadConversations(silent: true);
      if (mounted && _activePartnerId != null) {
        _loadMessages(reset: true, silent: true);
      }
    });
  }

  Future<String?> get _token async => _auth.getToken();

  // ── Load conversations ────────────────────────────────────────
  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      if (!mounted) return;
      setState(() => _loadingConvs = true);
    }
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
    finally {
      if (mounted && !silent) setState(() => _loadingConvs = false);
    }
  }

  // ── Load messages ──────────────────────────────────────────────
  Future<void> _loadMessages({bool reset = false, bool silent = false}) async {
    if (_activePartnerId == null) return;
    if (!silent) {
      if (!mounted) return;
      setState(() => _loadingMsgs = true);
    }
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
    finally {
      if (mounted && !silent) setState(() => _loadingMsgs = false);
    }
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
    if (!mounted) return;
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
    finally {
      if (mounted) setState(() => _sending = false);
    }
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
        if (!mounted) return;
        setState(() => _messages.removeWhere((m) => m.id == msg.id));
      }
    } catch (_) {}
  }

  // ── New chat partner picker ────────────────────────────────────
  Future<void> _showNewChatPicker() async {
    List<_Partner> partners = [];
    bool loading = true;
    var partnersLoadStarted = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xE6121824),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loading && !partnersLoadStarted) {
            partnersLoadStarted = true;
            _loadPartners().then((list) {
              if (ctx.mounted) {
                setS(() {
                  partners = list;
                  loading = false;
                });
              }
            }).catchError((Object e, StackTrace st) {
              debugPrint('ChatScreen _loadPartners: $e\n$st');
              if (ctx.mounted) {
                setS(() {
                  partners = [];
                  loading = false;
                });
              }
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
                    color: V26.hairline,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(_t('newChat'),
                    style: const TextStyle(color: V26.ink900,
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : partners.isEmpty
                        ? Center(child: Text(_t('noPartners'),
                            style: const TextStyle(color: V26.ink500)))
                        : ListView.builder(
                            controller: sc,
                            itemCount: partners.length,
                            itemBuilder: (_, i) {
                              final p = partners[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      V26.navy600.withValues(alpha: 0.15),
                                  child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          color: V26.navy600,
                                          fontWeight: FontWeight.w700)),
                                ),
                                title: Text(p.name,
                                    style: const TextStyle(color: V26.ink900)),
                                subtitle: Text(p.role,
                                    style: const TextStyle(
                                        color: V26.ink500, fontSize: 12)),
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
    final isWideTop =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    final wideShellChild = Row(
      children: [
        SizedBox(width: 340, child: _buildConversationList()),
        const VerticalDivider(width: 1, color: V26.hairline),
        Expanded(
          child: _activePartnerId == null
              ? _buildEmptyThread()
              : _buildThread(),
        ),
      ],
    );

    return FutureBuilder<String?>(
      future: _citizenChromeFuture,
      builder: (context, snap) {
        final citizen = snap.data == 'user';
        if (citizen) {
          final narrowChild = _activePartnerId != null
              ? _buildThread(showBackButton: true)
              : Scaffold(
                  backgroundColor: V26.paper,
                  body: V26Backdrop(
                    child: _buildConversationList(showAppBar: false),
                  ),
                );
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: CitizenMockupShell(
              currentRoute: '/chat',
              mobileNavIndex: citizenMobileNavIndexForRoute('/chat'),
              desktopTrailing: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: AppLanguageMenu(compact: true)),
                ),
              ],
              mobileAppBar: (!isWideTop && _activePartnerId == null)
                  ? AppBar(
                      backgroundColor: VetoMockup.surfaceCard,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: VetoMockup.ink, size: 20),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      title: Text(
                        _t('title'),
                        style: const TextStyle(
                          fontFamily: V26.serif,
                          color: VetoMockup.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: VetoMockup.primaryCta),
                          onPressed: _showNewChatPicker,
                          tooltip: _t('newChat'),
                        ),
                      ],
                      bottom: const PreferredSize(
                        preferredSize: Size.fromHeight(1),
                        child: Divider(height: 1, color: VetoMockup.hairline),
                      ),
                    )
                  : null,
              child: isWideTop ? wideShellChild : narrowChild,
            ),
          );
        }

        // Desktop: use 2026 pill-nav app shell and split-view below.
        if (isWideTop) {
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: V26AppShell(
              destinations: V26CitizenNav.destinations(code),
              currentIndex: 1, // צ'אט AI
              onDestinationSelected: (i) {
                V26CitizenNav.go(context, V26CitizenNav.routes[i],
                    current: '/chat');
              },
              desktopStatusText: isRtl
                  ? 'שיחות פעילות · מוצפן E2E'
                  : 'Active conversations · E2E encrypted',
              child: wideShellChild,
            ),
          );
        }

        // Narrow: legacy layout (thread or conversation list).
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: V26.paper,
            body: V26Backdrop(
              child: _activePartnerId != null
                  ? _buildThread(showBackButton: true)
                  : _buildConversationList(showAppBar: true),
            ),
          ),
        );
      },
    );
  }

  // ── Conversation list panel ────────────────────────────────────
  Widget _buildConversationList({bool showAppBar = false}) {
    return Scaffold(
      backgroundColor: V26.paper,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: showAppBar ? null : BackButton(
          color: V26.ink900,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _t('title'),
          style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: V26.navy600),
            onPressed: _showNewChatPicker,
            tooltip: _t('newChat'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: V26.hairline),
        ),
      ),
      body: _loadingConvs
          ? const Center(child: CircularProgressIndicator(color: V26.navy600))
          : _conversations.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: V26.ink300.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(_t('noConversations'),
                        style: const TextStyle(
                            color: V26.ink500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _showNewChatPicker,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_t('newChat')),
                      style: FilledButton.styleFrom(
                          backgroundColor: V26.navy600,
                          foregroundColor: const Color(0xFF041018),
                      ),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: V26.hairline),
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
      selectedTileColor: V26.navy600.withValues(alpha: 0.12),
      tileColor: Colors.transparent,
      leading: CircleAvatar(
        backgroundColor: V26.navy600.withValues(alpha: 0.15),
        child: Text(initial,
            style: const TextStyle(
                color: V26.navy600, fontWeight: FontWeight.w700)),
      ),
      title: Row(children: [
        Expanded(
          child: Text(c.partnerName,
              style: const TextStyle(
                  color: V26.ink900,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Text(ts, style: const TextStyle(color: V26.ink300, fontSize: 11)),
      ]),
      subtitle: c.lastMessage != null
          ? Text(c.lastMessage!,
              style: TextStyle(
                  color: c.unreadCount > 0
                      ? V26.ink900
                      : V26.ink500,
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
                  color: V26.navy600,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${c.unreadCount}',
                  style: const TextStyle(
                      color: Color(0xFF041018),
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
              color: V26.ink300.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(_t('selectPartner'),
              style: const TextStyle(
                  color: V26.ink500,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showNewChatPicker,
            icon: const Icon(Icons.add_rounded),
            label: Text(_t('newChat')),
            style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: const Color(0xFF041018),
            ),
          ),
        ]),
      );

  // ── Message thread panel ───────────────────────────────────────
  Widget _buildThread({bool showBackButton = false}) {
    return Scaffold(
      backgroundColor: V26.paper,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: V26.ink900),
                onPressed: () => setState(() {
                  _activePartnerId = null;
                  _activePartnerName = null;
                }),
              )
            : null,
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: V26.navy500.withValues(alpha: 0.2),
            child: Text(
              (_activePartnerName?.isNotEmpty == true)
                  ? _activePartnerName![0].toUpperCase()
                  : '?',
              style: const TextStyle(color: V26.navy600, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_activePartnerName ?? '',
                style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: V26.ink900),
            onPressed: () => _loadMessages(reset: true),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: V26.hairline),
        ),
      ),
      body: Column(children: [
        // Loading more indicator
        if (_loadingMsgs && _messages.isNotEmpty)
          const LinearProgressIndicator(
              color: V26.navy600, minHeight: 2),
        // Messages list
        Expanded(
          child: _loadingMsgs && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator(color: V26.navy600))
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
        const Expanded(child: Divider(color: V26.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: const TextStyle(
                  color: V26.ink500, fontSize: 11)),
        ),
        const Expanded(child: Divider(color: V26.hairline)),
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
                    backgroundColor: const Color(0xE6121824),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: V26.hairline),
                    ),
                    title: Text(_t('deleteMsg'),
                        style: const TextStyle(color: V26.ink900)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel',
                            style: TextStyle(color: V26.ink500)),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteMessage(msg);
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: V26.emerg),
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
                ? V26.navy500
                : V26.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(msg.isOwn ? 16 : 4),
              bottomRight: Radius.circular(msg.isOwn ? 4 : 16),
            ),
            border: msg.isOwn
                ? null
                : Border.all(color: V26.hairline),
            boxShadow: msg.isOwn
                ? null
                : [
                    BoxShadow(
                      color: V26.navy600.withValues(alpha: 0.06),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: msg.isOwn
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(msg.text,
                  style: TextStyle(
                      color: msg.isOwn
                          ? V26.ink900
                          : V26.ink900,
                      fontSize: 14,
                      height: 1.45)),
              const SizedBox(height: 3),
              Text(time,
                  style: TextStyle(
                      color: msg.isOwn
                          ? V26.ink900.withValues(alpha: 0.7)
                          : V26.ink300,
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
        color: Color(0x18FFFFFF),
        border: Border(top: BorderSide(color: V26.hairline)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            style: const TextStyle(color: V26.ink900, fontSize: 14),
            cursorColor: V26.navy600,
            maxLines: 4,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _t('typeMessage'),
              hintStyle: const TextStyle(color: V26.ink500),
              filled: true,
              fillColor: V26.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide:
                    const BorderSide(color: V26.hairline),
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
              backgroundColor: V26.navy600,
              foregroundColor: const Color(0xFF041018),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              minimumSize: const Size(48, 48),
            ),
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF041018)))
                : const Icon(Icons.send_rounded, size: 18, color: Color(0xFF041018)),
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
