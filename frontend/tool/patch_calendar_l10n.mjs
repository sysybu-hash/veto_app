import fs from 'fs';
const p = new URL('../lib/screens/legal_calendar_screen.dart', import.meta.url);
const out = new URL('../lib/screens/legal_calendar_screen.dart.tmp', import.meta.url);
let s = fs.readFileSync(p, 'utf8');
const map = [
  ['L.typeLabel(t)', '_calEventTypeLabel(_l10n, t)'],
  ['L.typeLabel(e.type)', '_calEventTypeLabel(_l10n, e.type)'],
  ['L.confirmDelete', '_l10n.calScrConfirmDeleteEvent'],
  ['L.googleOutlookHint', '_l10n.calScrGoogleOutlookHint'],
  ['L.gcalNotConfigured', '_l10n.calScrGcalNotConfigured'],
  ['L.newEvent', '_l10n.calScrNewEvent'],
  ['L.editEvent', '_l10n.calScrEditEvent'],
  ['L.titleField', '_l10n.calScrTitleField'],
  ['L.typeField', '_l10n.calScrTypeField'],
  ['L.addressField', '_l10n.calScrAddressField'],
  ['L.notesField', '_l10n.calScrNotesField'],
  ['L.reminders', '_l10n.calScrReminders'],
  ['L.linkCase', '_l10n.calScrLinkCase'],
  ['L.noCase', '_l10n.calScrNoCase'],
  ['L.startLbl', '_l10n.calScrStart'],
  ['L.endLbl', '_l10n.calScrEnd'],
  ['L.save', '_l10n.commonSave'],
  ['L.cancel', '_l10n.commonCancel'],
  ['L.delete', '_l10n.commonDelete'],
  ['L.monthTab', '_l10n.calScrMonthTab'],
  ['L.weekTab', '_l10n.calScrWeekTab'],
  ['L.agendaTab', '_l10n.calScrAgendaTab'],
  ['L.refresh', '_l10n.calScrToolbarRefresh'],
  ['L.prev', '_l10n.calScrPrev'],
  ['L.next', '_l10n.calScrNext'],
  ['L.addEvent', '_l10n.calScrAddEvent'],
  ['L.noEvents', '_l10n.calScrNoEvents'],
  ['L.copyUrl', '_l10n.calScrCopyUrl'],
  ['L.copied', '_l10n.calScrCopied'],
  ['L.title', '_l10n.calScrTitle'],
];
for (const [a, b] of map) {
  s = s.split(a).join(b);
}
s = s.replace(/Widget _buildGcalCard\(_CalStrings L\)/g, 'Widget _buildGcalCard()');
s = s.replace(/Widget _buildIcalCard\(_CalStrings L\)/g, 'Widget _buildIcalCard()');
s = s.replace(/Widget _buildViewToggle\(_CalStrings L\)/g, 'Widget _buildViewToggle()');
s = s.replace(/Widget _buildMonthGrid\(_CalStrings L,/g, 'Widget _buildMonthGrid(');
s = s.replace(/Widget _eventTile\(_CalStrings L,/g, 'Widget _eventTile(');
s = s.replace(/Widget _buildWeekView\(_CalStrings L,/g, 'Widget _buildWeekView(');
s = s.replace(/Widget _buildAgenda\(_CalStrings L\)/g, 'Widget _buildAgenda()');
s = s.replace(/final L = _CalStrings\(code\);\s*\n\s*/g, '');
s = s.replace(/_showEventEditor\(L\)/g, '_showEventEditor()');
s = s.replace(/_showEventEditor\(L, suggestedStart:/g, '_showEventEditor(suggestedStart:');
s = s.replace(/_gcalDisconnect\(L\)/g, '_gcalDisconnect()');
s = s.replace(/_openGcalConnect\(L\)/g, '_openGcalConnect()');
s = s.replace(/_buildIcalCard\(L\)/g, '_buildIcalCard()');
s = s.replace(/_buildGcalCard\(L\)/g, '_buildGcalCard()');
s = s.replace(/_buildViewToggle\(L\)/g, '_buildViewToggle()');
s = s.replace(/_buildAgenda\(L\)/g, '_buildAgenda()');
s = s.replace(/_buildWeekView\(L,/g, '_buildWeekView(');
s = s.replace(/_buildMonthGrid\(L,/g, '_buildMonthGrid(');
s = s.replace(/_eventTile\(L,/g, '_eventTile(');
s = s.replace(
  /final statusText = code == 'he'\s*\?[^\n]+\n\s*:[^\n]+\n\s*\?\s*[^\n]+\s*:[^\n]+;/,
  "final statusText = '\${_l10n.calScrTitle} · \$periodLabel';"
);
fs.writeFileSync(out, s);
fs.renameSync(out, p);
console.log('patched');
