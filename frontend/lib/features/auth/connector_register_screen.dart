import 'package:flutter/material.dart';
import '../../core/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../core/auth_api.dart'; // ✅ Added

class ConnectorRegisterScreen extends StatefulWidget {
  const ConnectorRegisterScreen({super.key});

  @override
  State<ConnectorRegisterScreen> createState() =>
      _ConnectorRegisterScreenState();
}

class _ConnectorRegisterScreenState extends State<ConnectorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

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
    _licenseCtrl.dispose();
    _nicCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  void _recomputeCanSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _canSubmit = valid && _agree && !_loading;
    });
  }

  // ✅ FINAL _onCreate FUNCTION
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

    // ✅ New Payload
    final payload = <String, dynamic>{
      'fullName': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'confirmPassword': _confirmCtrl.text,
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      'licenseNumber': _licenseCtrl.text.trim().toUpperCase(),
      'nicNumber': _nicCtrl.text.trim().toUpperCase(),
      'vehicleNumber': _vehicleCtrl.text.trim().toUpperCase(),
    };

    try {
      final data = await connectorRegister(payload);
      // ignore: avoid_print
      print('[connectorRegister] parsed data: $data');

      // Optional: store tokens and connector user if you add storage helpers
      // final tokens = Map<String, dynamic>.from(data['tokens'] as Map);
      // final connector = Map<String, dynamic>.from(data['connector'] as Map);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/connectorPanel');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _recomputeCanSubmit();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxCardWidth = 520.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
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
                          'Connector Sign Up',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Full Name
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

                        // Email
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

                        // Password
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
                          validator: Validators.password,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 12),

                        // Confirm Password
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

                        // Phone (optional)
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
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
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // License Number
                        TextFormField(
                          controller: _licenseCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'License Number',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          onChanged: (v) {
                            final upper = v.toUpperCase();
                            if (v != upper) {
                              final sel = _licenseCtrl.selection;
                              _licenseCtrl.value = TextEditingValue(
                                text: upper,
                                selection: sel,
                              );
                            }
                          },
                          validator: Validators.license,
                        ),
                        const SizedBox(height: 12),

                        // NIC Number
                        TextFormField(
                          controller: _nicCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'NIC Number',
                            prefixIcon: Icon(Icons.credit_card),
                            helperText: '9 digits + V/X or 12 digits',
                          ),
                          onChanged: (v) {
                            final upper = v.toUpperCase();
                            if (v != upper) {
                              final sel = _nicCtrl.selection;
                              _nicCtrl.value = TextEditingValue(
                                text: upper,
                                selection: sel,
                              );
                            }
                          },
                          validator: Validators.nicSriLanka,
                        ),
                        const SizedBox(height: 12),

                        // Vehicle Number
                        TextFormField(
                          controller: _vehicleCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Number',
                            prefixIcon: Icon(Icons.directions_car_outlined),
                          ),
                          onChanged: (v) {
                            final upper = v.toUpperCase();
                            if (v != upper) {
                              final sel = _vehicleCtrl.selection;
                              _vehicleCtrl.value = TextEditingValue(
                                text: upper,
                                selection: sel,
                              );
                            }
                          },
                          validator: Validators.vehicleNumber,
                          onFieldSubmitted: (_) => _onCreate(),
                        ),
                        const SizedBox(height: 12),

                        // Terms Checkbox
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

                        // Sign Up Button
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

                        // Already have account
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Already have an account? '),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/auth/connector/login',
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
