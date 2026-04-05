import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Renders an embedded WebView that loads a URL and optionally intercepts
/// navigation to a specific URL prefix, extracting query parameters and
/// sending them back to the backend as a ui_event.
///
/// Schema: { type: "webview", url: "string", intercept_url: "string",
///           intercept_action: "string" }
class WebViewWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const WebViewWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<WebViewWidget> createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<WebViewWidget> {
  bool _loading = true;
  bool _intercepted = false;

  @override
  Widget build(BuildContext context) {
    final url = widget.component['url'] as String? ?? '';
    final interceptUrl = widget.component['intercept_url'] as String? ?? '';
    final interceptAction =
        widget.component['intercept_action'] as String? ?? '';

    if (url.isEmpty) {
      return const Center(child: Text('No URL provided'));
    }

    final webview = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        javaScriptEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final navUrl = navigationAction.request.url?.toString() ?? '';

        // Intercept the callback URL before the HTTP request is made
        if (interceptUrl.isNotEmpty &&
            interceptAction.isNotEmpty &&
            navUrl.startsWith(interceptUrl) &&
            !_intercepted) {
          _intercepted = true;

          // Extract all query parameters from the redirect URL
          final uri = Uri.parse(navUrl);
          final params = <String, dynamic>{};
          uri.queryParameters.forEach((key, value) {
            params[key] = value;
          });

          // Send the params (code, state, etc.) to the backend via WS
          widget.sendEvent(interceptAction, params);

          // Cancel navigation — don't load the callback URL
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
      onLoadStop: (controller, url) {
        if (mounted) {
          setState(() => _loading = false);
        }
      },
      onLoadStart: (controller, url) {
        if (mounted && !_loading) {
          setState(() => _loading = true);
        }
      },
      onReceivedError: (controller, request, error) {
        if (_intercepted) return;
        if (mounted) {
          setState(() => _loading = false);
        }
      },
    );

    // InAppWebView requires bounded constraints. When placed inside a
    // ScrollView or Column with unbounded height, use LayoutBuilder to
    // fill the available viewport height.
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        // RepaintBoundary isolates the platform view to prevent
        // mouse_tracker assertion errors on Windows desktop.
        return RepaintBoundary(
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                webview,
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }
}
