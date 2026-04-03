import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../config.dart';

/// Login page supporting Keycloak OIDC (system browser redirect) with
/// mock auth fallback when MOCK_AUTH=true.
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'public_user');
  final _passwordController = TextEditingController();

  Future<void> _handleMockLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success =
        await auth.login(_usernameController.text, _passwordController.text);
    if (success && widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    }
  }

  Future<void> _handleOidcLogin() async {
    // TODO: Integrate flutter_appauth for Keycloak OIDC flow
    // For now, fall back to mock login
    await _handleMockLogin();
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

    if (AppConfig.useMockAuth) {
      return _buildMockLoginForm(auth);
    }
    return _buildOidcLogin(auth);
  }

  Widget _buildMockLoginForm(AuthProvider auth) {
    return Center(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AstralBody',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Development Login',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              enabled: !auth.isLoading,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !auth.isLoading,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => auth.isLoading ? null : _handleMockLogin(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleMockLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOidcLogin(AuthProvider auth) {
    return Center(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AstralBody',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (auth.error != null) ...[
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: auth.isLoading ? null : _handleOidcLogin,
                icon: const Icon(Icons.login),
                label: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in with Keycloak'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
