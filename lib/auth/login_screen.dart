import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final emailOrUsername = _emailController.text.trim();
    final password = _passwordController.text;

    if (emailOrUsername.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Harap isi username atau email dan kata sandi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.signIn(emailOrUsername, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = _authService.lastAuthError ??
            'Login gagal. Periksa kembali username/email dan kata sandi Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk CoastWatch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Selamat Datang Kembali',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masuk untuk mengirimkan laporan pesisir atau mengelola tugas pembersihan relawan dan verifikasi admin.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Clean Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xFF0F172A)),
                      SizedBox(width: 6),
                      Text(
                        'Petunjuk Akun (Username & Kata Sandi):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'admin';
                        _passwordController.text = 'password';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text('• Admin: admin / password', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'relawan';
                        _passwordController.text = 'password';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text('• Relawan: relawan / password', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'pelapor';
                        _passwordController.text = 'password';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text('• Pelapor: pelapor / password', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Username atau Email',
              hint: 'Contoh: admin, relawan, atau nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.person_outline, size: 18),
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: AppTheme.statusRejected),
              ),
            ],

            const SizedBox(height: 24),

            AppButton(
              label: 'Masuk Akun',
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum memiliki akun? ',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.register);
                  },
                  child: const Text('Daftar di sini'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
