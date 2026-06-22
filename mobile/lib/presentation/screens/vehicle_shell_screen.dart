import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import 'fuel_log_list_screen.dart';
import 'reminder_list_screen.dart';
import 'service_log_list_screen.dart';
import 'vehicle_overview_screen.dart';

/// Tabbed wrapper for a single vehicle: physical swipe (PageView) synced with a
/// BottomNavigationBar. Each tab provides its own AppBar.
class VehicleShellScreen extends StatefulWidget {
  const VehicleShellScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<VehicleShellScreen> createState() => _VehicleShellScreenState();
}

class _VehicleShellScreenState extends State<VehicleShellScreen> {
  final PageController _pageController = PageController();
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      VehicleOverviewScreen(id: widget.vehicleId),
      FuelLogListScreen(vehicleId: widget.vehicleId),
      ServiceLogListScreen(vehicleId: widget.vehicleId),
      ReminderListScreen(vehicleId: widget.vehicleId),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkLabel,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'POJAZD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'TANKOWANIE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'SERWIS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'PRZYPOMNIENIA',
          ),
        ],
      ),
    );
  }
}
