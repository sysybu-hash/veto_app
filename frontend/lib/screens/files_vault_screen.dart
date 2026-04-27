// ============================================================
//  FilesVaultScreen.dart — Per-user encrypted file vault
//  Features: upload, AI analysis, legal case prep,
//            lawyer access sharing, 100 MB quota, compression
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/vault_save_queue.dart';
import '../platform/browser_bridge.dart' as browser_bridge;

// ── i18n strings ─────────────────────────────────────────────
class _L {
  final String title, upload, uploading, analyzing, deleteConfirm, delete,
      share, revoke, analyze, noFiles, usageOf, used, quota, legalCase,
      caseName, createCase, addToCase, files, allFiles, caseFiles,
      shareWithLawyer, lawyerAccess, fileType, size, date, status,
      aiSummary, aiBtn, cancel, save, errorUpload, successUpload,
      successDelete, successShare, compressing, caseCreated, loading,
      rename, fileName,       successRename,
      deleteCase, deleteCaseConfirm, successDeleteCase,
      removeFromCase,
      folders, newFolder, folderName, moveToFolder, rootVault, deleteFolder,
      deleteFolderConfirm, folderNotEmpty, goUp, openFolder;

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
    required this.folders, required this.newFolder, required this.folderName,
    required this.moveToFolder, required this.rootVault, required this.deleteFolder,
    required this.deleteFolderConfirm, required this.folderNotEmpty, required this.goUp,
    required this.openFolder,
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
  folders: 'תיקיות', newFolder: 'תיקייה חדשה', folderName: 'שם התיקייה',
  moveToFolder: 'העבר לתיקייה', rootVault: 'כספת', deleteFolder: 'מחק תיקייה',
  deleteFolderConfirm: 'למחוק את התיקייה? (רק אם ריקה)', folderNotEmpty: 'התיקייה אינה ריקה',
  goUp: 'הקודם', openFolder: 'פתח',
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
  folders: 'Folders', newFolder: 'New folder', folderName: 'Folder name',
  moveToFolder: 'Move to folder', rootVault: 'Vault', deleteFolder: 'Delete folder',
  deleteFolderConfirm: 'Delete this folder? (only if empty)', folderNotEmpty: 'Folder is not empty',
  goUp: 'Up', openFolder: 'Open',
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
  folders: 'Папки', newFolder: 'Новая папка', folderName: 'Имя папки',
  moveToFolder: 'Переместить', rootVault: 'Хранилище', deleteFolder: 'Удалить папку',
  deleteFolderConfirm: 'Удалить папку? (только пустая)', folderNotEmpty: 'Папка не пуста',
  goUp: 'Назад', openFolder: 'Открыть',
);

// ── Data models ───────────────────────────────────────────────
class _VaultFile {
  final String id, name, type, url, status;
  final int sizeBytes;
  final DateTime uploadedAt;
  final bool lawyerAccess;
  final String? aiSummary, caseId, folderId;

  const _VaultFile({
    required this.id, required this.name, required this.type,
    required this.url, required this.status, required this.sizeBytes,
    required this.uploadedAt, required this.lawyerAccess,
    this.aiSummary, this.caseId, this.folderId,
  });

