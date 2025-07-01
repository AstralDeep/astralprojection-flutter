import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/navigation/nav_bar.dart';
import '../components/common/loading_spinner.dart';
import '../components/auth/login_page.dart';
import '../components/workspace/workspace_layout.dart';
import 'state/auth_provider.dart';
import 'state/project_provider.dart';
import 'state/web_socket_provider.dart';
import 'components/theme/app_theme.dart';

// TODO: Add global error handling and user-friendly error UI.
// TODO: Move colors and text styles to a central theme file.
// TODO: Add localization (l10n) support for multi-language UI.
// TODO: Consider more robust state management if app grows (e.g., Riverpod, Bloc).

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Optionally report errors to a logging service.
  };
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isControlPanelOpen = false;

  void handleToggleControlPanel() {
    setState(() {
      isControlPanelOpen = !isControlPanelOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        ],
        child: Builder(
          builder: (context) {
            final auth = Provider.of<AuthProvider>(context);
            final project = Provider.of<ProjectProvider>(context);
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: LoadingSpinner(message: 'Authenticating...')),
              );
            }
            return Scaffold(
              appBar: auth.isAuthenticated
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(56.0),
                      child: NavBar(onToggleControlPanel: handleToggleControlPanel),
                    )
                  : null,
              body: auth.isAuthenticated
                  ? WorkspaceLayout(
                      projectName: project.currentProject?.name ?? '',
                      wsStatus: project.projectConnectionStatus.name,
                      hasRootElement: false, // TODO: Bind to real UI definition state
                    )
                  : LoginPage(
                      onLoginSuccess: () => auth.initializeAuth(),
                    ),
            );
          },
        ),
      ),
    );
  }
}
