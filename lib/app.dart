// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/navigation/nav_bar.dart'; // Assuming this path is correct
import 'components/common/loading_spinner.dart'; // Assuming this path is correct
import 'components/auth/login_page.dart'; // Assuming this path is correct
import 'components/workspace/workspace_layout.dart'; // Assuming this path is correct
import 'state/auth_provider.dart'; // Assuming this path is correct
import 'state/project_provider.dart'; // Assuming this path is correct
import 'state/web_socket_provider.dart'; // Assuming this path is correct
import 'components/theme/app_theme.dart'; // Assuming this path is correct

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