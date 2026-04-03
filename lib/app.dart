import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/navigation/nav_bar.dart';
import 'components/common/loading_overlay.dart';
import 'components/common/offline_indicator.dart';
import 'components/auth/login_page.dart';
import 'components/workspace/workspace_layout.dart';
import 'state/auth_provider.dart';
import 'state/project_provider.dart';
import 'state/web_socket_provider.dart';
import 'state/device_profile_provider.dart';
import 'state/theme_provider.dart';
import 'components/theme/app_theme.dart';
import 'platform/tv/tv_focus_manager.dart';
import 'platform/tv/tv_theme.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, DeviceProfileProvider>(
        builder: (context, themeProvider, deviceProfile, _) {
          final isTv = deviceProfile.deviceType == 'tv';
          final lightTheme = themeProvider.backendTheme ??
              (isTv ? TvTheme.theme : AppTheme.lightTheme);
          final darkTheme = themeProvider.backendTheme ??
              (isTv ? TvTheme.theme : AppTheme.darkTheme);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: isTv ? ThemeMode.dark : ThemeMode.system,
            home: const _AppShell(),
          );
        },
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  bool _isControlPanelOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load cached SDUI tree on startup
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.loadCachedTree();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Orientation or window resize — update device profile
    _updateDeviceProfile();
  }

  void _updateDeviceProfile() {
    final mq = MediaQuery.of(context);
    final dp = Provider.of<DeviceProfileProvider>(context, listen: false);
    dp.updateFromMediaQuery(mq);
  }

  @override
  Widget build(BuildContext context) {
    // Update device profile on each build (captures initial + changes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDeviceProfile();
    });

    final auth = Provider.of<AuthProvider>(context);
    final ws = Provider.of<WebSocketProvider>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      return Scaffold(
        body: LoginPage(onLoginSuccess: () => auth.initializeAuth()),
      );
    }

    // Authenticated — show workspace with overlays
    final dp = Provider.of<DeviceProfileProvider>(context);
    final isTv = dp.deviceType == 'tv';

    Widget body = Stack(
      children: [
        WorkspaceLayout(
          projectName:
              Provider.of<ProjectProvider>(context).currentProject?.name ??
                  '',
          wsStatus:
              Provider.of<ProjectProvider>(context).projectConnectionStatus.name,
          hasRootElement: ws.hasReceivedRender || ws.components.isNotEmpty,
        ),
        // Loading overlay: shown after auth but before first ui_render
        if (ws.connected && !ws.hasReceivedRender && ws.components.isEmpty)
          const LoadingOverlay(),
        // Offline indicator: shown when connection is lost
        if (!ws.connected && auth.isAuthenticated) const OfflineIndicator(),
      ],
    );

    // Wrap body in TV focus manager for D-pad navigation
    if (isTv) {
      body = TvFocusManager(child: body);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: NavBar(
          onToggleControlPanel: () {
            setState(() => _isControlPanelOpen = !_isControlPanelOpen);
          },
        ),
      ),
      body: body,
    );
  }
}
