import 'package:hive_flutter/hive_flutter.dart';

import '../../exam/models/exam_profile.dart';

part 'mock_exam.g.dart';

/// Deneme sınavı kaydı
///
/// Kullanıcı deneme çözdükten sonra ders bazlı net'leri girer.
/// `subjectNets` Map<Subject.id, double>; toplam net otomatik hesaplanır.
@HiveType(typeId: 12)
class MockExam extends HiveObject {
  @HiveField(0)
  final String id;

  /// Yayın adı (örn. "Karekök 5", "Limit Yayınları Deneme 3")
  @HiveField(1)
  final String publisher;

  /// Deneme tarihi
  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final ExamType examType;

  /// Subject.id → net
  @HiveField(4)
  final Map<String, double> subjectNets;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final DateTime createdAt;

  MockExam({
    required this.id,
    required this.publisher,
    required this.date,
    required this.examType,
    required this.subjectNets,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Toplam net
  double get totalNet =>
      subjectNets.values.fold(0.0, (sum, n) => sum + n);

  /// Bir derse ait net
  double netFor(String subjectId) => subjectNets[subjectId] ?? 0;

  MockExam copyWith({
    String? id,
    String? publisher,
    DateTime? date,
    ExamType? examType,
    Map<String, double>? subjectNets,
    String? note,
    DateTime? createdAt,
  }) {
    return MockExam(
      id: id ?? this.id,
      publisher: publisher ?? this.publisher,
      date: date ?? this.date,
      examType: examType ?? this.examType,
      subjectNets: subjectNets ?? this.subjectNets,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
