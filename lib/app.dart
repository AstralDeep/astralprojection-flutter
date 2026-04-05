import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components/navigation/nav_bar.dart';
import 'components/common/loading_overlay.dart';
import 'components/common/offline_indicator.dart';
import 'components/sidebar/app_sidebar.dart';
import 'components/workspace/workspace_layout.dart';
import 'components/dynamic_renderer.dart';
import 'state/app_shell_provider.dart';
import 'state/token_storage_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TokenStorageProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppShellProvider()),
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final tokenStorage =
        Provider.of<TokenStorageProvider>(context, listen: false);

    // Load cached SDUI tree and tokens on startup
    ws.loadCachedTree();
    tokenStorage.loadCached().then((_) {
      _initWebSocket();
    });

    // Wire ui_action callbacks
    ws.onActionReceived = _handleUiAction;

    // Wire shell data callbacks
    _wireShellCallbacks();
  }

  void _wireShellCallbacks() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final shell = Provider.of<AppShellProvider>(context, listen: false);

    ws.onSystemConfig = (msg) => shell.updateFromSystemConfig(msg);
    ws.onHistoryList = (msg) => shell.updateFromHistoryList(msg);
    ws.onChatStatus = (msg) => shell.updateChatStatus(msg);
    ws.onAgentRegistered = (msg) => shell.addOrUpdateAgent(msg);
  }

  void _initWebSocket() {
    if (_initialized) return;
    _initialized = true;

    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final dp = Provider.of<DeviceProfileProvider>(context, listen: false);
    final tokenStorage =
        Provider.of<TokenStorageProvider>(context, listen: false);

    ws.connect(
      token: tokenStorage.token,
      device: dp.toDeviceMap(),
      capabilities: _sduiCapabilities,
    );
  }

  void _handleUiAction(String action, Map<String, dynamic> payload) {
    final tokenStorage =
        Provider.of<TokenStorageProvider>(context, listen: false);

    switch (action) {
      case 'open_url':
        final url = payload['url'] as String?;
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        break;
      case 'store_token':
        final token = payload['token'] as String? ?? '';
        final refreshToken = payload['refresh_token'] as String? ?? '';
        final expiresIn = payload['expires_in'] as int? ?? 300;
        tokenStorage.store(token, refreshToken, expiresIn);
        break;
      case 'clear_token':
        tokenStorage.clear();
        break;
    }
  }

  static const _sduiCapabilities = [
    'container', 'card', 'text', 'button', 'input', 'table', 'list',
    'alert', 'progress', 'metric', 'code', 'image', 'grid', 'tabs',
    'divider', 'bar_chart', 'line_chart', 'pie_chart', 'plotly_chart',
    'collapsible', 'color_picker', 'file_upload', 'file_download',
    'html_view', 'checkbox', 'stack_layout', 'webview',
  ];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateDeviceProfile();
  }

  void _updateDeviceProfile() {
    final mq = MediaQuery.of(context);
    final dp = Provider.of<DeviceProfileProvider>(context, listen: false);
    dp.updateFromMediaQuery(mq);
  }

  @override
  Widget build(BuildContext context) {
    // Update device profile on each build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDeviceProfile();
    });

    final ws = Provider.of<WebSocketProvider>(context);
    final dp = Provider.of<DeviceProfileProvider>(context);
    final shell = Provider.of<AppShellProvider>(context);
    final tokenStorage = Provider.of<TokenStorageProvider>(context);
    final isTv = dp.deviceType == 'tv';
    final isDesktop = dp.isDesktop;

    // Main content area: SDUI workspace + overlays
    Widget mainContent = Stack(
      children: [
        WorkspaceLayout(
          projectName:
              Provider.of<ProjectProvider>(context).currentProject?.name ?? '',
          wsStatus: Provider.of<ProjectProvider>(context)
              .projectConnectionStatus
              .name,
          hasRootElement: ws.hasReceivedRender || ws.components.isNotEmpty,
        ),
        if (ws.connected && !ws.hasReceivedRender && ws.components.isEmpty)
          const LoadingOverlay(),
        if (!ws.connected) const OfflineIndicator(),
      ],
    );

    // Wrap in TV focus manager if needed
    if (isTv) {
      mainContent = TvFocusManager(child: mainContent);
    }

    // Unauthenticated: centered login page without dashboard chrome
    if (!tokenStorage.hasToken) {
      return Scaffold(
        backgroundColor: AstralColors.background,
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final component in ws.components)
                        DynamicRenderer(component: component),
                    ],
                  ),
                ),
              ),
            ),
            if (ws.connected && !ws.hasReceivedRender && ws.components.isEmpty)
              const LoadingOverlay(),
            if (!ws.connected) const OfflineIndicator(),
          ],
        ),
      );
    }

    // Desktop: sidebar full-height on left, navbar+content on right.
    // Mobile: navbar on top, drawer for sidebar.
    if (isDesktop) {
      return Scaffold(
        backgroundColor: AstralColors.background,
        body: Row(
          children: [
            // Sidebar spans full screen height
            AppSidebar(
              collapsed: !shell.sidebarOpen,
              onToggle: () => shell.toggleSidebar(),
            ),
            // Navbar + content fill the rest
            Expanded(
              child: Column(
                children: [
                  const NavBar(),
                  Expanded(child: mainContent),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AstralColors.background,
      appBar: const NavBar(),
      drawer: Drawer(
        backgroundColor: AstralColors.surface,
        child: const AppSidebar(isDrawer: true),
      ),
      body: mainContent,
    );
  }
}
