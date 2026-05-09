import 'package:flutter/material.dart';

/// YKS sınav tipleri
enum ExamTypeFilter { tyt, sayisal, esitAgirlik, sozel, dil }

/// YKS dersleri (TYT ve AYT)
///
/// Bu enum Hive'a kaydedilmez; sadece bir dersin kimliğidir.
/// Topic ve TimeBudget gibi Hive modelleri `subjectId` (Subject.id) String'i tutar.
enum Subject {
  // TYT
  tytTurkce(
    id: 'tyt_turkce',
    title: 'Türkçe',
    examPart: 'TYT',
    questionCount: 40,
    color: Color(0xFFEF4444),
    icon: Icons.menu_book_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytMatematik(
    id: 'tyt_matematik',
    title: 'Matematik',
    examPart: 'TYT',
    questionCount: 30,
    color: Color(0xFF3B82F6),
    icon: Icons.calculate_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytGeometri(
    id: 'tyt_geometri',
    title: 'Geometri',
    examPart: 'TYT',
    questionCount: 10,
    color: Color(0xFF6366F1),
    icon: Icons.architecture_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytFizik(
    id: 'tyt_fizik',
    title: 'Fizik',
    examPart: 'TYT',
    questionCount: 7,
    color: Color(0xFF8B5CF6),
    icon: Icons.bolt_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytKimya(
    id: 'tyt_kimya',
    title: 'Kimya',
    examPart: 'TYT',
    questionCount: 7,
    color: Color(0xFF10B981),
    icon: Icons.science_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytBiyoloji(
    id: 'tyt_biyoloji',
    title: 'Biyoloji',
    examPart: 'TYT',
    questionCount: 6,
    color: Color(0xFF14B8A6),
    icon: Icons.biotech_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytTarih(
    id: 'tyt_tarih',
    title: 'Tarih',
    examPart: 'TYT',
    questionCount: 5,
    color: Color(0xFFF59E0B),
    icon: Icons.history_edu_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytCografya(
    id: 'tyt_cografya',
    title: 'Coğrafya',
    examPart: 'TYT',
    questionCount: 5,
    color: Color(0xFF0EA5E9),
    icon: Icons.public_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytFelsefe(
    id: 'tyt_felsefe',
    title: 'Felsefe',
    examPart: 'TYT',
    questionCount: 5,
    color: Color(0xFF78716C),
    icon: Icons.psychology_outlined,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),
  tytDin(
    id: 'tyt_din',
    title: 'Din Kültürü',
    examPart: 'TYT',
    questionCount: 5,
    color: Color(0xFF92400E),
    icon: Icons.menu_book_rounded,
    inExamTypes: {ExamTypeFilter.tyt, ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel, ExamTypeFilter.dil},
  ),

  // AYT
  aytMatematik(
    id: 'ayt_matematik',
    title: 'AYT Matematik',
    examPart: 'AYT',
    questionCount: 30,
    color: Color(0xFF1D4ED8),
    icon: Icons.functions_outlined,
    inExamTypes: {ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik},
  ),
  aytGeometri(
    id: 'ayt_geometri',
    title: 'AYT Geometri',
    examPart: 'AYT',
    questionCount: 10,
    color: Color(0xFF4338CA),
    icon: Icons.architecture,
    inExamTypes: {ExamTypeFilter.sayisal, ExamTypeFilter.esitAgirlik},
  ),
  aytFizik(
    id: 'ayt_fizik',
    title: 'AYT Fizik',
    examPart: 'AYT',
    questionCount: 14,
    color: Color(0xFF7C3AED),
    icon: Icons.electric_bolt,
    inExamTypes: {ExamTypeFilter.sayisal},
  ),
  aytKimya(
    id: 'ayt_kimya',
    title: 'AYT Kimya',
    examPart: 'AYT',
    questionCount: 13,
    color: Color(0xFF059669),
    icon: Icons.science,
    inExamTypes: {ExamTypeFilter.sayisal},
  ),
  aytBiyoloji(
    id: 'ayt_biyoloji',
    title: 'AYT Biyoloji',
    examPart: 'AYT',
    questionCount: 13,
    color: Color(0xFF0F766E),
    icon: Icons.biotech,
    inExamTypes: {ExamTypeFilter.sayisal},
  ),
  aytEdebiyat(
    id: 'ayt_edebiyat',
    title: 'Edebiyat',
    examPart: 'AYT',
    questionCount: 24,
    color: Color(0xFFDC2626),
    icon: Icons.auto_stories_outlined,
    inExamTypes: {ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel},
  ),
  aytTarih1(
    id: 'ayt_tarih1',
    title: 'Tarih-1',
    examPart: 'AYT',
    questionCount: 10,
    color: Color(0xFFD97706),
    icon: Icons.history_edu,
    inExamTypes: {ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel},
  ),
  aytCografya1(
    id: 'ayt_cografya1',
    title: 'Coğrafya-1',
    examPart: 'AYT',
    questionCount: 6,
    color: Color(0xFF0284C7),
    icon: Icons.public,
    inExamTypes: {ExamTypeFilter.esitAgirlik, ExamTypeFilter.sozel},
  ),
  aytTarih2(
    id: 'ayt_tarih2',
    title: 'Tarih-2',
    examPart: 'AYT',
    questionCount: 11,
    color: Color(0xFFB45309),
    icon: Icons.castle_outlined,
    inExamTypes: {ExamTypeFilter.sozel},
  ),
  aytCografya2(
    id: 'ayt_cografya2',
    title: 'Coğrafya-2',
    examPart: 'AYT',
    questionCount: 11,
    color: Color(0xFF075985),
    icon: Icons.terrain_outlined,
    inExamTypes: {ExamTypeFilter.sozel},
  ),
  aytFelsefeGrubu(
    id: 'ayt_felsefe_grubu',
    title: 'Felsefe Grubu',
    examPart: 'AYT',
    questionCount: 12,
    color: Color(0xFF57534E),
    icon: Icons.psychology,
    inExamTypes: {ExamTypeFilter.sozel},
  ),
  aytDin(
    id: 'ayt_din',
    title: 'AYT Din',
    examPart: 'AYT',
    questionCount: 6,
    color: Color(0xFF78350F),
    icon: Icons.book,
    inExamTypes: {ExamTypeFilter.sozel},
  ),

  // YDT (Dil)
  ydtIngilizce(
    id: 'ydt_ingilizce',
    title: 'İngilizce (YDT)',
    examPart: 'YDT',
    questionCount: 80,
    color: Color(0xFFEC4899),
    icon: Icons.language_outlined,
    inExamTypes: {ExamTypeFilter.dil},
  );

  const Subject({
    required this.id,
    required this.title,
    required this.examPart,
    required this.questionCount,
    required this.color,
    required this.icon,
    required this.inExamTypes,
  });

  final String id;
  final String title;
  final String examPart; // TYT / AYT / YDT
  final int questionCount;
  final Color color;
  final IconData icon;
  final Set<ExamTypeFilter> inExamTypes;

  /// Verilen sınav tipi için aktif dersleri döndürür
  static List<Subject> forExamType(ExamTypeFilter type) {
    return Subject.values.where((s) => s.inExamTypes.contains(type)).toList();
  }

  /// id'den Subject bul (yoksa null)
  static Subject? fromId(String id) {
    try {
      return Subject.values.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
