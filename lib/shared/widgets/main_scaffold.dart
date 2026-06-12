import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'glass_container.dart';

/// Ana scaffold — dikkat çekici premium UI
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Gradient TÜM scaffold'ı sarar: bar bölgesinin arkası da gradient
    // olur. extendBody kapalı → içerik camın arkasına akıp blur'da parlak
    // blok oluşturmaz; cam yalnızca gradient'i süzer.
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF1E1B4B), // Indigo 950
                  Color(0xFF000000), // Black
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                ],
              ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 28, top: 0),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? Colors.black : Colors.white,
          colorOpacity: isDark ? 0.4 : 0.7,
          blur: 20,
          // NavigationBar, safe-area alt dolgusunu kendi içine alıp camı
          // uzatıyordu — dolguyu kaldır, boşluğu dıştaki Padding yönetir.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Default 80 çok yüksek — buğulu bar ekranı yiyordu.
            height: 60,
            indicatorColor: theme.colorScheme.primary.withAlpha(50),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Anasayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Dersler',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer_rounded),
                label: 'Çalış',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note_rounded),
                label: 'Soru',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Analiz',
              ),
            ],
          ),
          ),
        ),
      ),
    ));
  }
}
