import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'candidate';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final auth = context.read<AuthViewModel>();
    final ok = await auth.register(
      _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim(), _role,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Lỗi đăng ký')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Bạn là:', style: TextStyle(fontWeight: FontWeight.w500))),
            RadioListTile(
              title: const Text('Ứng viên'),
              value: 'candidate',
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
            RadioListTile(
              title: const Text('Nhà tuyển dụng'),
              value: 'employer',
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 24),
            auth.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: const Text('Đăng ký')),
          ],
        ),
      ),
    );
  }
}