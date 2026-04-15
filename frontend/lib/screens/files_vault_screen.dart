// ============================================================
//  FilesVaultScreen.dart — Per-user encrypted file vault
//  Features: upload, AI analysis, legal case prep,
//            lawyer access sharing, 100 MB quota, compression
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../platform/browser_bridge.dart' as browser_bridge;

// ── i18n strings ─────────────────────────────────────────────
class _L {
  final String title, upload, uploading, analyzing, deleteConfirm, delete,
      share, revoke, analyze, noFiles, usageOf, used, quota, legalCase,
      caseName, createCase, addToCase, files, allFiles, caseFiles,
      shareWithLawyer, lawyerAccess, fileType, size, date, status,
      aiSummary, aiBtn, cancel, save, errorUpload, successUpload,
      successDelete, successShare, compressing, caseCreated, loading,
      rename, fileName, successRename,
      deleteCase, deleteCaseConfirm, successDeleteCase,
      removeFromCase;

  const _L({
    required this.title, required this.upload, required this.uploading,
    required this.analyzing, required this.deleteConfirm, required this.delete,
    required this.share, required this.revoke, required this.analyze,
    required this.noFiles, required this.usageOf, required this.used,
    required this.quota, required this.legalCase, required this.caseName,
    required this.createCase, required this.addToCase, required this.files,
    required this.allFiles, required this.caseFiles, required this.shareWithLawyer,
    required this.lawyerAccess, required this.fileType, required this.size,
    required this.date, required this.status, required this.aiSummary,
    required this.aiBtn, required this.cancel, required this.save,
    required this.errorUpload, required this.successUpload,
    required this.successDelete, required this.successShare,
    required this.compressing, required this.caseCreated, required this.loading,
    required this.rename, required this.fileName, required this.successRename,
    required this.deleteCase, required this.deleteCaseConfirm, required this.successDeleteCase,
    required this.removeFromCase,
  });
}

const _he = _L(
  title: 'כספת הקבצים שלי', upload: 'העלה קובץ', uploading: 'מעלה...',
  analyzing: 'AI מנתח...', deleteConfirm: 'למחוק את הקובץ?',
  delete: 'מחק', share: 'שתף עם עו"ד', revoke: 'בטל גישה',
  analyze: 'נתח עם AI', noFiles: 'אין קבצים עדיין',
  usageOf: 'בשימוש: ', used: 'MB', quota: ' / 100 MB',
  legalCase: 'תיק משפטי', caseName: 'שם התיק',
  createCase: 'צור תיק', addToCase: 'הוסף לתיק', files: 'קבצים',
  allFiles: 'כל הקבצים', caseFiles: 'קבצי התיק',
  shareWithLawyer: 'שתף עם עורך דין', lawyerAccess: 'גישת עו"ד',
  fileType: 'סוג', size: 'גודל', date: 'תאריך', status: 'סטטוס',
  aiSummary: 'סיכום AI', aiBtn: 'נתח', cancel: 'ביטול', save: 'שמור',
  errorUpload: 'שגיאה בהעלאה', successUpload: 'קובץ הועלה בהצלחה',
  successDelete: 'הקובץ נמחק', successShare: 'הגישה עודכנה',
  compressing: 'דוחס...', caseCreated: 'התיק נוצר', loading: 'טוען...',
  rename: 'שנה שם', fileName: 'שם הקובץ', successRename: 'השם עודכן',
  deleteCase: 'מחק תיק', deleteCaseConfirm: 'למחוק את התיק? הקבצים יישארו בכספת.',
  successDeleteCase: 'התיק נמחק', removeFromCase: 'הסר מהתיק',
);

