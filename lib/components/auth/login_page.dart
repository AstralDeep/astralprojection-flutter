import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';

/// Login page displaying BOTH username/password form AND SSO button
/// regardless of MOCK_AUTH setting. The glass-morphism card matches
/// the React LoginScreen.tsx styling.
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handlePasswordLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success =
        await auth.login(_usernameController.text, _passwordController.text);
    if (success && widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    }
  }

  Future<void> _handleSsoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithOidc();
    if (success && widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1221),
            Color(0xFF1A1E2E),
            Color(0xFF0F1221),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1E2E).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Branding
                    Text(
                      'AstralDeep',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF3F4F6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-Powered Research Platform',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFF3F4F6).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Username/Password form
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(
                            color: const Color(0xFFF3F4F6)
                                .withValues(alpha: 0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: const Color(0xFFFFFFFF)
                                  .withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6366F1)),
                        ),
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Color(0xFF6366F1)),
                      ),
                      style: const TextStyle(color: Color(0xFFF3F4F6)),
                      enabled: !auth.isLoading,
                      autofillHints: const [AutofillHints.username],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                            color: const Color(0xFFF3F4F6)
                                .withValues(alpha: 0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: const Color(0xFFFFFFFF)
                                  .withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6366F1)),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF6366F1)),
                      ),
                      style: const TextStyle(color: Color(0xFFF3F4F6)),
                      obscureText: true,
                      enabled: !auth.isLoading,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) =>
                          auth.isLoading ? null : _handlePasswordLogin(),
                    ),

                    // Error message
                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(auth.error!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign In button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed:
                            auth.isLoading ? null : _handlePasswordLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign In',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    // OR divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: const Color(0xFFFFFFFF)
                                    .withValues(alpha: 0.15)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: const Color(0xFFF3F4F6)
                                    .withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: const Color(0xFFFFFFFF)
                                    .withValues(alpha: 0.15)),
                          ),
                        ],
                      ),
                    ),

                    // SSO button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _handleSsoLogin,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Sign in with SSO',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF06B6D4),
                          side: BorderSide(
                              color: const Color(0xFF06B6D4)
                                  .withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
