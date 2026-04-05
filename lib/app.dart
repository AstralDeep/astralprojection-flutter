import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components/navigation/nav_bar.dart';
import 'components/common/loading_overlay.dart';
import 'components/common/offline_indicator.dart';
import 'components/workspace/workspace_layout.dart';
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
        ChangeNotifierProvider(create: (_) => TokenStorageProvider()),
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
  }

  void _initWebSocket() {
    if (_initialized) return;
    _initialized = true;

    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final dp = Provider.of<DeviceProfileProvider>(context, listen: false);
    final tokenStorage =
        Provider.of<TokenStorageProvider>(context, listen: false);

    // Connect immediately — token is optional.
    // Backend sends SDUI login page if unauthenticated, or dashboard if valid.
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

  /// The SDUI primitive types this client can render.
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
    // Update device profile on each build (captures initial + changes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDeviceProfile();
    });

    final ws = Provider.of<WebSocketProvider>(context);
    final dp = Provider.of<DeviceProfileProvider>(context);
    final isTv = dp.deviceType == 'tv';

    Widget body = Stack(
      children: [
        WorkspaceLayout(
          projectName:
              Provider.of<ProjectProvider>(context).currentProject?.name ?? '',
          wsStatus: Provider.of<ProjectProvider>(context)
              .projectConnectionStatus
              .name,
          hasRootElement: ws.hasReceivedRender || ws.components.isNotEmpty,
        ),
        // Loading overlay: shown while connecting and before first ui_render
        if (ws.connected && !ws.hasReceivedRender && ws.components.isEmpty)
          const LoadingOverlay(),
        // Offline indicator: shown when connection is lost
        if (!ws.connected) const OfflineIndicator(),
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
