import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/theme/veto_2026.dart';
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
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/vault/shared/$_userId'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
          )
          .timeout(const Duration(seconds: 15));

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
      backgroundColor: V26.paper,
      appBar: AppBar(
        backgroundColor: V26.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: V26.ink900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _userName != null ? _userName! : 'Vault',
          style: const TextStyle(
            fontFamily: V26.serif,
            color: V26.ink900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: V26.hairline),
        ),
      ),
      body: V26Backdrop(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: V26.navy600))
            : _files.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_open_outlined,
                          size: 56, color: V26.ink300),
                      SizedBox(height: 12),
                      Text('No documents shared.',
                          style: TextStyle(
                              fontFamily: V26.sans,
                              color: V26.ink500,
                              fontSize: 14)),
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

    return V26Card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: V26.paper2,
              border: Border.all(color: V26.hairline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(getIcon(), color: V26.navy600, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink900,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  type,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: V26.navy600),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
