import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.reporter;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Harap lengkapi semua kolom pendaftaran.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Kata sandi minimal 6 karakter.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.signUp(
      email: email,
      password: password,
      displayName: name,
      role: _selectedRole,
    );

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
        _errorMessage = 'Pendaftaran gagal. Silakan coba kembali.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bergabung Bersama CoastWatch',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih peran partisipasi Anda dalam menjaga kelestarian lingkungan pesisir.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Nama Lengkap / Panggilan',
              hint: 'Contoh: Arya Pesisir',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline, size: 18),
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Alamat Email',
              hint: 'nama@contoh.id',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Kata Sandi',
              hint: 'Minimal 6 karakter',
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
            const SizedBox(height: 20),

            // Role Selection
            const Text(
              'Pilih Peran Akun',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildRoleCard(
                    role: UserRole.reporter,
                    title: 'Pelapor',
                    subtitle: 'Mengambil foto ber-geotag & membuat laporan',
                    icon: Icons.camera_alt_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleCard(
                    role: UserRole.cleaner,
                    title: 'Relawan',
                    subtitle: 'Mengambil tugas aksi bersih & unggah bukti',
                    icon: Icons.cleaning_services_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              '*Peran Admin tidak dapat dipilih melalui formulir publik dan diatur secara terpisah melalui sistem web backend.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: AppTheme.statusRejected),
              ),
            ],

            const SizedBox(height: 24),

            AppButton(
              label: 'Daftar Sekarang',
              onPressed: _isLoading ? null : _handleRegister,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sudah punya akun? ',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: const Text('Masuk di sini'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.skyBlue.withValues(alpha: 0.35) : AppTheme.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.teal : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppTheme.teal : AppTheme.navy, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
