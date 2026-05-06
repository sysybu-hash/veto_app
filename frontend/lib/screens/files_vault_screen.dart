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
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../services/auth_service.dart';
import '../services/vault_save_queue.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../widgets/citizen_mockup_shell.dart';

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
      deleteFolderConfirm, folderNotEmpty, goUp, openFolder,
      dropFilesHere, uploadZoneTitle, uploadZoneHint;

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
    required this.dropFilesHere, required this.uploadZoneTitle, required this.uploadZoneHint,
  });
}

const _he = _L(
  title: 'הכספת שלך', upload: 'העלה קובץ', uploading: 'מעלה...',
  analyzing: 'AI מנתח...', deleteConfirm: 'למחוק את הקובץ?',
  delete: 'מחק', share: 'שתף עם עו"ד', revoke: 'בטל גישה',
  analyze: 'נתח עם AI', noFiles: 'אין קבצים עדיין',
  usageOf: 'בשימוש: ', used: 'GB', quota: ' / 10 GB',
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
  dropFilesHere: 'שחררו כאן לטעינה',
  uploadZoneTitle: 'העלאה מהירה',
  uploadZoneHint: 'במובייל: "העלה" או מצלמה. בווב: גרירה לכאן או לכל מקום על המסך.',
);

const _en = _L(
  title: 'Your Vault', upload: 'Upload File', uploading: 'Uploading...',
  analyzing: 'AI analyzing...', deleteConfirm: 'Delete this file?',
  delete: 'Delete', share: 'Share with Lawyer', revoke: 'Revoke Access',
  analyze: 'Analyze with AI', noFiles: 'No files yet',
  usageOf: 'Used: ', used: 'GB', quota: ' / 10 GB',
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
  dropFilesHere: 'Drop to upload',
  uploadZoneTitle: 'Quick upload',
  uploadZoneHint: 'Mobile: use Upload or camera. Web: drag files here or anywhere on the page.',
);