const _en = _L(
  title: 'My File Vault', upload: 'Upload File', uploading: 'Uploading...',
  analyzing: 'AI analyzing...', deleteConfirm: 'Delete this file?',
  delete: 'Delete', share: 'Share with Lawyer', revoke: 'Revoke Access',
  analyze: 'Analyze with AI', noFiles: 'No files yet',
  usageOf: 'Used: ', used: 'MB', quota: ' / 100 MB',
  legalCase: 'Legal Case', caseName: 'Case name',
  createCase: 'Create Case', addToCase: 'Add to Case', files: 'files',
  allFiles: 'All Files', caseFiles: 'Case Files',
  shareWithLawyer: 'Share with Lawyer', lawyerAccess: 'Lawyer Access',
  fileType: 'Type', size: 'Size', date: 'Date', status: 'Status',
  aiSummary: 'AI Summary', aiBtn: 'Analyze', cancel: 'Cancel', save: 'Save',
  errorUpload: 'Upload failed', successUpload: 'File uploaded successfully',
  successDelete: 'File deleted', successShare: 'Access updated',
  compressing: 'Compressing...', caseCreated: 'Case created', loading: 'Loading...',
  rename: 'Rename', fileName: 'File name', successRename: 'Name updated',
  deleteCase: 'Delete Case', deleteCaseConfirm: 'Delete this case? Files will remain in your vault.',
  successDeleteCase: 'Case deleted', removeFromCase: 'Remove from Case',
);

const _ru = _L(
  title: 'Моё хранилище', upload: 'Загрузить файл', uploading: 'Загрузка...',
  analyzing: 'AI анализирует...', deleteConfirm: 'Удалить файл?',
  delete: 'Удалить', share: 'Поделиться с адвокатом', revoke: 'Закрыть доступ',
  analyze: 'Анализ AI', noFiles: 'Файлов пока нет',
  usageOf: 'Использовано: ', used: 'МБ', quota: ' / 100 МБ',
  legalCase: 'Юридическое дело', caseName: 'Название дела',
  createCase: 'Создать дело', addToCase: 'Добавить в дело', files: 'файлов',
  allFiles: 'Все файлы', caseFiles: 'Файлы дела',
  shareWithLawyer: 'Поделиться с адвокатом', lawyerAccess: 'Доступ адвоката',
  fileType: 'Тип', size: 'Размер', date: 'Дата', status: 'Статус',
  aiSummary: 'Сводка AI', aiBtn: 'Анализ', cancel: 'Отмена', save: 'Сохранить',
  errorUpload: 'Ошибка загрузки', successUpload: 'Файл загружен',
  successDelete: 'Файл удалён', successShare: 'Доступ обновлён',
  compressing: 'Сжатие...', caseCreated: 'Дело создано', loading: 'Загрузка...',
  rename: 'Переименовать', fileName: 'Имя файла', successRename: 'Имя обновлено',
  deleteCase: 'Удалить дело', deleteCaseConfirm: 'Удалить это дело? Файлы останутся в хранилище.',
  successDeleteCase: 'Дело удалено', removeFromCase: 'Убрать из дела',
);

// ── Data models ───────────────────────────────────────────────
class _VaultFile {
  final String id, name, type, url, status;
  final int sizeBytes;
  final DateTime uploadedAt;
  final bool lawyerAccess;
  final String? aiSummary, caseId;

  const _VaultFile({
    required this.id, required this.name, required this.type,
    required this.url, required this.status, required this.sizeBytes,
    required this.uploadedAt, required this.lawyerAccess,
    this.aiSummary, this.caseId,
  });

  factory _VaultFile.fromJson(Map<String, dynamic> j) => _VaultFile(
    id: j['_id'] ?? j['id'] ?? '',
    name: j['name'] ?? j['fileName'] ?? 'file',
    type: j['mimeType'] ?? j['type'] ?? 'application/octet-stream',
    url: j['url'] ?? '',
    status: j['status'] ?? 'uploaded',
    sizeBytes: (j['sizeBytes'] ?? j['size'] ?? 0) as int,
    uploadedAt: DateTime.tryParse(j['uploadedAt'] ?? j['createdAt'] ?? '') ?? DateTime.now(),
    lawyerAccess: j['lawyerAccess'] == true,
    aiSummary: j['aiSummary'] as String?,
    caseId: j['caseId'] as String?,
  );

