import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/controller/organization_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../webview/register_webview.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  bool _hasFetched = false;
  bool _hasRetried = false;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();

    _initializeVideo();
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );
    _logoController.forward();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('');
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.setVolume(0.0);
    _videoController.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logoController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasFetched) {
      final orgController = Provider.of<OrganizationController>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await orgController.loadCachedData();
        await orgController.fetchOrganizationData();
        await orgController.fetchSupportDetails();

        if ((orgController.organizationData == null || orgController.appSettingsData == null) && !_hasRetried) {
          _hasRetried = true;
          Future.delayed(const Duration(seconds: 3), () async {
            debugPrint("🔁 Retrying organization data fetch...");
            await orgController.fetchOrganizationData();
            await orgController.fetchSupportDetails();
          });
        }
      });

      _hasFetched = true;
    }
  }

  Widget _buildAnimatedBackground(Color primaryColor, Color secondaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            secondaryColor.withOpacity(0.2),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 3.seconds,
      color: primaryColor.withOpacity(0.3),
    );
  }

  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final userData = prefs.getString('user');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      // User has logged in before, navigate to login page
      // Use a slight delay to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(Routes.login);
        // or if you're using your routes constants:
        // Navigator.of(context).pushReplacementNamed(YourRoutesClass.login);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationController>(
      builder: (context, orgController, child) {
        final isLoading = orgController.isLoading;
        final hasError = orgController.organizationData == null || orgController.appSettingsData == null;

        final settings = orgController.appSettingsData?['data'] ?? {};
        final orgData = orgController.organizationData?['data'] ?? {};

        final primaryColorHex = settings['customized-app-primary-color'] ?? '#6200EE';
        final tertiaryColorHex = settings['customized-app-tertiary-color'] ?? '#000000';
        final logoUrl = settings['customized-app-logo-url'];
        final welcomeTitle = "Welcome to ${orgData['short_name'] ?? 'Our Platform'}";
        final welcomeDescription = orgData['description'] ?? "We are here to help you achieve your goals.";

        final primaryColor = parseColor(primaryColorHex, fallbackHex: '#6200EE');
        final tertiaryColor = parseColor(tertiaryColorHex, fallbackHex: '#000000');

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Video Background
              if (_videoController.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),

              // Dark Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : hasError
                    ? _buildErrorState(context)
                    : _buildMainContent(
                  context,
                  logoUrl,
                  welcomeTitle,
                  welcomeDescription,
                  primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
      BuildContext context,
      String? logoUrl,
      String welcomeTitle,
      String welcomeDescription,
      Color primaryColor,
      ) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: ConstUI.kMainPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logoUrl != null)
                  FadeInDown(
                    duration: const Duration(milliseconds: 1200),
                    child: ScaleTransition(
                      scale: _logoAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          httpHeaders: const {
                            'User-Agent': 'Flutter App',
                            'Accept': 'image/png, image/jpeg, image/jpg, image/gif, image/webp, image/*',
                          },
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) {
                            debugPrint('Failed to load image: $url');
                            debugPrint('Error: $error');
                            return const Icon(Icons.error_outline, size: 60);
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    welcomeTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 700),
                  child: Text(
                    welcomeDescription,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        FadeInUp(
          duration: const Duration(milliseconds: 1000),
          delay: const Duration(milliseconds: 900),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildButton(
                    context: context,
                    text: "Login",
                    isOutlined: true,
                    onPressed: () => Navigator.pushNamed(context, Routes.login),
                    customColor: primaryColor, // Add this
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildButton(
                    context: context,
                    text: "Register",
                    isOutlined: false,
                    onPressed: () {
                      final orgController = Provider.of<OrganizationController>(context, listen: false);
                      final orgData = orgController.organizationData?['data'] ?? {};
                      final identityCode = orgData['org_identity_code'] ?? '';

                      if (identityCode == '0053') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  RegisterWebView(link: 'https://app.easy-buyandowncooperative.com/register',),
                          ),
                        );
                      } else if(identityCode == '0068'){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  RegisterWebView(link: 'https://fxoracleaiglobal.com/',),
                          ),
                        );
                      }


                      else {
                        Navigator.pushNamed(context, '/register');
                      }
                    },
                    customColor: primaryColor, // Add this
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required bool isOutlined,
    required VoidCallback onPressed,
    Color? customColor, // Add this parameter
  }) {
    final color = customColor ?? Theme.of(context).primaryColor;

    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isOutlined
            ? null
            : [
          BoxShadow(
            color: color.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(30),
        color: isOutlined ? Colors.transparent : color,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: isOutlined
                ? BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color,
                width: 2,
              ),
            )
                : null,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isOutlined ? color : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    // Get the OrganizationController to access app settings
    final orgController = Provider.of<OrganizationController>(context, listen: false);
    final settings = orgController.appSettingsData?['data'] ?? {};
    final primaryColorHex = settings['customized-app-primary-color'] ?? '#6200EE';
    final primaryColor = parseColor(primaryColorHex, fallbackHex: '#6200EE');

    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 1000),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildButton(
                context: context,
                text: "Retry",
                isOutlined: false,
                onPressed: () {
                  setState(() {
                    _hasFetched = false;
                    _hasRetried = false;
                  });
                },
                customColor: primaryColor, // Now primaryColor is defined
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color parseColor(String hexColor, {required String fallbackHex}) {
  try {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      return Color(int.parse("FF$hexColor", radix: 16));
    }
    return Color(int.parse(fallbackHex.replaceAll("#", "FF"), radix: 16));
  } catch (e) {
    return Color(int.parse(fallbackHex.replaceAll("#", "FF"), radix: 16));
  }
}
