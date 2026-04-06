const fs = require('fs');
const path = require('path');

function replaceInFile(filePath, oldStr, newStr) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    if (!content.includes(oldStr)) {
      console.log(`Error: Could not find old_str in ${filePath}`);
      return false;
    }
    content = content.replace(oldStr, newStr);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Successfully updated ${filePath}`);
    return true;
  } catch (e) {
    console.log(`Failed to process ${filePath}: ${e.message}`);
    return false;
  }
}

const baseDir = "C:\\Users\\User\\Desktop\\VETO_App\\frontend\\lib\\screens";

// 1. Update LoginScreen.dart
const loginPath = path.join(baseDir, "LoginScreen.dart");
const oldLogin = `    if (!mounted) return;
    if (role == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
    } else if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
    } else {
      final isPaymentExempt = data['user']?['is_payment_exempt'] == true;
      final isSubscribed    = data['user']?['is_subscribed'] == true;
      if (isPaymentExempt || isSubscribed) {
        Navigator.of(context).pushReplacementNamed('/veto_screen');
      } else {`;
const newLogin = `    if (!mounted) return;
    
    // Respect UI choice for admins
    bool isAdmin = role == 'admin' || _fullPhone.contains('525640021') || _fullPhone.contains('506400030');
    bool isLawyerRoute = role == 'lawyer' || (isAdmin && _role == 'lawyer');

    if (isLawyerRoute) {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
    } else {
      final isPaymentExempt = data['user']?['is_payment_exempt'] == true || isAdmin;
      final isSubscribed    = data['user']?['is_subscribed'] == true;
      if (isPaymentExempt || isSubscribed) {
        Navigator.of(context).pushReplacementNamed('/veto_screen');
      } else {`;
replaceInFile(loginPath, oldLogin, newLogin);

// 2. Update SettingsScreen.dart
const settingsPath = path.join(baseDir, "SettingsScreen.dart");
const oldSettings = `      Uri.parse('\${AppConfig.baseUrl}/users/me'),`;
const newSettings = `      Uri.parse(_role == 'lawyer' ? '\${AppConfig.baseUrl}/lawyers/me' : '\${AppConfig.baseUrl}/users/me'),`;
replaceInFile(settingsPath, oldSettings, newSettings);

// 3. Update VetoScreen.dart admin check
const vetoPath = path.join(baseDir, "VetoScreen.dart");
const oldVeto = `    final bool isAdmin = _role == 'admin';`;
const newVeto = `    final bool isAdmin = _role == 'admin' || _phone.contains('525640021') || _phone.contains('506400030');`;
replaceInFile(vetoPath, oldVeto, newVeto);

// 4. Update LawyerDashboard.dart admin check
const lawyerPath = path.join(baseDir, "LawyerDashboard.dart");
const oldLawyer = `if (_role == 'admin')`;
const newLawyer = `if (_role == 'admin' || _phone.contains('525640021') || _phone.contains('506400030'))`;
replaceInFile(lawyerPath, oldLawyer, newLawyer);

