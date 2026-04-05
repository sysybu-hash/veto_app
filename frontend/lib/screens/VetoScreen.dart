import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';

// ג”€ג”€ Internal chat message model ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€ג”€
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isSystem;
  _ChatMessage({required this.text, required this.isUser, this.isSystem = false});
}

class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen> {
  String _role = '', _phone = '';
  bool _isDispatching = false;

  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _geminiHistory = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _messages.add(_ChatMessage(
      text: '׳©׳׳•׳! ׳׳ ׳™ ׳”׳¢׳•׳–׳¨ ׳”׳׳©׳₪׳˜׳™ ׳©׳ VETO.\n'
          '׳×׳׳¨ ׳‘׳§׳¦׳¨׳” ׳׳× ׳”׳‘׳¢׳™׳” ׳”׳׳©׳₪׳˜׳™׳× ׳©׳׳ ׳•׳׳׳¦׳ ׳¢׳‘׳•׳¨׳ ׳¢׳•׳¨׳ ׳“׳™׳ ׳–׳׳™׳.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final r = await AuthService().getStoredRole();
    final p = await AuthService().getStoredPhone();
    if (mounted) {
      setState(() {
        _role  = r ?? '';
        _phone = p ?? '';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading || _isDispatching) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    // Snapshot history BEFORE this message
    final historySnapshot = List<Map<String, dynamic>>.from(_geminiHistory);

    final result = await AiService().chat(
      message: text,
      history: historySnapshot,
    );

    // Add this exchange to history for future calls
    _geminiHistory.add({'role': 'user',  'parts': [{'text': text}]});
    final reply = (result['reply'] as String?) ?? '׳׳¦׳˜׳¢׳¨, ׳׳™׳¨׳¢׳” ׳©׳’׳™׳׳”.';
    _geminiHistory.add({'role': 'model', 'parts': [{'text': reply}]});

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _messages.add(_ChatMessage(text: reply, isUser: false));
    });
    _scrollToBottom();

    if (result['classified'] == true) {
      final spec       = result['specialization'] as String?;
      final lawyerMap  = (result['lawyer'] as Map?)?.cast<String, dynamic>();
      final lawyerName = lawyerMap?['name'] as String?;
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _dispatch(spec, lawyerName);
    }
  }

  Future<void> _dispatch(String? spec, String? lawyerName) async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);
    HapticFeedback.heavyImpact();

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    SocketService().emitStartVeto(
      lat: pos?.latitude ?? 32.08,
      lng: pos?.longitude ?? 34.78,
      preferredLanguage: 'he',
      specialization: spec,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: lawyerName != null
            ? 'נ”” ׳׳—׳₪׳© ׳¢׳•׳¨׳ ׳“׳™׳ ׳‘׳×׳—׳•׳ $spec...\n$lawyerName ׳™׳™׳¦׳•׳¨ ׳׳™׳×׳ ׳§׳©׳¨ ׳‘׳§׳¨׳•׳‘.'
            : 'נ”” ׳׳—׳₪׳© ׳¢׳•׳¨׳ ׳“׳™׳ ׳–׳׳™׳ ׳‘׳×׳—׳•׳ $spec...',
        isUser: false,
        isSystem: true,
      ));
    });
    _scrollToBottom();
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

  void _openCamera() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('׳׳¦׳׳׳” - ׳‘׳₪׳™׳×׳•׳—')));

  void _openRecording() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('׳”׳§׳׳˜׳” - ׳‘׳₪׳™׳×׳•׳—')));

  void _showLocation() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pos != null
          ? '׳׳™׳§׳•׳: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
          : '׳׳ ׳ ׳™׳×׳ ׳׳׳¦׳•׳ ׳׳™׳§׳•׳'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _role.toLowerCase().contains('admin');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('VETO'),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin_settings'),
                tooltip: '׳ ׳™׳”׳•׳',
              ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              tooltip: '׳₪׳¨׳•׳₪׳™׳',
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => AuthService().logout(context),
              tooltip: '׳”׳×׳ ׳×׳§',
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoPalette.border),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _statusBadge(),
              const SizedBox(height: 4),
              Expanded(child: _chatList()),
              _inputRow(),
              _actionRow(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDispatching
            ? VetoPalette.emergency.withValues(alpha: 0.12)
            : VetoPalette.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isDispatching
              ? VetoPalette.emergency.withValues(alpha: 0.3)
              : VetoPalette.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isDispatching
                  ? VetoPalette.emergency
                  : VetoPalette.success,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isDispatching ? '׳©׳™׳“׳•׳¨ ׳₪׳¢׳™׳' : '׳׳•׳’׳',
            style: TextStyle(
              color: _isDispatching
                  ? VetoPalette.emergency
                  : VetoPalette.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (_phone.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              _phone,
              style: const TextStyle(
                  color: VetoPalette.textSubtle, fontSize: 11),
              textDirection: TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chatList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _typingIndicator();
        return _messageBubble(_messages[index]);
      },
    );
  }

  Widget _messageBubble(_ChatMessage msg) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VetoPalette.emergency.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: VetoPalette.emergency.withValues(alpha: 0.35)),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(
              color: VetoPalette.text, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
      );
    }

    final isUser = msg.isUser;
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? VetoPalette.surface
              : VetoPalette.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? VetoPalette.border
                : VetoPalette.success.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(
              color: VetoPalette.text, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VetoPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              child: LinearProgressIndicator(
                backgroundColor: VetoPalette.border,
                valueColor:
                    const AlwaysStoppedAnimation(VetoPalette.success),
              ),
            ),
            const SizedBox(width: 8),
            const Text('׳׳¢׳‘׳“...',
                style: TextStyle(
                    color: VetoPalette.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _inputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_isDispatching,
              style:
                  const TextStyle(color: VetoPalette.text, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    _isDispatching ? '׳‘׳×׳”׳׳™׳...' : '׳×׳׳¨ ׳׳× ׳”׳‘׳¢׳™׳”...',
                hintStyle:
                    const TextStyle(color: VetoPalette.textMuted),
                filled: true,
                fillColor: VetoPalette.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: VetoPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: VetoPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: VetoPalette.success),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_isLoading || _isDispatching)
                    ? VetoPalette.border
                    : VetoPalette.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionBtn(Icons.camera_alt_outlined, '׳×׳™׳¢׳•׳“', _openCamera),
          _actionBtn(Icons.mic_none_rounded, '׳”׳§׳׳˜׳”', _openRecording),
          _actionBtn(
              Icons.location_on_outlined, '׳׳™׳§׳•׳', _showLocation),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: VetoPalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: VetoPalette.border),
            ),
            child: Icon(icon, color: VetoPalette.textMuted, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: VetoPalette.textSubtle, fontSize: 11)),
        ],
      ),
    );
  }
}

