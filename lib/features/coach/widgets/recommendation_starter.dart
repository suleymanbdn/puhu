import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quick_log_sheet.dart';
import '../models/study_plan.dart';

/// Bugünkü öneriye basınca çalışma yolunu belirler.
///
/// Çalışma-dışı öneriler (hata tekrarı, ritmi koru) doğrudan hedefe gider.
/// Çalışma önerilerinde kullanıcıya SORAR — pomodoro dayatmaz: odaklanmak
/// isteyen sayacı başlatır, istemeyen doğrudan soru çözüp kaydeder.
void startRecommendation(BuildContext context, TodayRecommendation rec) {
  if (rec.kind == RecommendationKind.reviewMistakes ||
      rec.kind == RecommendationKind.maintain) {
    GoRouter.of(context).go(rec.actionRoute);
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      final textTheme = Theme.of(sheetCtx).textTheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                'Nasıl çalışmak istersin?',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: AppColors.focus),
              title: const Text('Pomodoro ile çalış'),
              subtitle: const Text('Odak sayacını başlat'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                GoRouter.of(context).go('/timer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded,
                  color: AppColors.quickAction),
              title: const Text('Pomodorosuz çalış'),
              subtitle: const Text('Çözdüğün soruları kaydet'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showQuickLogSheet(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
