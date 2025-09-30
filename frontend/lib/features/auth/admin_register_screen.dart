import 'package:flutter/material.dart';
import '../../core/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../services/api_service.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscurePwd = true;
  bool _obscureCpwd = true;
  bool _agree = false;
  bool _loading = false;
  bool _canSubmit = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _recomputeCanSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _canSubmit = valid && _agree && !_loading;
    });
  }

  Future<void> _onCreate() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || !_agree) {
      _recomputeCanSubmit();
      return;
    }

    setState(() {
      _loading = true;
      _canSubmit = false;
    });

    try {
      await ApiService.adminRegister(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/adminDashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _recomputeCanSubmit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxCardWidth = 520.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxCardWidth),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: _recomputeCanSubmit,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'App Admin Sign Up',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => Validators.requiredField(
                            v,
                            fieldName: 'Full Name',
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: Validators.email,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePwd,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePwd
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePwd
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePwd = !_obscurePwd),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                            ).hasMatch(v)) {
                              return 'Password must contain uppercase, lowercase, and number';
                            }
                            return null;
                          },
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureCpwd,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscureCpwd
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscureCpwd
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureCpwd = !_obscureCpwd),
                            ),
                          ),
                          validator: (v) {
                            if ((v ?? '').isEmpty) {
                              return 'Confirm Password is required';
                            }
                            if (v != _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return null;
                            if (t.length < 9 || t.length > 15) {
                              return 'Enter a valid phone (9–15 digits)';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(t)) {
                              return 'Phone number must contain only digits';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _onCreate(),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                              value: _agree,
                              onChanged: (v) {
                                setState(() {
                                  _agree = v ?? false;
                                });
                                _recomputeCanSubmit();
                              },
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text('I agree to the Terms & Privacy'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Semantics(
                          button: true,
                          label: 'Sign up',
                          child: GradientButton(
                            text: 'SIGN UP',
                            loading: _loading,
                            onPressed: (_canSubmit && !_loading)
                                ? _onCreate
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Already have an account? '),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/auth/admin/login',
                                );
                              },
                              child: const Text('Log in'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
