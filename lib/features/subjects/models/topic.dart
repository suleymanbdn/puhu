import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'topic.g.dart';

/// Konunun çalışılma durumu
@HiveType(typeId: 7)
enum TopicStatus {
  /// Henüz başlanmadı
  @HiveField(0)
  notStarted,

  /// Çalışılıyor
  @HiveField(1)
  inProgress,

  /// Bitirildi
  @HiveField(2)
  completed,

  /// Tekrar lazım
  @HiveField(3)
  needsReview;

  String get title {
    switch (this) {
      case TopicStatus.notStarted:
        return 'Çalışmadım';
      case TopicStatus.inProgress:
        return 'Çalışıyorum';
      case TopicStatus.completed:
        return 'Bitirdim';
      case TopicStatus.needsReview:
        return 'Tekrar Lazım';
    }
  }

  Color get color {
    switch (this) {
      case TopicStatus.notStarted:
        return const Color(0xFF6B7280);
      case TopicStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TopicStatus.completed:
        return const Color(0xFF10B981);
      case TopicStatus.needsReview:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case TopicStatus.notStarted:
        return Icons.radio_button_unchecked;
      case TopicStatus.inProgress:
        return Icons.play_circle_outline;
      case TopicStatus.completed:
        return Icons.check_circle_outline;
      case TopicStatus.needsReview:
        return Icons.refresh;
    }
  }
}

/// YKS Konu modeli
///
/// Her bir ders konusu (örn. "Türev", "Üslü Sayılar") için
/// kullanıcının ilerleme durumunu, harcadığı süreyi ve çözdüğü
/// soru sayısını tutar.
@HiveType(typeId: 8)
class Topic extends HiveObject {
  @HiveField(0)
  final String id;

  /// Subject.id (örn. "tyt_matematik")
  @HiveField(1)
  final String subjectId;

  /// Konu adı (curriculum'dan gelen)
  @HiveField(2)
  final String name;

  @HiveField(3)
  final TopicStatus status;

  /// Bu konuda harcanan toplam çalışma süresi (dakika)
  @HiveField(4)
  final int totalMinutes;

  @HiveField(5)
  final DateTime? lastStudiedAt;

  @HiveField(6)
  final int questionsSolved;

  @HiveField(7)
  final int correctCount;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final DateTime createdAt;

  /// Spaced repetition için: bir sonraki tekrar zamanı
  @HiveField(10)
  final DateTime? nextReviewAt;

  Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    this.status = TopicStatus.notStarted,
    this.totalMinutes = 0,
    this.lastStudiedAt,
    this.questionsSolved = 0,
    this.correctCount = 0,
    this.notes,
    DateTime? createdAt,
    this.nextReviewAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Doğru cevap oranı (0-1)
  double get correctRatio {
    if (questionsSolved == 0) return 0;
    return correctCount / questionsSolved;
  }

  /// Yanlış cevap sayısı
  int get wrongCount => questionsSolved - correctCount;

  /// Toplam saat
  double get totalHours => totalMinutes / 60;

  Topic copyWith({
    String? id,
    String? subjectId,
    String? name,
    TopicStatus? status,
    int? totalMinutes,
    DateTime? lastStudiedAt,
    int? questionsSolved,
    int? correctCount,
    String? notes,
    DateTime? createdAt,
    DateTime? nextReviewAt,
    bool clearLastStudiedAt = false,
    bool clearNextReviewAt = false,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      status: status ?? this.status,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      lastStudiedAt: clearLastStudiedAt
          ? null
          : (lastStudiedAt ?? this.lastStudiedAt),
      questionsSolved: questionsSolved ?? this.questionsSolved,
      correctCount: correctCount ?? this.correctCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      nextReviewAt:
          clearNextReviewAt ? null : (nextReviewAt ?? this.nextReviewAt),
    );
  }
}
