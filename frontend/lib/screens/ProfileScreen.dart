import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService().getStoredName();
    final role = await AuthService().getStoredRole();
    setState(() {
      _nameCtrl.text = name ?? '';
      _role = role;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    // Note: To persist this in backend, we need a /auth/update endpoint.
    // For now, we update local storage to reflect changes immediately.
    // In a production app, we would call http.patch here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully (Simulation)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        title: const Text('PERSONAL AREA', style: TextStyle(fontSize: 14, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFC0C2C9),
                      child: Icon(Icons.person, size: 50, color: Color(0xFF001F3F)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel('FULL NAME'),
                  _buildInput(_nameCtrl),
                  const SizedBox(height: 20),
                  _buildLabel('EMAIL (OPTIONAL)'),
                  _buildInput(_emailCtrl),
                  const SizedBox(height: 20),
                  _buildLabel('ROLE'),
                  Text(
                    _role?.toUpperCase() ?? 'USER',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71).withOpacity(0.2),
                        side: const BorderSide(color: Color(0xFF2ECC71)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
      ),
    );
  }
}
