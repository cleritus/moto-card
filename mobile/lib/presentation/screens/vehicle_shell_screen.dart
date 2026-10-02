import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../widgets/workshop_icons.dart';
import 'fuel_log_list_screen.dart';
import 'photo_list_screen.dart';
import 'reminder_list_screen.dart';
import 'service_log_list_screen.dart';
import 'vehicle_overview_screen.dart';

/// Tabbed wrapper for a single vehicle: physical swipe (PageView) synced
/// with the flat bottom bar from §6.
///
/// The "label on the toolbox" metaphor moves from the desktop mock's sidebar
/// onto the bottom bar: flat, `grease`, 2 px steel top edge, the active tab
/// in oxideLit with a 3 px annunciator strip above the label. No floating
/// pill, no Material BottomNavigationBar.
///
/// Labels are shortened on purpose (§6): at five tabs on 390 px even
/// condensed `TANKOWANIE` and `PRZYPOMNIENIA` do not fit — they become
/// `PALIWO` and `ALERTY`.
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

  static const List<_Tab> _tabs = [
    _Tab('POJAZD', WorkshopIconKind.vehicle),
    _Tab('PALIWO', WorkshopIconKind.fuel),
    _Tab('SERWIS', WorkshopIconKind.wrench),
    _Tab('ALERTY', WorkshopIconKind.bell),
    _Tab('FOTO', WorkshopIconKind.camera),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      VehicleOverviewScreen(
        id: widget.vehicleId,
        onOpenServiceBook: () => _onTabTapped(2),
      ),
      FuelLogListScreen(vehicleId: widget.vehicleId),
      ServiceLogListScreen(vehicleId: widget.vehicleId),
      ReminderListScreen(vehicleId: widget.vehicleId),
      PhotoListScreen(vehicleId: widget.vehicleId),
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
      body: Column(
        children: [
          const _BackToGarage(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _AnnunciatorBar(
        tabs: _tabs,
        index: _index,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// The only way out of a vehicle's 5-tab shell back to the garage list —
/// every tab below dropped its AppBar (and the free back arrow that came
/// with it) in favor of tab-style headers, so without this, nothing in any
/// of the 5 tabs can return to /vehicles.
class _BackToGarage extends StatelessWidget {
  const _BackToGarage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppGeo.screenMargin,
          10,
          AppGeo.screenMargin,
          0,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                '← GARAŻ',
                style: AppText.micro(color: AppColors.oxideLit),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon);

  final String label;
  final WorkshopIconKind icon;
}

class _AnnunciatorBar extends StatelessWidget {
  const _AnnunciatorBar({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.grease,
        border: Border(top: BorderSide(color: AppColors.steel, width: 2)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++)
              Expanded(
                child: _AnnunciatorTab(
                  tab: tabs[i],
                  active: i == index,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnnunciatorTab extends StatelessWidget {
  const _AnnunciatorTab({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final _Tab tab;
  final bool active;
  final VoidCallback onTap;

  /// Inactive label tone from the preview — reads 4.1:1 on grease, and the
  /// active tab additionally carries the annunciator strip, so colour is
  /// never the only signal.
  static const Color _inactive = Color(0xFF8A8276);

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.oxideLit : _inactive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: SizedBox(
              height: 3,
              child: ColoredBox(
                color: active ? AppColors.oxideOrange : Colors.transparent,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                WorkshopIcon(kind: tab.icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text(
                  tab.label,
                  style: AppText.button(size: 11.5, color: color)
                      .copyWith(letterSpacing: 11.5 * 0.09),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
