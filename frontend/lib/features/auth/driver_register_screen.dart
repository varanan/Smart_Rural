import 'package:flutter/material.dart';
import '../../core/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../core/auth_api.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _busCtrl = TextEditingController();

  bool _obscurePwd = true;
  bool _obscureCpwd = true;
  bool _agree = false;
  bool _loading = false;
  bool _canSubmit = false;

  final _api = DriverAuthApi();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _nicCtrl.dispose();
    _busCtrl.dispose();
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
      final data = await _api.signup(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
        phone: _phoneCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim().toUpperCase(),
        nicNumber: _nicCtrl.text.trim().toUpperCase(),
        busNumber: _busCtrl.text.trim().toUpperCase(),
      );

      final tokens = Map<String, dynamic>.from(data['tokens'] as Map);
      final driver = Map<String, dynamic>.from(data['driver'] as Map);
      await AuthStorage.saveDriver(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
        driver: driver,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/driverHome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
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
                          'Driver Sign Up',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 1) Full Name
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

                        // 2) Email
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

                        // 3) Password
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

                        // 4) Confirm Password
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
                            if ((v ?? '').isEmpty)
                              return 'Confirm Password is required';
                            if (v != _passwordCtrl.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 5) Phone (required; Sri Lankan format 0XXXXXXXXX)
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                            helperText: 'Sri Lankan format: 0XXXXXXXXX',
                          ),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Phone is required';
                            final reg = RegExp(r'^0\d{9}$');
                            if (!reg.hasMatch(t))
                              return 'Enter a valid phone (0XXXXXXXXX)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 6) License Number
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

                        // 7) NIC Number
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

                        // 8) Bus Number
                        TextFormField(
                          controller: _busCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Bus Number',
                            prefixIcon: Icon(Icons.directions_bus_outlined),
                          ),
                          onChanged: (v) {
                            final upper = v.toUpperCase();
                            if (v != upper) {
                              final sel = _busCtrl.selection;
                              _busCtrl.value = TextEditingValue(
                                text: upper,
                                selection: sel,
                              );
                            }
                          },
                          validator: Validators.busNumber,
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

                        GradientButton(
                          text: 'CREATE ACCOUNT',
                          loading: _loading,
                          onPressed: (_canSubmit && !_loading)
                              ? _onCreate
                              : null,
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
                                  '/auth/driver/login',
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
