import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'glass_container.dart';

/// Ana scaffold — arkasında gradient, altında yüzen cam navigasyon barı.
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Bar arkasındaki gradient görünsün
      body: Container(
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
        child: navigationShell,
      ),
      bottomNavigationBar: _GlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Yüzen cam navigasyon barı — kenarlardan boşluklu, ekranın altına sabit.
///
/// Material `NavigationBar` yerine elle yazıldı: safe-area inset'i ve
/// indicator hap davranışı cam kutu içinde istenmeyen boşluklar
/// yaratıyordu. Burada yükseklik ve hizalama tamamen kontrol altında.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Anasayfa'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Dersler'),
    _NavItem(Icons.timer_outlined, Icons.timer_rounded, 'Çalış'),
    _NavItem(Icons.edit_note_outlined, Icons.edit_note_rounded, 'Soru'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analiz'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Alt: home indicator yüksekliği (varsa) + nefes payı.
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 12 : 16),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF12102A) : Colors.white,
        // Arkadan geçen parlak kartlar (ör. Puhu+ promo) bar ile tek parça
        // görünmesin diye opaklık yüksek tutuluyor.
        colorOpacity: isDark ? 0.82 : 0.85,
        blur: 24,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavButton(
                  item: _items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withAlpha(140);
    final color = selected ? primary : muted;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        highlightColor: Colors.transparent,
        splashColor: primary.withAlpha(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Seçili sekmede ikonun arkasında hafif vurgu hapı.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? primary.withAlpha(40) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
