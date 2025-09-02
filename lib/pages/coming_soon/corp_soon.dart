import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> with SingleTickerProviderStateMixin {
  Color? _primaryColor;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the controller immediately
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _loadSettings(); // async method can now safely call setState later
  }


  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final primaryColorHex = settings['customized-app-primary-color'] ?? '#171E3B';
      _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Corporate Account"),
        backgroundColor: _primaryColor ?? Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _controller,
                child: Icon(Icons.hourglass_empty, size: 80, color: _primaryColor ?? Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                "Coming next on our upgrade...",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor ?? Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Start building your credit score to be the first to benefit from the service by transacting more.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
