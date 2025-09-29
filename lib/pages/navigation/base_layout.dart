import 'package:flutter/material.dart';
import 'package:gobeller/dashboard_page_multi_wallets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/pages/success/dashboard_page_1.dart';
import 'package:gobeller/pages/wallet/wallet_page.dart';
import 'package:gobeller/pages/borrowers/borrowers.dart';
import 'package:gobeller/pages/cards/virtual_card_page.dart';
import 'package:gobeller/pages/profile/profile_page.dart';
import '../success/7G_DASHBOARD.dart';
import '../success/DASHBOARD_Y.dart';
import 'bottom_nav.dart';
import 'dart:convert';

class BaseLayout extends StatefulWidget {
  final int initialIndex;

  const BaseLayout({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  late int _currentIndex;
  late List<Widget> _pages;
  bool _showPropertyMenu = false;
  bool _isVirtualCardEnabled = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadOrganizationSettings();
  }

  Future<void> _loadOrganizationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final orgDataJson = prefs.getString('organizationData');

    if (orgDataJson != null) {
      try {
        final orgData = json.decode(orgDataJson);
        final menuItems = orgData['data']?['customized_app_displayable_menu_items'] ??
            orgData['customized_app_displayable_menu_items'];

        setState(() {
          _showPropertyMenu = menuItems?['display-property-menu'] == true;
          _isVirtualCardEnabled = menuItems?['display-virtual-card-menu'] == true;
          _pages = _buildPages();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _showPropertyMenu = false;
          _isVirtualCardEnabled=false;
          _pages = _buildPages();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _showPropertyMenu = false;
        _isVirtualCardEnabled=false;

        _pages = _buildPages();
        _isLoading = false;
      });
    }
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      const DashboardPage7G(),
      const WalletPage(),
    ];

    // Add PropertyListPage only if enabled
    if (_showPropertyMenu) {
      pages.add(const PropertyListPage());
    }

    if(_isVirtualCardEnabled){
      pages.add(const VirtualCardPage());

    }

    pages.addAll([
      const ProfilePage(),
    ]);

    return pages;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: BottomNav(

          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          showPropertyTab: _showPropertyMenu,
          showVirtualCard: _isVirtualCardEnabled
        ),
      ),
    );
  }
}