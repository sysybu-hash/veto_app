/**
 * Prints stable dev URLs when phone + PC are on the same Wi‑Fi.
 * No localtunnel — IP may change if the router assigns a new DHCP lease
 * (set a DHCP reservation in the router for best stability).
 */

const os = require('os');

const PORT = Number(process.env.PORT) || 5001;

function ipv4LanAddresses() {
  const nets = os.networkInterfaces();
  const out = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === 'IPv4' && !net.internal) {
        out.push({ name, address: net.address });
      }
    }
  }
  return out;
}

console.log('');
console.log('══ VETO — כתובת יציבה (בדרך כלל) בלי טונל ══');
console.log('');
console.log('כשהטלפון והמחשב על אותה Wi‑Fi, Flutter יכול לדבר ישר עם השרת:');
console.log('');

const addrs = ipv4LanAddresses();
if (addrs.length === 0) {
  console.log('  (לא נמצאו ממשקי IPv4 חיצוניים — בדוק Wi‑Fi / כבל)');
} else {
  for (const { name, address } of addrs) {
    console.log(`  כרטיס: ${name}`);
    console.log(`  API:     http://${address}:${PORT}/api`);
    console.log(`  Flutter: flutter run --dart-define=VETO_HOST=${address}`);
    console.log('');
  }
}

console.log('הערות:');
console.log('  • אין צורך ב-localtunnel במצב הזה; השרת רק צריך npm run dev.');
console.log('  • אם ה-IP משתנה אחרי הפסקת חשמל לראוטר — בחר “הקצאה קבועה” (DHCP reservation) ל-PC.');
console.log('');
