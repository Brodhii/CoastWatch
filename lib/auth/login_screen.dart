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
  final TextEditingController _emailController = TextEditingController(text: 'admin@coastwatch.id');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');

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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Harap isi email dan kata sandi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.signIn(email, password);

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
        _errorMessage = 'Login gagal. Periksa kembali email dan kata sandi Anda.';
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
            const SizedBox(height: 24),

            // Demo Accounts Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.navy),
                      SizedBox(width: 6),
                      Text(
                        'Akun Demo Pengujian (Klik untuk memilih):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'admin@coastwatch.id';
                        _passwordController.text = 'admin123';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppTheme.navy),
                          SizedBox(width: 6),
                          Text('• Admin Konsol: admin@coastwatch.id', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'pelapor@coastwatch.id';
                        _passwordController.text = 'password123';
                      });
                    },
                    child: const Text('• Pelapor: pelapor@coastwatch.id', style: TextStyle(fontSize: 11, color: AppTheme.teal)),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'relawan@coastwatch.id';
                        _passwordController.text = 'password123';
                      });
                    },
                    child: const Text('• Relawan: relawan@coastwatch.id', style: TextStyle(fontSize: 11, color: AppTheme.teal)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Alamat Email',
              hint: 'nama@contoh.id',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
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
