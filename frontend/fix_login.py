import sys

file_path = r'C:\Users\User\Desktop\VETO_App\frontend\lib\screens\LoginScreen.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Change default language to Hebrew
    content = content.replace("VLang  _lang = VLang.en;", "VLang  _lang = VLang.he;")
    
    # 2. Fix admin routing
    old_routing = "  void _navigateToDashboard(String role) {\n    Navigator.of(context).pushReplacementNamed(\n      (role == 'lawyer' || role == 'admin') ? '/lawyer_dashboard' : '/veto_screen',\n    );\n  }"
    new_routing = "  void _navigateToDashboard(String role) {\n    Navigator.of(context).pushReplacementNamed(\n      (role == 'lawyer') ? '/lawyer_dashboard' : '/veto_screen',\n    );\n  }"
    content = content.replace(old_routing, new_routing)
    
    # 3. Add Enter key support to phone field
    old_phone_field = "          TextFormField(\n            controller:    _phoneCtrl,\n            keyboardType:  TextInputType.phone,\n            style: const TextStyle("
    new_phone_field = "          TextFormField(\n            controller:    _phoneCtrl,\n            keyboardType:  TextInputType.phone,\n            textInputAction: TextInputAction.next,\n            onFieldSubmitted: (_) => _handlePrimaryAction(),\n            style: const TextStyle("
    content = content.replace(old_phone_field, new_phone_field)
    
    # 4. Add Enter key support to name field
    old_name_field = "            TextFormField(\n              controller:    _nameCtrl,\n              keyboardType:  TextInputType.name,\n              style: const TextStyle("
    new_name_field = "            TextFormField(\n              controller:    _nameCtrl,\n              keyboardType:  TextInputType.name,\n              textInputAction: TextInputAction.done,\n              onFieldSubmitted: (_) => _handlePrimaryAction(),\n              style: const TextStyle("
    content = content.replace(old_name_field, new_name_field)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print('Successfully updated LoginScreen.dart')
except Exception as e:
    print('Error:', e)
