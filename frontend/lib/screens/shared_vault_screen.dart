// ============================================================
//  SharedVaultScreen — VETO 2026
//  Tokens-aligned. Files shared between citizen and lawyer for a case.
// ============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/auth_service.dart';

class SharedVaultScreen extends StatefulWidget {
  const SharedVaultScreen({super.key});

  @override
  State<SharedVaultScreen> createState() => _SharedVaultScreenState();
}

class _SharedVaultScreenState extends State<SharedVaultScreen> {
  bool _loading = true;
  List<dynamic> _files = [];
  String? _userId;
  String? _userName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId = args?['userId'];
      _userName = args?['userName'];
      if (_userId != null) _loadSharedFiles();
    }
  }

  Future<void> _loadSharedFiles() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final token = await AuthService().getToken();
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/vault/shared/$_userId'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() { _files = data['files'] ?? []; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoTokens.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('כספת משותפת', style: VetoTokens.kicker),
            Text(_userName ?? 'Vault', style: VetoTokens.titleLg),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadSharedFiles,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'רענן',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
          : _files.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: VetoTokens.cardDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(color: VetoTokens.paper2, borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.folder_open_outlined, size: 28, color: VetoTokens.ink300),
                        ),
                        const SizedBox(height: 12),
                        Text('אין מסמכים משותפים', style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
                        const SizedBox(height: 4),
                        Text('כשהאזרח יעלה קובץ, הוא יופיע כאן.', style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _SharedFileCard(file: _files[i] as Map<String, dynamic>),
                    ),
                  ),
                ),
    );
  }
}

class _SharedFileCard extends StatelessWidget {
  const _SharedFileCard({required this.file});
  final Map<String, dynamic> file;

  @override
  Widget build(BuildContext context) {
    final name = (file['name'] ?? 'Untitled').toString();
    final url = (file['url'] ?? '').toString();
    final type = (file['mimeType'] ?? '').toString();

    IconData icon;
    Color color;
    if (type.startsWith('image/')) {
      icon = Icons.image_outlined; color = const Color(0xFF94681A);
    } else if (type.startsWith('video/')) {
      icon = Icons.videocam_outlined; color = const Color(0xFF5A4FCF);
    } else if (type.startsWith('audio/')) {
      icon = Icons.music_note_rounded; color = const Color(0xFF16664B);
    } else if (type.contains('pdf')) {
      icon = Icons.picture_as_pdf_outlined; color = VetoTokens.emerg2;
    } else {
      icon = Icons.insert_drive_file_outlined; color = VetoTokens.navy600;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(type, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 18, color: VetoTokens.navy600),
            onPressed: url.isEmpty ? null : () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            tooltip: 'הורד',
          ),
        ],
      ),
    );
  }
}
