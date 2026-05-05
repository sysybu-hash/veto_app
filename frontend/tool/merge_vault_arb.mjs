import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "../lib/l10n");

/** Mirrors removed `_L` / `_he|_en|_ru` in files_vault_screen.dart */
const keys = {
  vaultScrTitle: {
    he: "הכספת שלך",
    en: "Your Vault",
    ru: "Моё хранилище",
  },
  vaultScrUpload: {
    he: "העלה קובץ",
    en: "Upload File",
    ru: "Загрузить файл",
  },
  vaultScrUploading: { he: "מעלה...", en: "Uploading...", ru: "Загрузка..." },
  vaultScrAnalyzing: {
    he: "AI מנתח...",
    en: "AI analyzing...",
    ru: "AI анализирует...",
  },
  vaultScrDeleteConfirm: {
    he: "למחוק את הקובץ?",
    en: "Delete this file?",
    ru: "Удалить файл?",
  },
  vaultScrDelete: { he: "מחק", en: "Delete", ru: "Удалить" },
  vaultScrShare: {
    he: 'שתף עם עו"ד',
    en: "Share with Lawyer",
    ru: "Поделиться с адвокатом",
  },
  vaultScrRevoke: {
    he: "בטל גישה",
    en: "Revoke Access",
    ru: "Закрыть доступ",
  },
  vaultScrAnalyze: {
    he: "נתח עם AI",
    en: "Analyze with AI",
    ru: "Анализ AI",
  },
  vaultScrNoFiles: {
    he: "אין קבצים עדיין",
    en: "No files yet",
    ru: "Файлов пока нет",
  },
  vaultScrUsageOf: {
    he: "בשימוש: ",
    en: "Used: ",
    ru: "Использовано: ",
  },
  vaultScrUsedGb: { he: "GB", en: "GB", ru: "ГБ" },
  vaultScrQuotaSuffix: {
    he: " / 10 GB",
    en: " / 10 GB",
    ru: " / 10 ГБ",
  },
  vaultScrLegalCase: {
    he: "תיק משפטי",
    en: "Legal Case",
    ru: "Юридическое дело",
  },
  vaultScrCaseName: {
    he: "שם התיק",
    en: "Case name",
    ru: "Название дела",
  },
  vaultScrCreateCase: {
    he: "צור תיק",
    en: "Create Case",
    ru: "Создать дело",
  },
  vaultScrAddToCase: {
    he: "הוסף לתיק",
    en: "Add to Case",
    ru: "Добавить в дело",
  },
  vaultScrFiles: { he: "קבצים", en: "files", ru: "файлов" },
  vaultScrAllFiles: {
    he: "כל הקבצים",
    en: "All Files",
    ru: "Все файлы",
  },
  vaultScrCaseFiles: {
    he: "קבצי התיק",
    en: "Case Files",
    ru: "Файлы дела",
  },
  vaultScrShareWithLawyer: {
    he: "שתף עם עורך דין",
    en: "Share with Lawyer",
    ru: "Поделиться с адвокатом",
  },
  vaultScrLawyerAccess: {
    he: 'גישת עו"ד',
    en: "Lawyer Access",
    ru: "Доступ адвоката",
  },
  vaultScrFileType: { he: "סוג", en: "Type", ru: "Тип" },
  vaultScrSize: { he: "גודל", en: "Size", ru: "Размер" },
  vaultScrDate: { he: "תאריך", en: "Date", ru: "Дата" },
  vaultScrStatus: { he: "סטטוס", en: "Status", ru: "Статус" },
  vaultScrAiSummary: {
    he: "סיכום AI",
    en: "AI Summary",
    ru: "Сводка AI",
  },
  vaultScrAiBtn: { he: "נתח", en: "Analyze", ru: "Анализ" },
  vaultScrCancel: { he: "ביטול", en: "Cancel", ru: "Отмена" },
  vaultScrSave: { he: "שמור", en: "Save", ru: "Сохранить" },
  vaultScrErrorUpload: {
    he: "שגיאה בהעלאה",
    en: "Upload failed",
    ru: "Ошибка загрузки",
  },
  vaultScrSuccessUpload: {
    he: "קובץ הועלה בהצלחה",
    en: "File uploaded successfully",
    ru: "Файл загружен",
  },
  vaultScrSuccessDelete: {
    he: "הקובץ נמחק",
    en: "File deleted",
    ru: "Файл удалён",
  },
  vaultScrSuccessShare: {
    he: "הגישה עודכנה",
    en: "Access updated",
    ru: "Доступ обновлён",
  },
  vaultScrCompressing: {
    he: "דוחס...",
    en: "Compressing...",
    ru: "Сжатие...",
  },
  vaultScrCaseCreated: {
    he: "התיק נוצר",
    en: "Case created",
    ru: "Дело создано",
  },
  vaultScrLoading: { he: "טוען...", en: "Loading...", ru: "Загрузка..." },
  vaultScrRename: { he: "שנה שם", en: "Rename", ru: "Переименовать" },
  vaultScrFileName: {
    he: "שם הקובץ",
    en: "File name",
    ru: "Имя файла",
  },
  vaultScrSuccessRename: {
    he: "השם עודכן",
    en: "Name updated",
    ru: "Имя обновлено",
  },
  vaultScrDeleteCase: {
    he: "מחק תיק",
    en: "Delete Case",
    ru: "Удалить дело",
  },
  vaultScrDeleteCaseConfirm: {
    he: "למחוק את התיק? הקבצים יישארו בכספת.",
    en: "Delete this case? Files will remain in your vault.",
    ru: "Удалить это дело? Файлы останутся в хранилище.",
  },
  vaultScrSuccessDeleteCase: {
    he: "התיק נמחק",
    en: "Case deleted",
    ru: "Дело удалено",
  },
  vaultScrRemoveFromCase: {
    he: "הסר מהתיק",
    en: "Remove from Case",
    ru: "Убрать из дела",
  },
  vaultScrFolders: { he: "תיקיות", en: "Folders", ru: "Папки" },
  vaultScrNewFolder: {
    he: "תיקייה חדשה",
    en: "New folder",
    ru: "Новая папка",
  },
  vaultScrFolderName: {
    he: "שם התיקייה",
    en: "Folder name",
    ru: "Имя папки",
  },
  vaultScrMoveToFolder: {
    he: "העבר לתיקייה",
    en: "Move to folder",
    ru: "Переместить",
  },
  vaultScrRootVault: { he: "כספת", en: "Vault", ru: "Хранилище" },
  vaultScrDeleteFolder: {
    he: "מחק תיקייה",
    en: "Delete folder",
    ru: "Удалить папку",
  },
  vaultScrDeleteFolderConfirm: {
    he: "למחוק את התיקייה? (רק אם ריקה)",
    en: "Delete this folder? (only if empty)",
    ru: "Удалить папку? (только пустая)",
  },
  vaultScrFolderNotEmpty: {
    he: "התיקייה אינה ריקה",
    en: "Folder is not empty",
    ru: "Папка не пуста",
  },
  vaultScrGoUp: { he: "הקודם", en: "Up", ru: "Назад" },
  vaultScrOpenFolder: { he: "פתח", en: "Open", ru: "Открыть" },
  vaultScrDropFilesHere: {
    he: "שחררו כאן לטעינה",
    en: "Drop to upload",
    ru: "Отпустите для загрузки",
  },
  vaultScrUploadZoneTitle: {
    he: "העלאה מהירה",
    en: "Quick upload",
    ru: "Быстрая загрузка",
  },
  vaultScrUploadZoneHint: {
    he: 'במובייל: "העלה" או מצלמה. בווב: גרירה לכאן או לכל מקום על המסך.',
    en: "Mobile: use Upload or camera. Web: drag files here or anywhere on the page.",
    ru: "Телефон: кнопка загрузки или камера. Веб: перетащите сюда или в любую область.",
  },
  vaultScrSearchTooltip: {
    he: "חיפוש",
    en: "Search",
    ru: "Поиск",
  },
  vaultScrDesktopStatus: {
    he: "מאובטח · מוצפן E2E · נשמר במכשיר ובכספת מוצפנת",
    en: "Secured · E2E encrypted · stored on-device & in encrypted vault",
    ru: "Защищено · E2E · на устройстве и в зашифрованном хранилище",
  },
  vaultScrCaptureCamera: {
    he: "צילום מהמצלמה",
    en: "Capture from camera",
    ru: "Снять камерой",
  },
  vaultScrRefresh: { he: "רענון", en: "Refresh", ru: "Обновить" },
  vaultScrQuotaExceededSnack: {
    he: "ניצלת את מכסת האחסון בכספת.",
    en: "Vault storage quota exceeded.",
    ru: "Достигнута квота хранилища.",
  },
  vaultScrQuotaFileTooLargeSnack: {
    he: "אין מספיק מקום פנוי לקובץ זה (מקס׳ להעלאה 100MB).",
    en: "Not enough free vault space for this file (max 100MB per upload).",
    ru: "Недостаточно места для файла (до 100 МБ за загрузку).",
  },
  vaultScrUpgradePlan: {
    he: "שדרג תוכנית",
    en: "Upgrade plan",
    ru: "Обновить план",
  },
};

