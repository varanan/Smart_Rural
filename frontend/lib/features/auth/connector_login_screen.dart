import 'package:flutter/material.dart';
import '../../core/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../core/auth_api.dart'; // ✅ Added

class ConnectorLoginScreen extends StatefulWidget {
  const ConnectorLoginScreen({super.key});

  @override
  State<ConnectorLoginScreen> createState() => _ConnectorLoginScreenState();
}

class _ConnectorLoginScreenState extends State<ConnectorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ✅ FINAL _onLogin FUNCTION (as per your request)
  Future<void> _onLogin() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _loading = true);
    try {
      final data = await connectorLogin(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      // ignore: avoid_print
      print('[connectorLogin] parsed data: $data');

      // Optional: store tokens and connector user if you add storage helpers
      // final tokens = Map<String, dynamic>.from(data['tokens'] as Map);
      // final connector = Map<String, dynamic>.from(data['connector'] as Map);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/connectorPanel');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxCardWidth = 480.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Connector Login',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: Validators.email,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 12),

                        // Password Field
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: Validators.password,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _onLogin(),
                        ),
                        const SizedBox(height: 8),

                        // Remember Me
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(child: Text('Remember me')),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Login Button
                        GradientButton(
                          text: 'LOG IN',
                          loading: _loading,
                          onPressed: _loading ? null : _onLogin,
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset — coming soon'),
                                ),
                              );
                            },
                            child: const Text('Forget Password'),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Sign Up Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Not a member? '),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/auth/connector/register',
                                );
                              },
                              child: const Text('Sign up now'),
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
