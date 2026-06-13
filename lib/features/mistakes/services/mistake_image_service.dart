import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Yanlış sorunun fotoğrafını seçer (kamera/galeri) ve uygulamanın kalıcı
/// klasörüne kopyalar.
///
/// `image_picker` geçici (cache) bir dosya döner; OS bunu silebilir. Bu yüzden
/// resmi `ApplicationDocuments/mistake_images/` altına kopyalayıp o kalıcı yolu
/// döndürürüz. İptal/hata durumunda `null`. Burada AI/işleme YOK — sadece
/// görsel saklama (sıfır doğruluk riski).
Future<String?> pickMistakeImage(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 80,
  );
  if (picked == null) return null;

  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/mistake_images');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
  final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
  await File(picked.path).copy(dest);
  return dest;
}

/// Hata silinince ilişkili fotoğrafı diskten temizler (sessizce).
Future<void> deleteMistakeImage(String? path) async {
  if (path == null) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