  String get sizeLabel {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData get icon {
    if (type.startsWith('image/')) return Icons.image_outlined;
    if (type.startsWith('video/')) return Icons.videocam_outlined;
    if (type.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (type.contains('word') || type.contains('document')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get typeColor {
    if (type.startsWith('image/')) return VetoPalette.accentSky;
    if (type.startsWith('video/')) return const Color(0xFF2ECC71);
    if (type.startsWith('audio/')) return VetoPalette.accentSky;
    if (type.contains('pdf')) return VetoPalette.emergency;
    return VetoPalette.textMuted;
  }
}

class _LegalCase {
  final String id, name;
  final List<String> fileIds;
  final DateTime createdAt;

  const _LegalCase({
    required this.id, required this.name,
    required this.fileIds, required this.createdAt,
  });

  factory _LegalCase.fromJson(Map<String, dynamic> j) => _LegalCase(
    id: j['_id'] ?? j['id'] ?? '',
    name: j['name'] ?? '',
    fileIds: List<String>.from(j['fileIds'] ?? []),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ── Screen ────────────────────────────────────────────────────
class FilesVaultScreen extends StatefulWidget {
  const FilesVaultScreen({super.key});

  @override
  State<FilesVaultScreen> createState() => _FilesVaultScreenState();
}

class _FilesVaultScreenState extends State<FilesVaultScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  List<_VaultFile> _files = [];
  List<_LegalCase> _cases = [];
  bool _loading = true;
  bool _uploading = false;
  bool _analyzing = false;
  bool _isDragging = false;
  String? _activeFileId;

  late TabController _tabController;

  double get _usedMb =>
      _files.fold(0.0, (s, f) => s + f.sizeBytes) / (1024 * 1024);
  double get _quotaMb => 100.0;

  _L get _l {
    final code = context.read<AppLanguageController>().code;
    if (code == 'he') return _he;
    if (code == 'ru') return _ru;
    return _en;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
    if (kIsWeb) {
      browser_bridge.setupDragAndDropHandlers(
        onDragOver: () { if (mounted) setState(() => _isDragging = true); },
        onDragLeave: () { if (mounted) setState(() => _isDragging = false); },
        onDrop: (files) {
          if (mounted) setState(() => _isDragging = false);
          for (final f in files) { _uploadHtmlFile(f); }
        },
      );
    }
  }

  @override
  void dispose() {
    // browser_bridge handlers are anonymous in this implementation, 
    // ideally we'd remove them but flutter doesn't provide a clean dispose for global listeners easily without complexity
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> get _token async => _auth.getToken();

  // ── Drag & drop (web) ────────────────────────────────────────
  // ── Drag & drop (web handlers moved to bridge) ────────────────

  Future<void> _uploadHtmlFile(dynamic file) async {
    if (_usedMb >= _quotaMb) { _snack(_l.quota, isError: true); return; }
    setState(() => _uploading = true);
    try {
      final tok = await _token;
      if (tok == null) return;
      
      final bytes = await browser_bridge.readFileAsBytes(file);
      final fileName = browser_bridge.getFileName(file);
      final fileType = browser_bridge.getFileType(file);

      final uri = Uri.parse('${AppConfig.baseUrl}/vault/files/upload');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(AppConfig.httpHeadersBinary({'Authorization': 'Bearer $tok'}))
        ..fields['name'] = fileName
        ..fields['mimeType'] = fileType.isNotEmpty ? fileType : 'application/octet-stream';
      
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      final streamed = await req.send();
      if (streamed.statusCode == 201 || streamed.statusCode == 200) {
        _snack(_l.successUpload);
        await _load();
      } else {
        _snack(_l.errorUpload, isError: true);
      }
    } catch (_) {
      _snack(_l.errorUpload, isError: true);
    }
    if (mounted) setState(() => _uploading = false);
  }

  // ── Camera capture (web) ─────────────────────────────────────
  void _captureFromCamera() {
    if (!kIsWeb) return;
    browser_bridge.triggerCameraCapture((f) => _uploadHtmlFile(f));
  }

  // ── File preview dialog ──────────────────────────────────────
  void _showPreview(_VaultFile file) {
    final isImage = file.type.startsWith('image/');
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: VetoPalette.border))),
            child: Row(children: [
              Icon(file.icon, color: file.typeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(file.name,
                  style: const TextStyle(color: VetoPalette.text,
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: VetoPalette.textMuted),
                onPressed: () => Navigator.pop(ctx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
          // Preview content
          if (isImage && file.url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  file.url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image_outlined,
                        size: 80, color: VetoPalette.textMuted),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Icon(file.icon, size: 80, color: file.typeColor),
            ),
          // Metadata row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              const Icon(Icons.storage_rounded, size: 12, color: VetoPalette.textMuted),
              const SizedBox(width: 4),
              Text(file.sizeLabel,
                  style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: VetoPalette.textMuted),
              const SizedBox(width: 4),
              Text(
                '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12),
              ),
            ]),
          ),
          // Open in new tab button
          if (file.url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (kIsWeb) {
                      browser_bridge.openInNewTab(file.url);
                    } else {
                      // handle mobile download or launch
                    }
                    if (mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open in new tab'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VetoPalette.primary,
                    side: const BorderSide(color: VetoPalette.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── API calls ────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tok = await _token;
      if (tok == null) return;
      final filesRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/vault/files'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 15));
      final casesRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/vault/cases'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (filesRes.statusCode == 200) {
        final data = jsonDecode(filesRes.body);
        final list = data is List ? data : (data['files'] ?? []);
        _files = (list as List).map((e) => _VaultFile.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (casesRes.statusCode == 200) {
        final data = jsonDecode(casesRes.body);
        final list = data is List ? data : (data['cases'] ?? []);
        _cases = (list as List).map((e) => _LegalCase.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickFile() async {
    if (_uploading) return;
    if (_usedMb >= _quotaMb) {
      _snack(_l.quota, isError: true);
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
        allowMultiple: false,
      ).timeout(const Duration(minutes: 2), onTimeout: () => null);

      if (result == null || result.files.isEmpty) {
        debugPrint('File picker cancelled or timed out');
        return;
      }

      final pf = result.files.first;
      final fileSizeMb = pf.size / (1024 * 1024);
      
      if (_usedMb + fileSizeMb > _quotaMb) {
        _snack('${_l.quota} (max 100MB)', isError: true);
        return;
      }

      setState(() => _uploading = true);

      final tok = await _token;
      if (tok == null) throw Exception('No auth token');

      final uri = Uri.parse('${AppConfig.baseUrl}/vault/files/upload');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(AppConfig.httpHeadersBinary({'Authorization': 'Bearer $tok'}))
        ..fields['name'] = pf.name;

      if (pf.extension != null) {
        req.fields['mimeType'] = 'application/${pf.extension}';
      }

      if (kIsWeb) {
        if (pf.bytes == null) throw Exception('No file data received');
        req.files.add(http.MultipartFile.fromBytes('file', pf.bytes!, filename: pf.name));
      } else {
        if (pf.path == null) throw Exception('File path is null');
        req.files.add(await http.MultipartFile.fromPath('file', pf.path!));
      }

      final streamedRes = await req.send().timeout(const Duration(seconds: 60));
      final responseBody = await streamedRes.stream.bytesToString();

      if (streamedRes.statusCode == 200 || streamedRes.statusCode == 201) {
        _snack(_l.successUpload);
        await _load();
      } else {
        debugPrint('Upload failed (${streamedRes.statusCode}): $responseBody');
        _snack('${_l.errorUpload} (${streamedRes.statusCode})', isError: true);
      }
    } catch (e) {
      debugPrint('Error in _pickFile: $e');
      _snack(_l.errorUpload, isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _analyzeFile(_VaultFile file) async {
    setState(() { _analyzing = true; _activeFileId = file.id; });
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}/analyze'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        _snack(_l.aiSummary);
        await _load();
      }
    } catch (_) {}
    if (mounted) setState(() { _analyzing = false; _activeFileId = null; });
  }

  Future<void> _toggleLawyerAccess(_VaultFile file) async {
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}/access'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'lawyerAccess': !file.lawyerAccess}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _snack(_l.successShare);
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _deleteFile(_VaultFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_l.deleteConfirm,
            style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700)),
        content: Text(file.name,
            style: const TextStyle(color: VetoPalette.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l.cancel, style: const TextStyle(color: VetoPalette.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
            child: Text(_l.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
        _snack(_l.successDelete);
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _renameFile(_VaultFile file) async {
    final ctrl = TextEditingController(text: file.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_l.rename,
            style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: VetoPalette.text),
          decoration: InputDecoration(
            hintText: _l.fileName,
            hintStyle: const TextStyle(color: VetoPalette.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: VetoPalette.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
            child: Text(_l.save),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == file.name) return;

    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'name': newName}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        _snack(_l.successRename);
        await _load();
      }
    } catch (_) {}
  }


  Future<void> _createCase() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_l.createCase,
            style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: VetoPalette.text),
          decoration: InputDecoration(
            hintText: _l.caseName,
            hintStyle: const TextStyle(color: VetoPalette.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: VetoPalette.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
            child: Text(_l.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/vault/cases'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'name': name}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 201 || res.statusCode == 200) {
        _snack(_l.caseCreated);
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _renameCase(_LegalCase c) async {
    final ctrl = TextEditingController(text: c.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_l.rename,
            style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: VetoPalette.text),
          decoration: InputDecoration(
            hintText: _l.caseName,
            hintStyle: const TextStyle(color: VetoPalette.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: VetoPalette.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
            child: Text(_l.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == c.name) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/vault/cases/${c.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'name': name}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _snack(_l.successRename);
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _deleteCase(_LegalCase c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_l.deleteCase,
            style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700)),
        content: Text(_l.deleteCaseConfirm,
            style: const TextStyle(color: VetoPalette.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l.cancel, style: const TextStyle(color: VetoPalette.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
            child: Text(_l.deleteCase),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/vault/cases/${c.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _snack(_l.successDeleteCase);
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _removeFromCase(_VaultFile file) async {
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'caseId': null}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        await _load();
      }
    } catch (_) {}
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? VetoPalette.emergency : VetoPalette.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
          title: Text(_l.title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          actions: [
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.photo_camera_outlined, color: Color(0xFF334155)),
                onPressed: _uploading ? null : _captureFromCamera,
                tooltip: 'Capture from camera',
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF5B8FFF),
            labelColor: const Color(0xFF5B8FFF),
            unselectedLabelColor: const Color(0xFF94A3B8),
            tabs: [
              Tab(text: _l.allFiles),
              Tab(text: _l.legalCase),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploading ? null : _pickFile,
          backgroundColor: _uploading ? const Color(0xFFE2E8F8) : const Color(0xFF5B8FFF),
          icon: _uploading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.upload_file_rounded, color: Colors.white),
          label: Text(_uploading ? _l.uploading : _l.upload,
              style: const TextStyle(color: VetoColors.white, fontWeight: FontWeight.w700)),
        ),
        body: Stack(children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  _buildQuotaBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllFilesTab(),
                        _buildCasesTab(),
                      ],
                    ),
                  ),
                ]),
          if (_isDragging)
            IgnorePointer(
              child: Container(
                color: VetoPalette.primary.withValues(alpha: 0.18),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: VetoPalette.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: VetoPalette.primary, width: 2),
                      ),
                      child: const Icon(Icons.upload_file_rounded,
                          size: 60, color: VetoPalette.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text('Drop files here',
                        style: TextStyle(color: VetoPalette.primary,
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildQuotaBar() {
    final pct = (_usedMb / _quotaMb).clamp(0.0, 1.0);
    final color = pct > 0.9
        ? VetoPalette.emergency
        : pct > 0.7
            ? VetoPalette.warning
            : VetoPalette.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: VetoPalette.surface,
        border: Border(bottom: BorderSide(color: VetoPalette.border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_l.usageOf,
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13)),
          Text('${_usedMb.toStringAsFixed(1)} ${_l.used}${_l.quota}',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${_files.length} ${_l.files}',
              style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: VetoPalette.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }

  Widget _buildAllFilesTab() {
    if (_files.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.folder_open_outlined,
              size: 64, color: VetoPalette.textSubtle.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_l.noFiles,
              style: const TextStyle(color: VetoPalette.textMuted,
                  fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(_l.upload,
              style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 13)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _FileCard(
        file: _files[i],
        l: _l,
        isAnalyzing: _analyzing && _activeFileId == _files[i].id,
        onAnalyze: () => _analyzeFile(_files[i]),
        onDelete: () => _deleteFile(_files[i]),
        onToggleAccess: () => _toggleLawyerAccess(_files[i]),
        onRename: () => _renameFile(_files[i]),
        onAddToCase: _cases.isEmpty ? null : () => _showAddToCase(_files[i]),
        onRemoveFromCase: _files[i].caseId == null ? null : () => _removeFromCase(_files[i]),
        onPreview: () => _showPreview(_files[i]),
      ),
    );
  }

  Widget _buildCasesTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Expanded(child: Text(_l.caseFiles,
              style: const TextStyle(
                  color: VetoPalette.text, fontWeight: FontWeight.w700, fontSize: 16))),
          TextButton.icon(
            onPressed: _createCase,
            icon: const Icon(Icons.create_new_folder_outlined,
                size: 18, color: VetoPalette.primary),
            label: Text(_l.createCase,
                style: const TextStyle(color: VetoPalette.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      if (_cases.isEmpty)
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cases_outlined,
                  size: 64, color: VetoPalette.textSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(_l.createCase,
                  style: const TextStyle(color: VetoPalette.textMuted,
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ),
        )
      else
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = _cases[i];
              final caseFiles = _files.where((f) => f.caseId == c.id).toList();
              return _CaseCard(
                legalCase: c, files: caseFiles, l: _l,
                onRename: () => _renameCase(c),
                onDelete: () => _deleteCase(c),
              );
            },
          ),
        ),
    ]);
  }

  Future<void> _showAddToCase(_VaultFile file) async {
    final selected = await showModalBottomSheet<_LegalCase>(
      context: context,
      backgroundColor: VetoPalette.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: VetoPalette.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(_l.addToCase,
              style: const TextStyle(color: VetoPalette.text,
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ..._cases.map((c) => ListTile(
          leading: const Icon(Icons.cases_rounded, color: VetoPalette.primary),
          title: Text(c.name, style: const TextStyle(color: VetoPalette.text)),
          subtitle: Text('${c.fileIds.length} ${_l.files}',
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
          onTap: () => Navigator.pop(ctx, c),
        )),
        const SizedBox(height: 12),
      ]),
    );
    if (selected == null) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      await http.patch(
        Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({'caseId': selected.id}),
      ).timeout(const Duration(seconds: 10));
      await _load();
    } catch (_) {}
  }
}

// ── File card widget ─────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final _VaultFile file;
  final _L l;
  final bool isAnalyzing;
  final VoidCallback onAnalyze, onDelete, onToggleAccess, onRename;
  final VoidCallback? onAddToCase, onRemoveFromCase;
  final VoidCallback? onPreview;

  const _FileCard({
    required this.file, required this.l, required this.isAnalyzing,
    required this.onAnalyze, required this.onDelete,
    required this.onToggleAccess, required this.onRename,
    this.onAddToCase, this.onRemoveFromCase, this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ─────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: file.typeColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(file.icon, color: file.typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(file.name, style: const TextStyle(
                  color: VetoPalette.text, fontWeight: FontWeight.w700,
                  fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${file.sizeLabel}  ·  '
                  '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                  style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
            ],
          )),
          if (onPreview != null)
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              color: VetoPalette.textMuted,
              onPressed: onPreview,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Preview',
            ),
          // Lawyer access badge
          if (file.lawyerAccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: VetoPalette.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VetoPalette.success.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_open_rounded,
                    size: 11, color: VetoPalette.success),
                const SizedBox(width: 3),
                Text(l.lawyerAccess, style: const TextStyle(
                    color: VetoPalette.success, fontSize: 10,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
        // ── AI summary ─────────────────────────────────
        if (file.aiSummary != null && file.aiSummary!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.20)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 14, color: VetoPalette.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(file.aiSummary!,
                  style: const TextStyle(
                      color: VetoPalette.text, fontSize: 12, height: 1.5),
                  maxLines: 3, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
        // ── Action buttons ─────────────────────────────
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _ActionChip(
            icon: isAnalyzing
                ? Icons.hourglass_empty_rounded
                : Icons.auto_awesome,
            label: isAnalyzing ? l.analyzing : l.aiBtn,
            color: VetoPalette.primary,
            onTap: isAnalyzing ? null : onAnalyze,
          ),
          _ActionChip(
            icon: file.lawyerAccess
                ? Icons.lock_rounded
                : Icons.lock_open_rounded,
            label: file.lawyerAccess ? l.revoke : l.share,
            color: file.lawyerAccess ? VetoPalette.warning : VetoPalette.success,
            onTap: onToggleAccess,
          ),
          _ActionChip(
            icon: Icons.edit_note_rounded,
            label: l.rename,
            color: VetoPalette.textSubtle,
            onTap: onRename,
          ),
          if (onAddToCase != null)
            _ActionChip(
              icon: Icons.cases_rounded,
              label: l.addToCase,
              color: VetoPalette.accentSky,
              onTap: onAddToCase!,
            ),
          _ActionChip(
            icon: Icons.delete_outline_rounded,
            label: l.delete,
            color: VetoPalette.emergency,
            onTap: onDelete,
          ),
          if (file.caseId != null)
            _ActionChip(
              icon: Icons.link_off_rounded,
              label: l.removeFromCase,
              color: VetoPalette.warning,
              onTap: onRemoveFromCase,
            ),
        ]),
      ]),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon, required this.label,
    required this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onTap == null ? 0.04 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: onTap == null ? color.withValues(alpha: 0.4) : color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            color: onTap == null ? color.withValues(alpha: 0.4) : color,
            fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Case card widget ─────────────────────────────────────────
class _CaseCard extends StatelessWidget {
  final _LegalCase legalCase;
  final List<_VaultFile> files;
  final _L l;
  final VoidCallback onRename, onDelete;

  const _CaseCard({
    required this.legalCase, required this.files, required this.l,
    required this.onRename, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cases_rounded,
                color: VetoPalette.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(legalCase.name, style: const TextStyle(
                  color: VetoPalette.text, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                '${files.length} ${l.files}  ·  '
                '${legalCase.createdAt.day}/${legalCase.createdAt.month}/${legalCase.createdAt.year}',
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12),
              ),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 18, color: VetoPalette.textMuted),
            onPressed: onRename,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 12),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: VetoPalette.emergency),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 12),
          ),
        ]),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...files.take(3).map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(f.icon, size: 14, color: f.typeColor),
              const SizedBox(width: 8),
              Expanded(child: Text(f.name,
                  style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(f.sizeLabel,
                  style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
            ]),
          )),
          if (files.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${files.length - 3} more',
                  style: const TextStyle(
                      color: VetoPalette.primary, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ]),
    );
  }
}
