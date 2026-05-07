import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task_enums.dart';
import '../providers/task_provider.dart';

/// Görev ekleme bottom sheet'i
class AddTaskBottomSheet extends ConsumerStatefulWidget {
  const AddTaskBottomSheet({
    super.key,
    this.initialDate,
  });

  final DateTime? initialDate;

  /// Bottom sheet'i göster
  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskBottomSheet(initialDate: initialDate),
    );
  }

  @override
  ConsumerState<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends ConsumerState<AddTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  TaskCategory _selectedCategory = TaskCategory.personal;
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(taskListProvider.notifier).addTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            priority: _selectedPriority,
            date: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task added successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  const SizedBox(height: 20),

                  // Başlık
                  Text(
                    'New Task',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Görev başlığı
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What do you need to do?',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Açıklama (opsiyonel)
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Additional details...',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarih seçimi
                  Text(
                    'Date',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('d MMMM yyyy, EEEE', 'en_US')
                                .format(_selectedDate),
                            style: textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kategori seçimi
                  Text(
                    'Category',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskCategory.values.map((category) {
                      final isSelected = category == _selectedCategory;
                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                        avatar: Icon(
                          category.icon,
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : category.color,
                        ),
                        label: Text(category.title),
                        selectedColor: category.color,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Öncelik seçimi
                  Text(
                    'Priority',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: TaskPriority.values.map((priority) {
                      final isSelected = priority == _selectedPriority;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: priority != TaskPriority.high ? 8 : 0,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedPriority = priority);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? priority.color.withAlpha(26)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? priority.color
                                      : colorScheme.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    priority.icon,
                                    color: isSelected
                                        ? priority.color
                                        : colorScheme.onSurfaceVariant,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    priority.title,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: isSelected
                                          ? priority.color
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Kaydet butonu
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


