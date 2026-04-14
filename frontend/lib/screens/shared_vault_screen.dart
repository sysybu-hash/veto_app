import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/theme/veto_theme.dart';
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
        setState(() {
          _files = data['files'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoPalette.bg,
      appBar: AppBar(
        title: Text(
          'Shared Vault: ${_userName ?? "User"}',
          style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: VetoPalette.text),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: VetoPalette.primary))
          : _files.isEmpty
              ? const Center(
                  child: Text(
                    'No documents shared by this user.',
                    style: TextStyle(color: VetoPalette.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final f = _files[i];
                    return _SharedFileCard(file: f);
                  },
                ),
    );
  }
}

class _SharedFileCard extends StatelessWidget {
  final Map<String, dynamic> file;

  const _SharedFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final name = file['name'] ?? 'Untitled';
    final url = file['url'] ?? '';
    final type = file['mimeType'] ?? '';

    IconData getIcon() {
      if (type.startsWith('image/')) return Icons.image_outlined;
      if (type.startsWith('video/')) return Icons.videocam_outlined;
      if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
      return Icons.insert_drive_file_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Row(
        children: [
          Icon(getIcon(), color: VetoPalette.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: VetoPalette.text,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  type,
                  style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: VetoPalette.primary),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
