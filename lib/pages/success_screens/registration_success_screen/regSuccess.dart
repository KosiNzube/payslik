import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationSuccessPage extends StatefulWidget {
  const RegistrationSuccessPage({super.key});

  @override
  State<RegistrationSuccessPage> createState() => _RegistrationSuccessPageState();
}

class _RegistrationSuccessPageState extends State<RegistrationSuccessPage> {
  Color _primaryColor = Colors.blueAccent;
  Color _secondaryColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _loadAppColors();
  }

  Future<void> _loadAppColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        final primaryHex = data['customized-app-primary-color'];
        final secondaryHex = data['customized-app-secondary-color'];

        setState(() {
          _primaryColor = primaryHex != null
              ? Color(int.parse(primaryHex.replaceAll('#', '0xFF')))
              : _primaryColor;

          _secondaryColor = secondaryHex != null
              ? Color(int.parse(secondaryHex.replaceAll('#', '0xFF')))
              : _secondaryColor;
        });
      } catch (e) {
        debugPrint('❌ Failed to load theme colors: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration Successful"),
        automaticallyImplyLeading: false,
        backgroundColor: _primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: _secondaryColor, size: 100),
            const SizedBox(height: 20),
            const Text(
              "Your registration was successful. Kindly log in within some minutes.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.dashboard),
                label: const Text("Go to Login"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white, // 👈 This sets the text and icon color to white
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
