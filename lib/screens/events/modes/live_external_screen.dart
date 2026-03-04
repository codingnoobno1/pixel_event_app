import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/live_activity.dart';
import '../../../models/models.dart';

/// Screen for external activities (hacking games, external platforms).
/// Opens the configured URL in a full-screen WebView.
class LiveExternalScreen extends StatefulWidget {
  final Event event;
  final String participantId;
  final LiveActivity activity;

  const LiveExternalScreen({
    super.key,
    required this.event,
    required this.participantId,
    required this.activity,
  });

  @override
  State<LiveExternalScreen> createState() => _LiveExternalScreenState();
}

class _LiveExternalScreenState extends State<LiveExternalScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _webViewReady = false;

  static const _bg = Color(0xFF0B0B0F);
  static const _purple = Color(0xFFA855F7);

  @override
  void initState() {
    super.initState();
    final url = widget.activity.external?.url;
    if (url != null && url.isNotEmpty) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ))
        ..loadRequest(Uri.parse(url));
      setState(() => _webViewReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = widget.activity.external;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.activity.title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                '${ext?.points ?? 0} PTS · ${ext?.durationMinutes ?? 0}MIN',
                style: const TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.w900),
              ),
              backgroundColor: _purple.withOpacity(0.12),
              side: BorderSide(color: _purple.withOpacity(0.3)),
            ),
          ),
        ],
      ),
      body: _webViewReady
          ? Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: _purple),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.open_in_new, color: _purple, size: 40),
                  ).animate().scale(),
                  const SizedBox(height: 20),
                  const Text(
                    'No URL configured for this activity',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
