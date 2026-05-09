import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../models/mock_exam.dart';
import '../providers/mock_exam_provider.dart';

class MockExamView extends ConsumerWidget {
  const MockExamView({super.key});

  ExamTypeFilter _filter(ExamType t) {
    switch (t) {
      case ExamType.tyt:
        return ExamTypeFilter.tyt;
      case ExamType.sayisal:
        return ExamTypeFilter.sayisal;
      case ExamType.esitAgirlik:
        return ExamTypeFilter.esitAgirlik;
      case ExamType.sozel:
        return ExamTypeFilter.sozel;
      case ExamType.dil:
        return ExamTypeFilter.dil;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(examProfileProvider);
    final exams = ref.watch(mockExamProvider);
    final notifier = ref.read(mockExamProvider.notifier);

    if (profile == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Denemeler'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Özet
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Son Net',
                  value: notifier.lastNet?.toStringAsFixed(2) ?? '—',
                  color: colorScheme.primary,
                  icon: Icons.flag_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Ortalama',
                  value: exams.isEmpty
                      ? '—'
                      : notifier.averageNet.toStringAsFixed(2),
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.show_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Hedef',
                  value: profile.targetNet?.toStringAsFixed(0) ?? '—',
                  color: const Color(0xFF10B981),
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grafik
          if (exams.length >= 2) _NetChart(exams: exams, profile: profile),
          if (exams.length >= 2) const SizedBox(height: 20),

          Text('Geçmiş Denemeler',
              style: textTheme.titleSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          if (exams.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.assessment_outlined,
                      size: 56, color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Henüz deneme yok',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...exams.reversed.map((e) => _ExamTile(exam: e)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _AddMockSheet.show(
          context,
          examType: profile.examType,
          subjects: Subject.forExamType(_filter(profile.examType)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Deneme Ekle'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: textTheme.labelSmall?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _NetChart extends StatelessWidget {
  const _NetChart({required this.exams, required this.profile});
  final List<MockExam> exams;
  final ExamProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final spots = <FlSpot>[
      for (var i = 0; i < exams.length; i++)
        FlSpot(i.toDouble(), exams[i].totalNet),
    ];

    final maxNet = exams.map((e) => e.totalNet).fold<double>(
          profile.targetNet ?? 0,
          (a, b) => a > b ? a : b,
        );
    final yMax = (maxNet * 1.15).ceilToDouble().clamp(10, 600).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Net Gelişimi',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (profile.targetNet != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hedef: ${profile.targetNet!.toStringAsFixed(0)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.6,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: yMax,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} net\n${DateFormat('d MMM', 'tr_TR').format(exams[s.x.toInt()].date)}',
                            TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withAlpha(60),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (exams.length / 6).ceilToDouble().clamp(1, 999),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= exams.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d/M', 'tr_TR').format(exams[i].date),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: profile.targetNet != null
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: profile.targetNet!,
                            color: const Color(0xFF10B981),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: colorScheme.primary,
                        strokeColor: colorScheme.surface,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withAlpha(60),
                          colorScheme.primary.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamTile extends ConsumerWidget {
  const _ExamTile({required this.exam});
  final MockExam exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(exam.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) =>
            ref.read(mockExamProvider.notifier).delete(exam.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: exam.examType.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(exam.examType.icon,
                    color: exam.examType.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.publisher,
                        style: textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMMM yyyy', 'tr_TR').format(exam.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam.totalNet.toStringAsFixed(2),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMockSheet extends ConsumerStatefulWidget {
  const _AddMockSheet({required this.examType, required this.subjects});
  final ExamType examType;
  final List<Subject> subjects;

  static Future<void> show(BuildContext context,
      {required ExamType examType, required List<Subject> subjects}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddMockSheet(examType: examType, subjects: subjects),
    );
  }

  @override
  ConsumerState<_AddMockSheet> createState() => _AddMockSheetState();
}

class _AddMockSheetState extends ConsumerState<_AddMockSheet> {
  final _publisherController = TextEditingController();
  DateTime _date = DateTime.now();
  final Map<String, TextEditingController> _netControllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final s in widget.subjects) {
      _netControllers[s.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _publisherController.dispose();
    for (final c in _netControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalNet {
    return widget.subjects.fold<double>(0, (sum, s) {
      final raw = _netControllers[s.id]?.text.replaceAll(',', '.') ?? '';
      final n = double.tryParse(raw) ?? 0;
      return sum + n;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Yeni Deneme',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextField(
                controller: _publisherController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Yayın / Deneme Adı',
                  hintText: 'Örn: Karekök Deneme 5',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 7)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_date),
                          style: textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Ders Netleri',
                  style: textTheme.titleSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),

              ...widget.subjects.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: s.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(s.icon, color: s.color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Text(s.title,
                              style: textTheme.bodyMedium),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _netControllers[s.id],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            textAlign: TextAlign.right,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate_outlined,
                        color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('Toplam Net',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _totalNet.toStringAsFixed(2),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ||
                          _publisherController.text.trim().isEmpty ||
                          _totalNet == 0
                      ? null
                      : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final nets = <String, double>{};
    for (final s in widget.subjects) {
      final raw = _netControllers[s.id]!.text.replaceAll(',', '.');
      final n = double.tryParse(raw);
      if (n != null && n != 0) nets[s.id] = n;
    }

    try {
      await ref.read(mockExamProvider.notifier).add(
            publisher: _publisherController.text.trim(),
            date: _date,
            examType: widget.examType,
            subjectNets: nets,
          );
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }
}