/** ICU placeholders — companion @metadata per key */
const placeholderKeys = {
  vaultScrStorageUsedLine: {
    templates: {
      he: "{used} GB מנוצל מתוך {quota} GB",
      en: "{used} GB of {quota} GB used",
      ru: "{used} GB из {quota} GB",
    },
    placeholders: {
      used: { type: "String" },
      quota: { type: "String" },
    },
  },
  vaultScrStorageSubLine: {
    templates: {
      he: "{count} קבצים · הצפנה AES-256 בכל קובץ",
      en: "{count} files · AES-256 per-file encryption",
      ru: "{count} файлов · AES-256 для каждого файла",
    },
    placeholders: {
      count: { type: "int" },
    },
  },
};

function esc(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function merge(locale, lang) {
  const p = path.join(root, `app_${locale}.arb`);
  let raw = fs.readFileSync(p, "utf8").trimEnd();
  if (!raw.endsWith("}")) throw new Error(p);
  raw = raw.slice(0, -1).trimEnd();
  if (!raw.endsWith(",")) raw += ",";
  const lines = Object.keys(keys).map(
    (k) => `  "${k}": "${esc(keys[k][lang])}"`
  );
  const phLines = [];
  for (const pk of Object.keys(placeholderKeys)) {
    const spec = placeholderKeys[pk];
    const template = spec.templates[lang];
    phLines.push(`  "${pk}": "${esc(template)}"`);
    const phObj = Object.entries(spec.placeholders)
      .map(
        ([name, meta]) =>
          `      "${name}": { "type": "${meta.type}" }`
      )
      .join(",\n");
    phLines.push(`  "@${pk}": {
    "placeholders": {
${phObj}
    }
  }`);
  }
  fs.writeFileSync(
    p,
    raw + "\n" + [...lines, ...phLines].join(",\n") + "\n}\n"
  );
}

merge("he", "he");
merge("en", "en");
merge("ru", "ru");
console.log("vault ARB merged");
