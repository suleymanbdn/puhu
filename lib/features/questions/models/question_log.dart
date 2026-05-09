import 'package:hive_flutter/hive_flutter.dart';

part 'question_log.g.dart';

/// Soru çözüm günlüğü kaydı
///
/// Bir oturumda çözülen sorular için tek satır. Net hesabı için
/// `correct - wrong/4` formülü kullanılır (YKS standardı).
@HiveType(typeId: 11)
class QuestionLog extends HiveObject {
  @HiveField(0)
  final String id;

  /// Subject.id (örn. "tyt_matematik")
  @HiveField(1)
  final String subjectId;

  /// İsteğe bağlı konu id'si — null ise genel konu çözümü
  @HiveField(2)
  final String? topicId;

  @HiveField(3)
  final int correct;

  @HiveField(4)
  final int wrong;

  @HiveField(5)
  final int blank;

  /// Çözüm tarihi (gün başlangıcına yuvarlanmaz; orijinal an saklanır)
  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String? note;

  QuestionLog({
    required this.id,
    required this.subjectId,
    this.topicId,
    required this.correct,
    required this.wrong,
    required this.blank,
    required this.date,
    this.note,
  });

  /// Toplam soru
  int get total => correct + wrong + blank;

  /// Net (YKS: correct - wrong/4)
  double get net => correct - (wrong / 4);

  /// Doğruluk oranı (çözülen sorular üzerinden, boşlar hariç)
  double get accuracy {
    final attempted = correct + wrong;
    if (attempted == 0) return 0;
    return correct / attempted;
  }

  QuestionLog copyWith({
    String? id,
    String? subjectId,
    String? topicId,
    int? correct,
    int? wrong,
    int? blank,
    DateTime? date,
    String? note,
  }) {
    return QuestionLog(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      blank: blank ?? this.blank,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
