import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register Controllers
  final _nameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _courseController = TextEditingController();
  final _semesterController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _enrollmentController.dispose();
    _courseController.dispose();
    _semesterController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).login(
            _loginEmailController.text.trim(),
            _loginPasswordController.text,
          );
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).register(
            name: _nameController.text.trim(),
            enrollmentNumber: _enrollmentController.text.trim(),
            course: _courseController.text.trim(),
            semester: _semesterController.text.trim(),
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
      if (mounted) {
        SuccessDialog.show(
          context,
          message: "Account created successfully! You can now login.",
          onOk: () => _tabController.animateTo(0),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const pink = Color(0xFFFF2E88);

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0B0F), Color(0xFF15151F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Logo & Header
                  const Icon(Icons.bolt_rounded, size: 60, color: pink)
                      .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  const Text(
                    'PIXEL EVENTS',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ),
                  const SizedBox(height: 24),

                  // Tabs
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pink.withOpacity(0.1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: pink.withOpacity(0.2),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: pink,
                      unselectedLabelColor: Colors.white54,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: "LOGIN"),
                        Tab(text: "REGISTER"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Content
                  SizedBox(
                    height: 550, // Fixed height for tab content
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginForm(),
                        _buildRegisterForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return CyberGlassCard(
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            CyberTextField(
              controller: _loginEmailController,
              labelText: 'Email Address',
              prefixIcon: Icons.email_outlined,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CyberTextField(
              controller: _loginPasswordController,
              labelText: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: const Color(0xFFFF2E88).withOpacity(0.5)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const Spacer(),
            CyberButton(
              onPressed: _handleLogin,
              text: "Sign In",
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return CyberGlassCard(
      child: Form(
        key: _registerFormKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              CyberTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CyberTextField(
                      controller: _enrollmentController,
                      labelText: 'Enrollment #',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberTextField(
                      controller: _semesterController,
                      labelText: 'Semester',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CyberTextField(
                controller: _courseController,
                labelText: 'Course',
                prefixIcon: Icons.school_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CyberTextField(
                controller: _registerEmailController,
                labelText: 'Email',
                prefixIcon: Icons.email_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CyberTextField(
                controller: _registerPasswordController,
                labelText: 'Password',
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              CyberTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                obscureText: true,
                validator: (v) => v != _registerPasswordController.text ? 'Mismatch' : null,
              ),
              const SizedBox(height: 24),
              CyberButton(
                onPressed: _handleRegister,
                text: "Create Account",
                isLoading: _isLoading,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
