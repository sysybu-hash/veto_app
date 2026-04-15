import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF334155), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
          title: Text(
          _userName != null ? _userName! : 'Vault',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F8)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B8FFF)))
          : _files.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.folder_open_outlined, size: 56, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text('No documents shared.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5B8FFF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(getIcon(), color: const Color(0xFF5B8FFF), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(type,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF5B8FFF)),
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
