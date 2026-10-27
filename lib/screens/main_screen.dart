import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'settings/settings_screen.dart';
import 'quick_add/quick_add_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardScreen(
        onSelectCategory: (categoryId) {
          QuickAddSheet.show(context, categoryId: categoryId);
        },
      ),
      const TransactionsScreen(),
      const SettingsScreen(),
    ];

    return Container(
      color: isDark ? const Color(0xFF090D16) : const Color(0xFFE2E8F0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            floatingActionButton: _currentIndex != 2
                ? FloatingActionButton.extended(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      QuickAddSheet.show(context);
                    },
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text(
                      'Catat',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                  )
                : null,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabChanged,
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: AppColors.primary.withOpacity(0.18),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                    label: 'Ringkasan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                    label: 'Transaksi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
                    label: 'Pengaturan',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
