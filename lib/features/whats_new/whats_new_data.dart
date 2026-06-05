import 'package:flutter/material.dart';

/// "Bu sürümde yeni" ekranı için tek bir versiyon kaydı.
class WhatsNewEntry {
  final String version;
  final String headline;
  final String subhead;
  final List<WhatsNewItem> items;

  const WhatsNewEntry({
    required this.version,
    required this.headline,
    required this.subhead,
    required this.items,
  });
}

class WhatsNewItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String? routeOnTap;

  const WhatsNewItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.routeOnTap,
  });
}

/// Mevcut versiyonun "yeni" içeriği. Tek bir kayıt — App Store'a kadar
/// biriken tüm sprint'ler (1.1.2 → 1.1.7) buradan tanıtılır.
const String kCurrentWhatsNewVersion = '1.1.7';
