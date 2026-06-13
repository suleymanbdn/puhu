import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Hata sepeti soru fotoğrafları için kalıcı görsel saklama.
///
/// **Önemli (iOS):** Uygulamanın sandbox klasörünün MUTLAK yolu yeniden kurulum
/// / migration'da değişebilir. Bu yüzden veritabanında mutlak yol DEĞİL, yalnızca
/// **dosya adı** saklanır; tam yol okuma anında [mistakeImagePath] ile yeniden
/// kurulur. Böylece kayıtlar reinstall'da kırılmaz. AI/işleme YOK — sadece
/// görsel saklama (sıfır doğruluk riski).
class MistakeImages {
  MistakeImages._();

  static String? _dirPath;

  /// Uygulama açılışında bir kez çağrılır (main). Görsel klasörünü hazırlar.
  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/mistake_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dirPath = dir.path;
  }

  /// Saklanan değerden (dosya adı VEYA eski mutlak yol) tam dosya yolu üretir.
  /// `null`/boşsa null. Eski kayıtlar mutlak yol içerebilir ('/' barındırır) →
  /// olduğu gibi döner (errorBuilder eksik dosyayı zaten yakalar).
  static String? mistakeImagePath(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (stored.contains('/')) return stored; // eski/mutlak yol
    if (_dirPath == null) return null;
    return '$_dirPath/$stored';
  }
}

/// Kamera/galeriden foto seçer, kalıcı klasöre kopyalar ve **dosya adını** döner
/// (mutlak yol değil — reinstall'a dayanıklı). İptal/hata → null.
Future<String?> pickMistakeImage(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 80,
  );
  if (picked == null) return null;

  if (MistakeImages._dirPath == null) {
    await MistakeImages.init();
  }
  final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
  final fileName = '${DateTime.now().microsecondsSinceEpoch}.$ext';
  final dest = '${MistakeImages._dirPath}/$fileName';
  await File(picked.path).copy(dest);
  return fileName;
}

/// Hata silinince ilişkili fotoğrafı diskten temizler (sessizce).
Future<void> deleteMistakeImage(String? stored) async {
  final path = MistakeImages.mistakeImagePath(stored);
  if (path == null) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