const _ru = _L(
  title: 'Моё хранилище', upload: 'Загрузить файл', uploading: 'Загрузка...',
  analyzing: 'AI анализирует...', deleteConfirm: 'Удалить файл?',
  delete: 'Удалить', share: 'Поделиться с адвокатом', revoke: 'Закрыть доступ',
  analyze: 'Анализ AI', noFiles: 'Файлов пока нет',
  usageOf: 'Использовано: ', used: 'ГБ', quota: ' / 10 ГБ',
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
  dropFilesHere: 'Отпустите для загрузки',
  uploadZoneTitle: 'Быстрая загрузка',
  uploadZoneHint: 'Телефон: кнопка загрузки или камера. Веб: перетащите сюда или в любую область.',
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
    if (type.startsWith('image/')) return V26.navy500;
    if (type.startsWith('video/')) return const Color(0xFF2ECC71);
    if (type.startsWith('audio/')) return V26.navy500;
    if (type.contains('pdf')) return V26.emerg;
    return V26.ink500;
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
  late final Future<String?> _vaultRoleFuture = _auth.getStoredRole();

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

  /// VETO 2026 — 10 GB tier (mirrors `2026/vault.html`).
  /// Value is in MB for backwards compat with existing upload checks.
  double get _usedMb =>
      _files.fold(0.0, (s, f) => s + f.sizeBytes) / (1024 * 1024);
  double get _quotaMb => 10 * 1024.0; // 10 GB
  double get _usedGb => _usedMb / 1024.0;
  double get _quotaGb => _quotaMb / 1024.0;

  /// Which category tab is active in the new 2026 layout.
  /// 0 = all · 1 = documents · 2 = audio · 3 = video · 4 = images
  int _category = 0;

  Iterable<_VaultFile> _filteredByCategory(Iterable<_VaultFile> files) {
    switch (_category) {
      case 1: // documents
        return files.where((f) =>
            f.type.contains('pdf') ||
            f.type.contains('word') ||
            f.type.contains('document') ||
            f.type.contains('text/'));
      case 2: // audio
        return files.where((f) => f.type.startsWith('audio/'));
      case 3: // video
        return files.where((f) => f.type.startsWith('video/'));
      case 4: // images
        return files.where((f) => f.type.startsWith('image/'));
      default:
        return files;
    }
  }

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
        backgroundColor: V26.surface,
        title: Text(_l.newFolder, style: const TextStyle(color: V26.ink900)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: _l.folderName,
            labelStyle: const TextStyle(color: V26.ink500),
          ),
          style: const TextStyle(color: V26.ink900),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l.cancel, style: const TextStyle(color: V26.ink500)),
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

  // ignore: unused_element
  Future<void> _removeFolder(_VaultFolder f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: V26.surface,
        title: Text(_l.deleteFolder, style: const TextStyle(color: V26.ink900)),
        content: Text(_l.deleteFolderConfirm, style: const TextStyle(color: V26.ink500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l.cancel, style: const TextStyle(color: V26.ink500)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: V26.emerg, foregroundColor: Colors.white),
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
          backgroundColor: V26.surface,
          title: Text(_l.moveToFolder, style: const TextStyle(color: V26.ink900, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: V26.navy600),
                  title: Text(_l.rootVault, style: const TextStyle(color: V26.ink900)),
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
                    leading: const Icon(Icons.folder_outlined, color: V26.ink500),
                    title: Text(
                      g.name,
                      style: const TextStyle(color: V26.ink900),
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
              child: Text(_l.cancel, style: const TextStyle(color: V26.ink500)),
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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: V26.hairline)),
        insetPadding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: V26.hairline))),
            child: Row(children: [
              Icon(file.icon, color: file.typeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(file.name,
                  style: const TextStyle(color: V26.ink900,
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: V26.ink500),
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
                        size: 80, color: V26.ink500),
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
              const Icon(Icons.storage_rounded, size: 12, color: V26.ink500),
              const SizedBox(width: 4),
              Text(file.sizeLabel,
                  style: const TextStyle(color: V26.ink500, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: V26.ink500),
              const SizedBox(width: 4),
              Text(
                '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                style: const TextStyle(color: V26.ink500, fontSize: 12),
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
                    foregroundColor: V26.navy600,
                    side: const BorderSide(color: V26.navy600),
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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline)),
        title: Text(_l.deleteConfirm,
            style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700)),
        content: Text(file.name,
            style: const TextStyle(color: V26.ink500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l.cancel, style: const TextStyle(color: V26.ink500))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: V26.emerg, foregroundColor: Colors.white),
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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline)),
        title: Text(_l.rename,
            style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: V26.ink900),
          cursorColor: V26.navy600,
          decoration: InputDecoration(
            hintText: _l.fileName,
            hintStyle: const TextStyle(color: V26.ink500),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: V26.navy600, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: V26.ink500))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white),
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


  // ignore: unused_element
  Future<void> _createCase() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline)),
        title: Text(_l.createCase,
            style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: V26.ink900),
          cursorColor: V26.navy600,
          decoration: InputDecoration(
            hintText: _l.caseName,
            hintStyle: const TextStyle(color: V26.ink500),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: V26.navy600, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: V26.ink500))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white),
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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline)),
        title: Text(_l.rename,
            style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: V26.ink900),
          cursorColor: V26.navy600,
          decoration: InputDecoration(
            hintText: _l.caseName,
            hintStyle: const TextStyle(color: V26.ink500),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: V26.navy600, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_l.cancel, style: const TextStyle(color: V26.ink500))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white),
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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline)),
        title: Text(_l.deleteCase,
            style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700)),
        content: Text(_l.deleteCaseConfirm,
            style: const TextStyle(color: V26.ink500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l.cancel, style: const TextStyle(color: V26.ink500))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: V26.emerg, foregroundColor: Colors.white),
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
      backgroundColor: isError ? V26.emerg : V26.ok,
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
        color: V26.hairline.withValues(alpha: 0.25),
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
                          ? V26.emerg
                          : V26.navy600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        j.label,
                        style: const TextStyle(
                          color: V26.ink900,
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
                        color: V26.ink500,
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
                        ? V26.emerg
                        : V26.ink500,
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
                      backgroundColor: V26.hairline,
                      color: V26.navy600,
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

  Widget _vaultLayerStack() {
    return Stack(
      children: [
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: V26.navy600))
            : _build2026Body(),
        if (_isDragging)
          IgnorePointer(
            child: Container(
              color: V26.navy600.withValues(alpha: 0.08),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: V26.navy500.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: V26.navy600, width: 2),
                      ),
                      child: const Icon(Icons.upload_file_rounded,
                          size: 60, color: V26.navy600),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _l.dropFilesHere,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: V26.navy600,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;
    final isWide = MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    final uploadLabel = _uploading ? _l.uploading : _l.upload;

    return FutureBuilder<String?>(
      future: _vaultRoleFuture,
      builder: (context, snap) {
        final citizenChrome = snap.data == 'user';
        final stackChild = _vaultLayerStack();

        final mobileAppBar = AppBar(
          backgroundColor: citizenChrome ? VetoMockup.surfaceCard : V26.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: citizenChrome ? VetoMockup.ink : V26.ink900, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            _l.title,
            style: TextStyle(
              color: citizenChrome ? VetoMockup.ink : V26.ink900,
              fontFamily: V26.serif,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            if (kIsWeb)
              IconButton(
                icon: Icon(Icons.photo_camera_outlined,
                    color: citizenChrome ? VetoMockup.inkSecondary : V26.ink700),
                onPressed: _uploading ? null : _captureFromCamera,
                tooltip: 'Capture from camera',
              ),
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: citizenChrome ? VetoMockup.inkSecondary : V26.ink700),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ],
        );

        if (citizenChrome) {
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: CitizenMockupShell(
              currentRoute: '/files_vault',
              mobileNavIndex: 3,
              mobileAppBar: mobileAppBar,
              desktopTrailing: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: VetoMockup.ink),
                  tooltip: code == 'he' ? 'חיפוש' : 'Search',
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickFile,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                  label: Text(
                    uploadLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoMockup.primaryCta,
                    disabledBackgroundColor:
                        VetoMockup.inkSecondary.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(VetoMockup.radiusButton),
                    ),
                  ),
                ),
              ],
              floatingActionButton: isWide
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: _uploading ? null : _pickFile,
                      backgroundColor: _uploading
                          ? VetoMockup.inkSecondary.withValues(alpha: 0.35)
                          : VetoMockup.primaryCta,
                      icon: _uploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload_file_rounded,
                              color: Colors.white),
                      label: Text(
                        uploadLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
              child: stackChild,
            ),
          );
        }

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: V26AppShell(
            destinations: isWide
                ? V26CitizenNav.destinations(code)
                : V26CitizenNav.bottomDestinations(code),
            currentIndex: isWide ? 2 /* כספת */ : 2 /* קבצים */,
            onDestinationSelected: (i) {
              final routes = isWide
                  ? V26CitizenNav.routes
                  : V26CitizenNav.bottomRoutes;
              V26CitizenNav.go(context, routes[i], current: '/files_vault');
            },
            desktopStatusText: code == 'he'
                ? 'מאובטח · מוצפן E2E · נשמר במכשיר ובכספת מוצפנת'
                : (code == 'ru'
                    ? 'Безопасно · E2E шифрование'
                    : 'Secured · E2E encrypted · stored on-device & in encrypted vault'),
            desktopTrailing: [
              V26IconBtn(
                icon: Icons.search_rounded,
                onTap: () {},
                tooltip: code == 'he' ? 'חיפוש' : 'Search',
              ),
              const SizedBox(width: 8),
              V26PillCTA(
                label: uploadLabel,
                icon: _uploading ? Icons.hourglass_empty_rounded : Icons.add,
                onTap: _uploading ? null : _pickFile,
              ),
            ],
            mobileAppBar: mobileAppBar,
            floatingAction: isWide
                ? null
                : FloatingActionButton.extended(
                    onPressed: _uploading ? null : _pickFile,
                    backgroundColor: _uploading
                        ? V26.ink500.withValues(alpha: 0.35)
                        : V26.navy600,
                    icon: _uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_file_rounded,
                            color: Colors.white),
                    label: Text(
                      uploadLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
            child: stackChild,
          ),
        );
      },
    );
  }

  // ── VETO 2026 body (matches `2026/vault.html`) ──────────────
  Widget _build2026Body() {
    final code = context.read<AppLanguageController>().code;
    final isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    // Compose main content scroll area.
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 28 : 16,
        vertical: isWide ? 24 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCallSaveBanners(),
          // Header (kicker + headline + sub-line + tabs)
          _buildVaultHeader(code, isWide),
          const SizedBox(height: 18),
          // Storage indicator card
          _buildStorageCard(code),
          const SizedBox(height: 18),
          // Folder breadcrumb (if not at root)
          if (_folderPath.length > 1) ...[
            _buildFolderBreadcrumb(),
            const SizedBox(height: 12),
          ],
          // Subfolders strip
          if (_subfolders.isNotEmpty) ...[
            _buildFoldersStrip(),
            const SizedBox(height: 18),
          ],
          // File grid
          _build2026Grid(isWide),
          const SizedBox(height: 28),
          // Cases section — kept as secondary area
          if (_cases.isNotEmpty) ...[
            _buildCasesSection(code),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildVaultHeader(String code, bool isWide) {
    final he = code == 'he';
    final ru = code == 'ru';
    final kicker = he
        ? 'מאובטח · מוצפן E2E'
        : (ru ? 'Безопасно · E2E' : 'Secured · E2E Encrypted');
    final subline = he
        ? '${_files.length} קבצים · ${_usedGb.toStringAsFixed(1)} GB מתוך ${_quotaGb.toStringAsFixed(0)} GB · נשמר אך ורק במכשיר ובכספת המוצפנת שלך'
        : (ru
            ? '${_files.length} файлов · ${_usedGb.toStringAsFixed(1)} GB из ${_quotaGb.toStringAsFixed(0)} GB · хранится только на устройстве и в зашифрованном хранилище'
            : '${_files.length} files · ${_usedGb.toStringAsFixed(1)} GB of ${_quotaGb.toStringAsFixed(0)} GB · stored only on your device and in your encrypted vault');

    final tabLabels = he
        ? const ['הכל', 'מסמכים', 'שמע', 'וידאו', 'תמונות']
        : (ru
            ? const ['Все', 'Документы', 'Аудио', 'Видео', 'Фото']
            : const ['All', 'Documents', 'Audio', 'Video', 'Photos']);

    final headerText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        V26Kicker(kicker),
        const SizedBox(height: 4),
        V26Headline(_l.title, size: isWide ? 26 : 22, weight: FontWeight.w800),
        const SizedBox(height: 6),
        Text(
          subline,
          style: const TextStyle(
            fontFamily: V26.sans,
            fontSize: 13,
            color: V26.ink500,
            height: 1.45,
          ),
        ),
      ],
    );

    final tabs = V26Tabs(
      labels: tabLabels,
      current: _category,
      onChanged: (i) => setState(() => _category = i),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: headerText),
          const SizedBox(width: 20),
          Align(alignment: Alignment.centerRight, child: tabs),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerText,
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: tabs,
        ),
      ],
    );
  }

  Widget _buildStorageCard(String code) {
    final pct = (_usedMb / _quotaMb).clamp(0.0, 1.0);
    final he = code == 'he';
    final ru = code == 'ru';
    final usedLabel = he
        ? '${_usedGb.toStringAsFixed(1)} GB מנוצל מתוך ${_quotaGb.toStringAsFixed(0)} GB'
        : (ru
            ? '${_usedGb.toStringAsFixed(1)} GB из ${_quotaGb.toStringAsFixed(0)} GB'
            : '${_usedGb.toStringAsFixed(1)} GB of ${_quotaGb.toStringAsFixed(0)} GB used');
    final subLabel = he
        ? '${_files.length} קבצים · הצפנה AES-256 בכל קובץ'
        : (ru
            ? '${_files.length} файлов · AES-256 шифрование'
            : '${_files.length} files · AES-256 per-file encryption');
    final upgrade = he
        ? 'שדרג תוכנית'
        : (ru ? 'Обновить план' : 'Upgrade plan');

    return V26Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [V26.navy500, V26.navy400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usedLabel,
                      style: const TextStyle(
                        fontFamily: V26.sans,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: V26.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subLabel,
                      style: const TextStyle(
                        fontFamily: V26.sans,
                        fontSize: 12,
                        color: V26.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              V26PillCTA(label: upgrade, ghost: true, onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),
          V26Progress(value: pct, height: 6),
        ],
      ),
    );
  }

  Widget _buildFoldersStrip() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _subfolders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == _subfolders.length) {
            return OutlinedButton.icon(
              onPressed: _createSubfolder,
              icon: const Icon(Icons.create_new_folder_outlined, size: 16),
              label: Text(_l.newFolder),
              style: OutlinedButton.styleFrom(
                foregroundColor: V26.navy600,
                side: const BorderSide(color: V26.hairline),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          final fo = _subfolders[i];
          return InkWell(
            onTap: () => _openFolder(fo),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: V26.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: V26.hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded,
                      color: V26.navy600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    fo.name,
                    style: const TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: V26.ink900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _build2026Grid(bool isWide) {
    final here = _filteredByCategory(_filesHere).toList();
    if (here.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: V26Empty(
          icon: Icons.folder_open_outlined,
          title: _l.noFiles,
          description: _l.upload,
          action: V26PillCTA(
            label: _l.upload,
            icon: Icons.add,
            onTap: _uploading ? null : _pickFile,
          ),
        ),
      );
    }
    final cross = isWide ? 4 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isWide ? 1.15 : 0.95,
      ),
      itemCount: here.length,
      itemBuilder: (_, i) {
        final f = here[i];
        return _Vault2026FileCard(
          file: f,
          l: _l,
          onTap: () => _showPreview(f),
          onMenu: () => _showFileActions(f),
          onLongPress: () => _showFileActions(f),
        );
      },
    );
  }

  Widget _buildCasesSection(String code) {
    final he = code == 'he';
    final ru = code == 'ru';
    final title = he
        ? 'תיקים משפטיים'
        : (ru ? 'Юридические дела' : 'Legal cases');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            V26Kicker(he ? 'תיקי תיעוד' : (ru ? 'Дела' : 'Case files')),
          ],
        ),
        const SizedBox(height: 6),
        V26Headline(title, size: 20, weight: FontWeight.w800),
        const SizedBox(height: 12),
        ..._cases.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CaseCard(
              legalCase: c,
              files: _files.where((f) => f.caseId == c.id).toList(),
              l: _l,
              onRename: () => _renameCase(c),
              onDelete: () => _deleteCase(c),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFileActions(_VaultFile f) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: V26.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: V26.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: V26.ink900,
                  ),
                ),
              ),
              const Divider(height: 1, color: V26.hairline),
              ListTile(
                leading: Icon(
                  _analyzing && _activeFileId == f.id
                      ? Icons.hourglass_empty_rounded
                      : Icons.auto_awesome,
                  color: V26.navy600,
                ),
                title: Text(
                  _analyzing && _activeFileId == f.id
                      ? _l.analyzing
                      : _l.aiBtn,
                  style: const TextStyle(color: V26.ink900),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _analyzeFile(f);
                },
              ),
              ListTile(
                leading: Icon(
                  f.lawyerAccess
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  color: f.lawyerAccess ? V26.warn : V26.ok,
                ),
                title: Text(
                  f.lawyerAccess ? _l.revoke : _l.share,
                  style: const TextStyle(color: V26.ink900),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleLawyerAccess(f);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline,
                    color: V26.ink500),
                title: Text(_l.rename,
                    style: const TextStyle(color: V26.ink900)),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameFile(f);
                },
              ),
              if (_folders.isNotEmpty ||
                  (f.folderId != null && f.folderId!.isNotEmpty))
                ListTile(
                  leading:
                      const Icon(Icons.drive_folder_upload, color: V26.ink500),
                  title: Text(_l.moveToFolder,
                      style: const TextStyle(color: V26.ink900)),
                  onTap: () {
                    Navigator.pop(ctx);
                    unawaited(_moveFileToFolder(f));
                  },
                ),
              if (_cases.isNotEmpty && f.caseId == null)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined,
                      color: V26.ink500),
                  title: Text(_l.addToCase,
                      style: const TextStyle(color: V26.ink900)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToCase(f);
                  },
                ),
              if (f.caseId != null)
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined,
                      color: V26.ink500),
                  title: Text(_l.removeFromCase,
                      style: const TextStyle(color: V26.ink900)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeFromCase(f);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: V26.emerg),
                title: Text(_l.delete,
                    style:
                        const TextStyle(color: V26.emerg)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteFile(f);
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildUploadZoneCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _uploading ? null : _pickFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: V26.navy600.withValues(alpha: 0.45),
                width: 1.5,
              ),
              color: V26.surface.withValues(alpha: 0.6),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: V26.navy500.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: V26.navy600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _l.uploadZoneTitle,
                        style: const TextStyle(
                          color: V26.ink900,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _l.uploadZoneHint,
                        style: const TextStyle(
                          color: V26.ink500,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: V26.ink300,
                ),
              ],
            ),
          ),
        ),
      ),
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
                child: Icon(Icons.chevron_right, size: 16, color: V26.ink500),
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
                        ? V26.navy600
                        : V26.ink900,
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

  Future<void> _showAddToCase(_VaultFile file) async {
    final selected = await showModalBottomSheet<_LegalCase>(
      context: context,
      backgroundColor: V26.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: V26.hairline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(_l.addToCase,
              style: const TextStyle(color: V26.ink900,
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ..._cases.map((c) => ListTile(
          leading: const Icon(Icons.cases_rounded, color: V26.navy600),
          title: Text(c.name, style: const TextStyle(color: V26.ink900)),
          subtitle: Text('${c.fileIds.length} ${_l.files}',
              style: const TextStyle(color: V26.ink500, fontSize: 12)),
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

// ignore: unused_element
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
      color: V26.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: V26.hairline),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_rounded, color: V26.navy600, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: V26.ink900,
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
                icon: const Icon(Icons.delete_outline, color: V26.emerg, size: 20),
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
// ignore: unused_element
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
    // ignore: unused_element_parameter
    this.onAddToCase,
    // ignore: unused_element_parameter
    this.onRemoveFromCase,
    // ignore: unused_element_parameter
    this.onMoveToFolder,
    // ignore: unused_element_parameter
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: V26.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: V26.hairline),
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
                  color: V26.ink900, fontWeight: FontWeight.w700,
                  fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${file.sizeLabel}  ·  '
                  '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                  style: const TextStyle(color: V26.ink500, fontSize: 12)),
            ],
          )),
          if (onPreview != null)
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              color: V26.ink500,
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
                color: V26.ok.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: V26.ok.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_open_rounded,
                    size: 11, color: V26.ok),
                const SizedBox(width: 3),
                Text(l.lawyerAccess, style: const TextStyle(
                    color: V26.ok, fontSize: 10,
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
              color: V26.navy600.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: V26.navy600.withValues(alpha: 0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 14, color: V26.navy600),
              const SizedBox(width: 6),
              Expanded(child: Text(file.aiSummary!,
                  style: const TextStyle(
                      color: V26.ink900, fontSize: 12, height: 1.5),
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
            color: V26.navy600,
            onTap: isAnalyzing ? null : onAnalyze,
          ),
          _ActionChip(
            icon: file.lawyerAccess
                ? Icons.lock_rounded
                : Icons.lock_open_rounded,
            label: file.lawyerAccess ? l.revoke : l.share,
            color: file.lawyerAccess ? V26.warn : V26.ok,
            onTap: onToggleAccess,
          ),
          _ActionChip(
            icon: Icons.edit_note_rounded,
            label: l.rename,
            color: V26.ink300,
            onTap: onRename,
          ),
          if (onAddToCase != null)
            _ActionChip(
              icon: Icons.cases_rounded,
              label: l.addToCase,
              color: V26.navy700,
              onTap: onAddToCase!,
            ),
          if (onMoveToFolder != null)
            _ActionChip(
              icon: Icons.drive_file_move_rounded,
              label: l.moveToFolder,
              color: V26.navy600,
              onTap: onMoveToFolder!,
            ),
          _ActionChip(
            icon: Icons.delete_outline_rounded,
            label: l.delete,
            color: V26.emerg,
            onTap: onDelete,
          ),
          if (file.caseId != null)
            _ActionChip(
              icon: Icons.link_off_rounded,
              label: l.removeFromCase,
              color: V26.warn,
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
        color: V26.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: V26.hairline),
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
              color: V26.navy600.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cases_rounded,
                color: V26.navy600, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(legalCase.name, style: const TextStyle(
                  color: V26.ink900, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                '${files.length} ${l.files}  ·  '
                '${legalCase.createdAt.day}/${legalCase.createdAt.month}/${legalCase.createdAt.year}',
                style: const TextStyle(color: V26.ink500, fontSize: 12),
              ),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 18, color: V26.ink500),
            onPressed: onRename,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 12),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: V26.emerg),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 12),
          ),
        ]),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: V26.hairline),
          const SizedBox(height: 8),
          ...files.take(3).map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(f.icon, size: 14, color: f.typeColor),
              const SizedBox(width: 8),
              Expanded(child: Text(f.name,
                  style: const TextStyle(color: V26.ink500, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(f.sizeLabel,
                  style: const TextStyle(color: V26.ink300, fontSize: 11)),
            ]),
          )),
          if (files.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${files.length - 3} more',
                  style: const TextStyle(
                      color: V26.navy600, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  _Vault2026FileCard — matches `.file-card` in `2026/vault.html`.
//  Vertical card: icon tile · name · meta · badges.
// ════════════════════════════════════════════════════════════
class _Vault2026FileCard extends StatelessWidget {
  final _VaultFile file;
  final _L l;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;
  final VoidCallback? onLongPress;

  const _Vault2026FileCard({
    required this.file,
    required this.l,
    this.onTap,
    this.onMenu,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final (icoBg, icoFg) = _iconColors(file);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(V26.rLg),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: V26.surface,
            borderRadius: BorderRadius.circular(V26.rLg),
            border: Border.all(color: V26.hairline),
            boxShadow: V26.shadow1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: icoBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(file.icon, size: 20, color: icoFg),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onMenu,
                    icon: const Icon(Icons.more_horiz,
                        color: V26.ink500, size: 18),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: V26.ink900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${file.sizeLabel}  ·  ${_timeAgo(file.uploadedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 11,
                  color: V26.ink500,
                ),
              ),
              if (_badges().isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _badges(),
                ),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _badges() {
    final out = <Widget>[];
    if (file.type.startsWith('audio/')) {
      out.add(const _BadgePill(label: 'תיעוד שיחה', bg: V26.infoSoft, fg: V26.info));
    }
    if (file.type.startsWith('image/') || file.type.startsWith('video/')) {
      out.add(const _BadgePill(
          label: 'חתום GPS', bg: V26.goldSoft, fg: V26.goldDeep));
    }
    if (file.type.contains('pdf')) {
      // Treat PDFs as potentially "signed" — show badge if filename hints.
      if (file.name.toLowerCase().contains('signed') ||
          file.name.contains('חתום')) {
        out.add(const _BadgePill(label: 'חתום', bg: V26.okSoft, fg: V26.ok));
      }
    }
    if (file.lawyerAccess) {
      out.add(_BadgePill(
          label: l.lawyerAccess, bg: V26.infoSoft, fg: V26.info));
    }
    if (file.caseId != null) {
      out.add(_BadgePill(
          label: l.legalCase, bg: V26.paper2, fg: V26.navy600));
    }
    return out;
  }

  static (Color, Color) _iconColors(_VaultFile f) {
    if (f.type.contains('pdf')) {
      return (V26.emergSoft, V26.emerg2);
    }
    if (f.type.startsWith('audio/')) {
      return (V26.infoSoft, V26.info);
    }
    if (f.type.startsWith('video/')) {
      return (V26.navy100, V26.navy600);
    }
    if (f.type.startsWith('image/')) {
      return (V26.goldSoft, V26.goldDeep);
    }
    return (V26.paper2, V26.navy600);
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      return 'לפני ${(diff.inDays / 30).floor()} חודש';
    }
    if (diff.inDays >= 7) {
      return 'לפני ${(diff.inDays / 7).floor()} שבועות';
    }
    if (diff.inDays >= 1) {
      return diff.inDays == 1 ? 'אתמול' : 'לפני ${diff.inDays} ימים';
    }
    if (diff.inHours >= 1) return 'לפני ${diff.inHours} שעות';
    if (diff.inMinutes >= 1) return 'לפני ${diff.inMinutes} דק\'';
    return 'הרגע';
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _BadgePill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(V26.rPill),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: V26.sans,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
