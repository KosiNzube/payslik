import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterWebView extends StatefulWidget {

  final String link;

  const RegisterWebView({super.key, required this.link});
  @override
  State<RegisterWebView> createState() => _RegisterWebViewState();
}

class _RegisterWebViewState extends State<RegisterWebView> with SingleTickerProviderStateMixin {
  late final WebViewController controller;
  bool isLoading = true;
  String? logoUrl;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _loadLogo();
    _initializeWebView();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadLogo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      logoUrl = prefs.getString('org_logo');
    });
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => isLoading = false);
            }
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: logoUrl != null
                            ? Image.network(
                                logoUrl!,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 100),
                              )
                            : const CircularProgressIndicator(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}