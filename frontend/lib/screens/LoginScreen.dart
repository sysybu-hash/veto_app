import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _step = 0; String _role = 'user';
  final _phone = TextEditingController(text: '+972'), _name = TextEditingController();
  bool _loading = false, _isReg = false; String _error = '';

  void _next(String role) {
    bool isLawyer = (role == 'lawyer' || (_role == 'lawyer'));
    Navigator.of(context).pushReplacementNamed(isLawyer ? '/lawyer_dashboard' : '/veto_screen');
  }

  Future<void> _handle() async {
    if (_phone.text.length < 10) { setState(() => _error = 'מספר לא תקין'); return; }
    setState(() { _loading = true; _error = ''; });
    if (_isReg) {
      if (_name.text.isEmpty) { setState(() { _loading = false; _error = 'נא להזין שם'; }); return; }
      await AuthService().register(fullName: _name.text, phoneNumber: _phone.text, role: _role, language: 'he');
    }
    final res = await AuthService().requestOTPDetailed(_phone.text, _role);
    if (res == OtpRequestOutcome.success) setState(() { _step = 1; _loading = false; });
    else setState(() { _loading = false; _error = 'שגיאה בחיבור'; });
  }

  Future<void> _verify(String code) async {
    setState(() => _loading = true);
    final data = await AuthService().verifyOTP(_phone.text, code);
    if (data != null) _next(data['user']?['role'] ?? _role);
    else setState(() { _loading = false; _error = 'קוד לא תקין'; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(children: [
        const SizedBox(height: 60),
        const Text('VETO', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w100, letterSpacing: 10)),
        Text('Wizard Flow - שלב ${_step + 1} מתוך 2', style: const TextStyle(color: Colors.white24, fontSize: 12)),
        const SizedBox(height: 60),
        if (_step == 0) ...[
          Row(children: [
            _tab('אזרח', 'user', Icons.person), _tab('עורך דין', 'lawyer', Icons.balance),
          ]),
          const SizedBox(height: 32),
          if (_isReg) _input(_name, 'שם מלא', Icons.person_outline, false),
          _input(_phone, 'מספר טלפון', Icons.phone_android, true),
          const SizedBox(height: 24),
          _btn(_loading ? 'שולח...' : 'המשך', _handle),
          TextButton(onPressed: () => setState(() => _isReg = !_isReg), child: Text(_isReg ? 'כבר יש לי חשבון' : 'הרשמה למשתמש חדש', style: const TextStyle(color: Colors.white54))),
        ] else ...[
          const Text('הזן קוד אימות', style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 24),
          Pinput(length: 6, autofocus: true, onCompleted: _verify, defaultPinTheme: PinTheme(width: 50, height: 60, textStyle: const TextStyle(color: Colors.white, fontSize: 24), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 32),
          TextButton(onPressed: () => setState(() => _step = 0), child: const Text('חזרה', style: TextStyle(color: Colors.white54))),
        ],
        if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Text(_error, style: const TextStyle(color: Colors.redAccent))),
      ]))),
    ));
  }

  Widget _tab(String l, String r, IconData i) => Expanded(child: GestureDetector(onTap: () => setState(() => _role = r),
    child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _role == r ? Colors.white10 : Colors.transparent, border: Border.all(color: _role == r ? Colors.white24 : Colors.white10), borderRadius: BorderRadius.circular(15)),
      child: Column(children: [Icon(i, color: _role == r ? Colors.white : Colors.white24), Text(l, style: TextStyle(color: _role == r ? Colors.white : Colors.white24, fontSize: 12))]))));

  Widget _input(TextEditingController c, String h, IconData i, bool isLast) => Padding(padding: const EdgeInsets.only(bottom: 16),
    child: TextField(controller: c, keyboardType: i == Icons.phone_android ? TextInputType.phone : TextInputType.text, textInputAction: isLast ? TextInputAction.done : TextInputAction.next, onSubmitted: isLast ? (_) => _handle() : null, style: const TextStyle(color: Colors.white), decoration: InputDecoration(prefixIcon: Icon(i, color: Colors.white24), hintText: h, hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))));

  Widget _btn(String l, VoidCallback o) => SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _loading ? null : o, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}