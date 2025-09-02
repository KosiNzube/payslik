import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showPropertyTab;

  final bool showVirtualCard;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showPropertyTab = false, required this.showVirtualCard,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
  }

  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final primaryColorHex = data['customized-app-primary-color'];
          final secondaryColorHex = data['customized-app-secondary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;
        });
      } catch (_) {}
    }
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.home),
        activeIcon: Icon(CupertinoIcons.house),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.wallet,),
        activeIcon: Icon(Icons.wallet),
        label: 'Wallet',
      ),
    ];

    // Add Properties tab conditionally
    if (widget.showPropertyTab) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard_outlined),
          activeIcon: Icon(Icons.card_giftcard_outlined),
          label: 'Properties',
        ),
      );
    }

    if (widget.showVirtualCard) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.creditcard),
          activeIcon: Icon(CupertinoIcons.creditcard),
          label: 'Cards',
        ),
      );
    }


    items.addAll([

      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person_alt_circle),
        activeIcon: Icon(CupertinoIcons.person_alt_circle_fill),
        label: 'Profile',
      ),
    ]);

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor ?? Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:  GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle:  GoogleFonts.poppins(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: _buildNavigationItems(),
      ),
    );
  }
}