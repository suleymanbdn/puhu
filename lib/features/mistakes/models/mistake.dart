/// Hata Sepeti — tek bir hata kaydı.
///
/// Yanlış cevaplanan soruları kullanıcı buraya bir cümleyle ve isteğe bağlı
/// notla atar. Spaced repetition (aralıklı tekrar) algoritması ile bir
/// program belirlenir; kullanıcı tekrar gününde "Biliyorum" derse aralık
/// artar, "Yine yanlış" derse sıfırlanır.
///
/// Bu model build_runner kullanmaz — `toJson`/`fromJson` ile
/// SharedPreferences içinde JSON listesi olarak saklanır (küçük veri seti
/// için Hive setup overhead'inden kaçınmak adına).
class Mistake {
  const Mistake({
    required this.id,
    required this.subjectId,
    this.topicId,
    required this.title,
    this.note,
    required this.addedAt,
    this.lastReviewedAt,
    this.intervalIndex = 0,
    this.correctStreak = 0,
    this.wrongCount = 0,
    this.mastered = false,
  });

  /// Aralıklı tekrar günleri — interval index'e göre kaç gün sonra tekrar.
  ///
  /// Index 0: ilk eklendiğinde 1 gün sonra, "Biliyorum" dedikçe sıradakine
  /// geçer. Son aralığı geçenler `mastered=true` olur.
  static const intervals = <int>[1, 3, 7, 21, 60];

  /// Benzersiz kimlik.
  final String id;

  /// Hangi derse ait? (`Subject.id`)
  final String subjectId;

  /// Hangi konu? (opsiyonel — null ise ders bazlı genel hata)
  final String? topicId;

  /// Kullanıcının yazdığı kısa başlık (örn. "Trigonometri özdeşliği").
  final String title;

  /// Detay açıklama / hata notu (opsiyonel).
  final String? note;

  /// Hatanın sepete eklendiği zaman.
  final DateTime addedAt;

  /// Son tekrar zamanı (null = hiç tekrar edilmedi).
  final DateTime? lastReviewedAt;

  /// Şu anki aralık indeksi (`intervals` listesindeki yer).
  final int intervalIndex;

  /// Peşpeşe "Biliyorum" sayısı (mastery'ye yaklaşıyor).
  final int correctStreak;

  /// Toplam "Yine yanlış" sayısı (analiz için).
  final int wrongCount;

  /// Tüm aralıklar tamamlandı, öğrenildi olarak işaretlendi.
  final bool mastered;

  /// Bir sonraki tekrar tarihi (lastReviewedAt + interval gün).
  ///
  /// Eğer hiç tekrar edilmediyse: `addedAt + intervals[0]` gün.
  DateTime get nextReviewAt {
    final base = lastReviewedAt ?? addedAt;
    final days = intervalIndex < intervals.length
        ? intervals[intervalIndex]
        : intervals.last;
    return DateTime(base.year, base.month, base.day + days);
  }

  /// Bugün veya öncesinden bekliyor mu?
  bool get isPending {
    if (mastered) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !nextReviewAt.isAfter(today);
  }

  /// "Biliyorum" geçişi — bir sonraki aralığa atla. Eğer son aralıktaysa
  /// mastered olarak işaretle.
  Mistake markCorrect(DateTime now) {
    final nextIdx = intervalIndex + 1;
    if (nextIdx >= intervals.length) {
      return copyWith(
        lastReviewedAt: now,
        intervalIndex: intervals.length - 1,
        correctStreak: correctStreak + 1,
        mastered: true,
      );
    }
    return copyWith(
      lastReviewedAt: now,
      intervalIndex: nextIdx,
      correctStreak: correctStreak + 1,
    );
  }

  /// "Yine yanlış" geçişi — sıfırdan başla, wrong sayacını artır.
  Mistake markWrong(DateTime now) => copyWith(
        lastReviewedAt: now,
        intervalIndex: 0,
        correctStreak: 0,
        wrongCount: wrongCount + 1,
      );

  Mistake copyWith({
    String? title,
    String? note,
    DateTime? lastReviewedAt,
    int? intervalIndex,
    int? correctStreak,
    int? wrongCount,
    bool? mastered,
  }) =>
      Mistake(
        id: id,
        subjectId: subjectId,
        topicId: topicId,
        title: title ?? this.title,
        note: note ?? this.note,
        addedAt: addedAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        intervalIndex: intervalIndex ?? this.intervalIndex,
        correctStreak: correctStreak ?? this.correctStreak,
        wrongCount: wrongCount ?? this.wrongCount,
        mastered: mastered ?? this.mastered,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'topicId': topicId,
        'title': title,
        'note': note,
        'addedAt': addedAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
        'intervalIndex': intervalIndex,
        'correctStreak': correctStreak,
        'wrongCount': wrongCount,
        'mastered': mastered,
      };

  static Mistake fromJson(Map<String, dynamic> j) => Mistake(
        id: j['id'] as String,
        subjectId: j['subjectId'] as String,
        topicId: j['topicId'] as String?,
        title: j['title'] as String,
        note: j['note'] as String?,
        addedAt: DateTime.parse(j['addedAt'] as String),
        lastReviewedAt: j['lastReviewedAt'] == null
            ? null
            : DateTime.parse(j['lastReviewedAt'] as String),
        intervalIndex: j['intervalIndex'] as int? ?? 0,
        correctStreak: j['correctStreak'] as int? ?? 0,
        wrongCount: j['wrongCount'] as int? ?? 0,
        mastered: j['mastered'] as bool? ?? false,
      );
}