  factory _VaultFile.fromJson(Map<String, dynamic> j) {
    final raw = j['folderId'];
    String? fid;
    if (raw == null) {
      fid = null;
    } else if (raw is String) {
      fid = raw.isEmpty ? null : raw;
    } else {
      fid = raw.toString();
    }
    return _VaultFile(
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
    folderId: fid,
  );
  }

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

class _VaultFolder {
  final String id, name;
  final String? parentId;
  const _VaultFolder({
    required this.id, required this.name, this.parentId,
  });
  factory _VaultFolder.fromJson(Map<String, dynamic> j) {
    final p = j['parentId'];
    return _VaultFolder(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: (j['name'] ?? 'folder').toString(),
      parentId: p?.toString(),
    );
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
  List<_VaultFolder> _folders = [];
  List<_LegalCase> _cases = [];
  /// Breadcrumb: first is always root; last is current folder (id null = vault root).
  final List<({String? id, String name})> _folderPath = [
    (id: null, name: ''), // name filled from _l.rootVault in build
  ];
  bool _loading = true;
  bool _uploading = false;
  bool _analyzing = false;
  bool _isDragging = false;
  String? _activeFileId;

  late TabController _tabController;
  VaultSaveQueue? _queue;
  void Function()? _queueListRefresh;

  double get _usedMb =>
      _files.fold(0.0, (s, f) => s + f.sizeBytes) / (1024 * 1024);
  double get _quotaMb => 100.0;

  String? get _currentFolderId =>
      _folderPath.isEmpty ? null : _folderPath.last.id;

  List<_VaultFolder> get _subfolders {
    final cur = _currentFolderId;
    final out = _folders.where((f) {
      final p = f.parentId;
      if (cur == null || cur.isEmpty) {
        return p == null || p.isEmpty;
      }
      return p == cur;
    }).toList();
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  List<_VaultFile> get _filesHere {
    final cur = _currentFolderId;
    return _files.where((f) {
      final fid = f.folderId;
      if (cur == null || cur.isEmpty) {
        return fid == null || fid.isEmpty;
      }
      return fid == cur;
    }).toList();
  }

  void _goFolderUp() {
    if (_folderPath.length <= 1) return;
    setState(() {
      _folderPath.removeLast();
    });
  }

  void _openFolder(_VaultFolder f) {
    setState(() {
      _folderPath.add((id: f.id, name: f.name));
    });
  }

  Future<void> _createSubfolder() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoGlassTokens.sheetPanel,
        title: Text(_l.newFolder, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: _l.folderName,
            labelStyle: const TextStyle(color: VetoGlassTokens.textMuted),
          ),
          style: const TextStyle(color: VetoGlassTokens.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_l.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/vault/folders'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
            body: jsonEncode({
              'name': name,
              'parentId': _currentFolderId,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 201 || res.statusCode == 200) {
        await _load();
      } else {
        _snack(_l.errorUpload, isError: true);
      }
    } catch (_) {
      _snack(_l.errorUpload, isError: true);
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _removeFolder(_VaultFolder f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoGlassTokens.sheetPanel,
        title: Text(_l.deleteFolder, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
        content: Text(_l.deleteFolderConfirm, style: const TextStyle(color: VetoGlassTokens.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency, foregroundColor: Colors.white),
            child: Text(_l.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http
          .delete(
            Uri.parse('${AppConfig.baseUrl}/vault/folders/${f.id}'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        if (_currentFolderId == f.id) {
          _goFolderUp();
        }
        _folderPath.removeWhere((s) => s.id == f.id);
        await _load();
        return;
      }
      if (res.statusCode == 400) {
        _snack(_l.folderNotEmpty, isError: true);
        return;
      }
      _snack(_l.errorUpload, isError: true);
    } catch (_) {
      _snack(_l.errorUpload, isError: true);
    }
  }

  Future<void> _moveFileToFolder(_VaultFile file) async {
    String? targetId; // null = root
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: VetoGlassTokens.sheetPanel,
          title: Text(_l.moveToFolder, style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: VetoGlassTokens.neonCyan),
                  title: Text(_l.rootVault, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
                  onTap: () {
                    targetId = 'ROOT';
                    Navigator.pop(ctx);
                  },
                ),
                ..._folders.map((g) {
                  if (g.id == file.folderId) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined, color: VetoGlassTokens.textMuted),
                    title: Text(
                      g.name,
                      style: const TextStyle(color: VetoGlassTokens.textPrimary),
                      maxLines: 1,
                    ),
                    onTap: () {
                      targetId = g.id;
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                targetId = '__cancel__';
                Navigator.pop(ctx);
              },
              child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted)),
            ),
          ],
        );
      },
    );
    if (targetId == null || targetId == '__cancel__') return;
    final payload = <String, dynamic>{};
    if (targetId == 'ROOT') {
      payload['folderId'] = null;
    } else {
      payload['folderId'] = targetId;
    }
    try {
      final tok = await _token;
      if (tok == null) return;
      final res = await http
          .patch(
            Uri.parse('${AppConfig.baseUrl}/vault/files/${file.id}'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        await _load();
      } else {
        _snack(_l.errorUpload, isError: true);
      }
    } catch (_) {
      _snack(_l.errorUpload, isError: true);
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _queue = context.read<VaultSaveQueue>();
      _queueListRefresh = () {
        if (mounted) {
          unawaited(_load());
        }
      };
      _queue!.listRefresh.addListener(_queueListRefresh!);
    });
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
    if (_queueListRefresh != null) {
      _queue?.listRefresh.removeListener(_queueListRefresh!);
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> get _token async => _auth.getToken();

  // ── Drag & drop (web) ────────────────────────────────────────
  // ── Drag & drop (web handlers moved to bridge) ────────────────

  Future<void> _uploadHtmlFile(dynamic file) async {
    if (_usedMb >= _quotaMb) { _snack(_l.quota, isError: true); return; }
    if (!mounted) return;
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
      final pfo = _currentFolderId;
      if (pfo != null && pfo.isNotEmpty) {
        req.fields['folderId'] = pfo;
      }

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
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: VetoGlassTokens.glassBorder)),
        insetPadding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: VetoGlassTokens.glassBorder))),
            child: Row(children: [
              Icon(file.icon, color: file.typeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(file.name,
                  style: const TextStyle(color: VetoGlassTokens.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: VetoGlassTokens.textMuted),
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
                        size: 80, color: VetoGlassTokens.textMuted),
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
              const Icon(Icons.storage_rounded, size: 12, color: VetoGlassTokens.textMuted),
              const SizedBox(width: 4),
              Text(file.sizeLabel,
                  style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: VetoGlassTokens.textMuted),
              const SizedBox(width: 4),
              Text(
                '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12),
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
                    foregroundColor: VetoGlassTokens.neonCyan,
                    side: const BorderSide(color: VetoGlassTokens.neonCyan),
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
    if (!mounted) return;
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
      final foldersRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/vault/folders'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 15));
      if (foldersRes.statusCode == 200) {
        final data = jsonDecode(foldersRes.body);
        final list = data is List ? data : (data['folders'] ?? []);
        _folders = (list as List).map((e) => _VaultFolder.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (casesRes.statusCode == 200) {
        final data = jsonDecode(casesRes.body);
        final list = data is List ? data : (data['cases'] ?? []);
        _cases = (list as List).map((e) => _LegalCase.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
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
      final pfo = _currentFolderId;
      if (pfo != null && pfo.isNotEmpty) {
        req.fields['folderId'] = pfo;
      }

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
    if (!mounted) return;
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
      } else if (res.statusCode == 401) {
        if (kIsWeb) {
          debugPrint('vault analyze 401: sign in again or file not owned by this user');
        }
        _snack('נדרש להתחבר מחדש (או אין גישה לקובץ)', isError: true);
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() { _analyzing = false; _activeFileId = null; });
    }
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder)),
        title: Text(_l.deleteConfirm,
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(file.name,
            style: const TextStyle(color: VetoGlassTokens.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: VetoPalette.emergency, foregroundColor: Colors.white),
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder)),
        title: Text(_l.rename,
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: VetoGlassTokens.textPrimary),
          cursorColor: VetoGlassTokens.neonCyan,
          decoration: InputDecoration(
            hintText: _l.fileName,
            hintStyle: const TextStyle(color: VetoGlassTokens.textMuted),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: VetoGlassTokens.neonCyan, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: VetoGlassTokens.neonCyan,
                foregroundColor: VetoGlassTokens.onNeon),
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder)),
        title: Text(_l.createCase,
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: VetoGlassTokens.textPrimary),
          cursorColor: VetoGlassTokens.neonCyan,
          decoration: InputDecoration(
            hintText: _l.caseName,
            hintStyle: const TextStyle(color: VetoGlassTokens.textMuted),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: VetoGlassTokens.neonCyan, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: VetoGlassTokens.neonCyan,
                foregroundColor: VetoGlassTokens.onNeon),
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder)),
        title: Text(_l.rename,
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: VetoGlassTokens.textPrimary),
          cursorColor: VetoGlassTokens.neonCyan,
          decoration: InputDecoration(
            hintText: _l.caseName,
            hintStyle: const TextStyle(color: VetoGlassTokens.textMuted),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: VetoGlassTokens.neonCyan, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: VetoGlassTokens.neonCyan,
                foregroundColor: VetoGlassTokens.onNeon),
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder)),
        title: Text(_l.deleteCase,
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(_l.deleteCaseConfirm,
            style: const TextStyle(color: VetoGlassTokens.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l.cancel, style: const TextStyle(color: VetoGlassTokens.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: VetoPalette.emergency, foregroundColor: Colors.white),
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

  Widget _buildCallSaveBanners() {
    final q = context.watch<VaultSaveQueue>();
    if (q.visibleJobs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final j in q.visibleJobs) _oneSaveBanner(j, q),
        ],
      ),
    );
  }

  Widget _oneSaveBanner(VaultSaveJob j, VaultSaveQueue q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: VetoGlassTokens.glassBorder.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: j.error == null
              ? null
              : () {
                  q.dismissJob(j.id);
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      j.error != null
                          ? Icons.error_outline_rounded
                          : (j.isDone
                              ? Icons.check_circle_outline_rounded
                              : Icons.cloud_upload_outlined),
                      size: 18,
                      color: j.error != null
                          ? VetoPalette.emergency
                          : VetoGlassTokens.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        j.label,
                        style: const TextStyle(
                          color: VetoGlassTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (j.error != null)
                      IconButton(
                        onPressed: () => q.dismissJob(j.id),
                        icon: const Icon(Icons.close, size: 18),
                        color: VetoGlassTokens.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  j.error ?? j.statusLine,
                  style: TextStyle(
                    color: j.error != null
                        ? VetoPalette.emergency
                        : VetoGlassTokens.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!j.isDone && j.error == null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: j.progress,
                      minHeight: 4,
                      backgroundColor: VetoGlassTokens.glassBorder,
                      color: VetoGlassTokens.neonCyan,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        appBar: AppBar(
          backgroundColor: const Color(0x18FFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoGlassTokens.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_l.title, style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          actions: [
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.photo_camera_outlined, color: VetoGlassTokens.textPrimary),
                onPressed: _uploading ? null : _captureFromCamera,
                tooltip: 'Capture from camera',
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: VetoGlassTokens.textPrimary),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: VetoGlassTokens.neonCyan,
            labelColor: VetoGlassTokens.neonCyan,
            unselectedLabelColor: VetoGlassTokens.textMuted,
            tabs: [
              Tab(text: _l.allFiles),
              Tab(text: _l.legalCase),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploading ? null : _pickFile,
          backgroundColor: _uploading ? VetoGlassTokens.textMuted.withValues(alpha: 0.35) : VetoGlassTokens.neonBlue,
          icon: _uploading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VetoGlassTokens.onNeon))
              : const Icon(Icons.upload_file_rounded, color: VetoGlassTokens.onNeon),
          label: Text(_uploading ? _l.uploading : _l.upload,
              style: const TextStyle(color: VetoGlassTokens.onNeon, fontWeight: FontWeight.w700)),
        ),
        body: VetoGlassAuroraBackground(
          child: Stack(children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan))
              : Column(children: [
                  _buildCallSaveBanners(),
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
                color: VetoGlassTokens.neonCyan.withValues(alpha: 0.12),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: VetoGlassTokens.neonBlue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: VetoGlassTokens.neonCyan, width: 2),
                      ),
                      child: const Icon(Icons.upload_file_rounded,
                          size: 60, color: VetoGlassTokens.neonCyan),
                    ),
                    const SizedBox(height: 20),
                    const Text('Drop files here',
                        style: TextStyle(color: VetoGlassTokens.neonCyan,
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
        ]),
        ),
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
        color: VetoGlassTokens.glassFillStrong,
        border: Border(bottom: BorderSide(color: VetoGlassTokens.glassBorder)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_l.usageOf,
              style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 13)),
          Text('${_usedMb.toStringAsFixed(1)} ${_l.used}${_l.quota}',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${_files.length} ${_l.files}',
              style: const TextStyle(color: VetoGlassTokens.textSubtle, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: const Color(0xFF0F1A24),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }

  Widget _buildAllFilesTab() {
    final subs = _subfolders;
    final here = _filesHere;
    final isEmpty = subs.isEmpty && here.isEmpty;
    if (isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFolderBreadcrumb(),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: _createSubfolder,
                child: Text(_l.newFolder),
              ),
              const SizedBox(width: 8),
              if (_folderPath.length > 1)
                OutlinedButton(
                  onPressed: _goFolderUp,
                  child: Text(_l.goUp),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open_outlined,
                  size: 64, color: VetoGlassTokens.textSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(_l.noFiles,
                  style: const TextStyle(color: VetoGlassTokens.textMuted,
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(_l.upload,
                  style: const TextStyle(color: VetoGlassTokens.textSubtle, fontSize: 13)),
            ]),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFolderBreadcrumb(),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: _createSubfolder,
              child: Text(_l.newFolder),
            ),
            const SizedBox(width: 8),
            if (_folderPath.length > 1)
              OutlinedButton(
                onPressed: _goFolderUp,
                child: Text(_l.goUp),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...subs.map(
          (fo) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FolderListTile(
              name: fo.name,
              l: _l,
              onOpen: () => _openFolder(fo),
              onDelete: () => _removeFolder(fo),
            ),
          ),
        ),
        if (here.isNotEmpty) const SizedBox(height: 4),
        ...here.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FileCard(
              file: f,
              l: _l,
              isAnalyzing: _analyzing && _activeFileId == f.id,
              onAnalyze: () => _analyzeFile(f),
              onDelete: () => _deleteFile(f),
              onToggleAccess: () => _toggleLawyerAccess(f),
              onRename: () => _renameFile(f),
              onAddToCase: _cases.isEmpty ? null : () => _showAddToCase(f),
              onRemoveFromCase: f.caseId == null ? null : () => _removeFromCase(f),
              onMoveToFolder: (_folders.isNotEmpty ||
                      (f.folderId != null && f.folderId!.isNotEmpty))
                  ? () => unawaited(_moveFileToFolder(f))
                  : null,
              onPreview: () => _showPreview(f),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderBreadcrumb() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _folderPath.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16, color: VetoGlassTokens.textMuted),
              ),
            InkWell(
              onTap: i < _folderPath.length - 1
                  ? () {
                      setState(() {
                        while (_folderPath.length > i + 1) {
                          _folderPath.removeLast();
                        }
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  (i == 0 && _folderPath[i].name.isEmpty) ? _l.rootVault : _folderPath[i].name,
                  style: TextStyle(
                    color: i == _folderPath.length - 1
                        ? VetoGlassTokens.neonCyan
                        : VetoGlassTokens.textPrimary,
                    fontWeight: i == _folderPath.length - 1 ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
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
                  color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700, fontSize: 16))),
          TextButton.icon(
            onPressed: _createCase,
            icon: const Icon(Icons.create_new_folder_outlined,
                size: 18, color: VetoGlassTokens.neonCyan),
            label: Text(_l.createCase,
                style: const TextStyle(color: VetoGlassTokens.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      if (_cases.isEmpty)
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cases_outlined,
                  size: 64, color: VetoGlassTokens.textSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(_l.createCase,
                  style: const TextStyle(color: VetoGlassTokens.textMuted,
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
      backgroundColor: VetoGlassTokens.sheetPanel,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: VetoGlassTokens.glassBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(_l.addToCase,
              style: const TextStyle(color: VetoGlassTokens.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ..._cases.map((c) => ListTile(
          leading: const Icon(Icons.cases_rounded, color: VetoGlassTokens.neonCyan),
          title: Text(c.name, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
          subtitle: Text('${c.fileIds.length} ${_l.files}',
              style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12)),
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

class _FolderListTile extends StatelessWidget {
  const _FolderListTile({
    required this.name,
    required this.l,
    required this.onOpen,
    required this.onDelete,
  });
  final String name;
  final _L l;
  final VoidCallback onOpen, onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VetoGlassTokens.glassFillStrong,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VetoGlassTokens.glassBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_rounded, color: VetoGlassTokens.neonCyan, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: VetoGlassTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onOpen,
                child: Text(l.openFolder),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: VetoPalette.emergency, size: 20),
                onPressed: onDelete,
                tooltip: l.deleteFolder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── File card widget ─────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final _VaultFile file;
  final _L l;
  final bool isAnalyzing;
  final VoidCallback onAnalyze, onDelete, onToggleAccess, onRename;
  final VoidCallback? onAddToCase, onRemoveFromCase, onMoveToFolder;
  final VoidCallback? onPreview;

  const _FileCard({
    required this.file, required this.l, required this.isAnalyzing,
    required this.onAnalyze, required this.onDelete,
    required this.onToggleAccess, required this.onRename,
    this.onAddToCase, this.onRemoveFromCase, this.onMoveToFolder, this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoGlassTokens.glassBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20, offset: const Offset(0, 8))],
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
                  color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700,
                  fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${file.sizeLabel}  ·  '
                  '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                  style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12)),
            ],
          )),
          if (onPreview != null)
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              color: VetoGlassTokens.textMuted,
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
              color: VetoGlassTokens.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 14, color: VetoGlassTokens.neonCyan),
              const SizedBox(width: 6),
              Expanded(child: Text(file.aiSummary!,
                  style: const TextStyle(
                      color: VetoGlassTokens.textPrimary, fontSize: 12, height: 1.5),
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
            color: VetoGlassTokens.neonCyan,
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
            color: VetoGlassTokens.textSubtle,
            onTap: onRename,
          ),
          if (onAddToCase != null)
            _ActionChip(
              icon: Icons.cases_rounded,
              label: l.addToCase,
              color: VetoGlassTokens.accentSoft,
              onTap: onAddToCase!,
            ),
          if (onMoveToFolder != null)
            _ActionChip(
              icon: Icons.drive_file_move_rounded,
              label: l.moveToFolder,
              color: VetoPalette.info,
              onTap: onMoveToFolder!,
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
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoGlassTokens.glassBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VetoGlassTokens.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cases_rounded,
                color: VetoGlassTokens.neonCyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(legalCase.name, style: const TextStyle(
                  color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                '${files.length} ${l.files}  ·  '
                '${legalCase.createdAt.day}/${legalCase.createdAt.month}/${legalCase.createdAt.year}',
                style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12),
              ),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 18, color: VetoGlassTokens.textMuted),
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
          const Divider(height: 1, color: VetoGlassTokens.glassBorder),
          const SizedBox(height: 8),
          ...files.take(3).map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(f.icon, size: 14, color: f.typeColor),
              const SizedBox(width: 8),
              Expanded(child: Text(f.name,
                  style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(f.sizeLabel,
                  style: const TextStyle(color: VetoGlassTokens.textSubtle, fontSize: 11)),
            ]),
          )),
          if (files.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${files.length - 3} more',
                  style: const TextStyle(
                      color: VetoGlassTokens.neonCyan, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ]),
    );
  }
}
