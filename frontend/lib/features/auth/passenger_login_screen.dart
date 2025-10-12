import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../core/auth_api.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_auth_service.dart';


class PassengerLoginScreen extends StatefulWidget {
  const PassengerLoginScreen({super.key});

  @override
  State<PassengerLoginScreen> createState() => _PassengerLoginScreenState();
}

class _PassengerLoginScreenState extends State<PassengerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;

  final _api = PassengerAuthApi();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    // Check connectivity first
    final connectivityService = ConnectivityService();
    final isOnline = await connectivityService.isConnected();
    
    if (!isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please connect to login or use offline mode.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await _api.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final tokens = Map<String, dynamic>.from(data['tokens'] as Map);
      final passenger = Map<String, dynamic>.from(data['passenger'] as Map);

      // Always save tokens for authenticated requests
      // ✅ FIXED: Save token in both formats for compatibility
      final prefs = await SharedPreferences.getInstance();
      
      // Save for AuthStorage (old system)
      await AuthStorage.savePassenger(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
        passenger: passenger,
      );
      
      // ✅ NEW: Also save for ApiService (new review system)
      await prefs.setString('access_token', tokens['access'] as String);
      await prefs.setString('user_role', 'passenger');
      await prefs.setString('user_data', jsonEncode(passenger));

      await prefs.setString('auth_passenger', jsonEncode(passenger));



      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/passengerHome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueOffline() async {
    await OfflineAuthService.enableOfflineMode();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/customer-bus-timetable');
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
                          'Passenger Login',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                        GradientButton(
                          text: 'LOG IN',
                          loading: _loading,
                          onPressed: _loading ? null : _onLogin,
                        ),
                        const SizedBox(height: 12),
                        
                        // NEW: Offline Access Button
                        OutlinedButton.icon(
                          icon: const Icon(Icons.wifi_off),
                          label: const Text('Browse Offline'),
                          onPressed: _continueOffline,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
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
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Not a member? '),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/auth/passenger/register',
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