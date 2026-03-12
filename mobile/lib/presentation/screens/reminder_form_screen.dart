import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? id;

  const ReminderFormScreen({super.key, required this.vehicleId, this.id});

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _dueMileageController = TextEditingController();
  final _notesController = TextEditingController();

  ReminderType _selectedType = ReminderType.date;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _typeController.text = _getTypeLabel(_selectedType);
    if (widget.id != null) {
      _loadReminder();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _dueDateController.dispose();
    _dueMileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadReminder() async {
    final state = ref.read(reminderDetailProvider((widget.vehicleId, widget.id!)));
    if (state.reminder != null) {
      final reminder = state.reminder!;
      _titleController.text = reminder.title;
      _selectedType = reminder.type;
      _typeController.text = _getTypeLabel(_selectedType);
      if (reminder.type == ReminderType.date && reminder.dueDate != null) {
        _selectedDueDate = reminder.dueDate;
        _dueDateController.text = DateFormat('dd.MM.yyyy').format(reminder.dueDate!);
      } else if (reminder.type == ReminderType.mileage && reminder.dueMileage != null) {
        _dueMileageController.text = reminder.dueMileage.toString();
      }
      if (reminder.notes != null) {
        _notesController.text = reminder.notes!;
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  String _getTypeLabel(ReminderType type) {
    return type == ReminderType.date ? 'Data' : 'Przebieg';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      DateTime? dueDate;
      int? dueMileage;

      if (_selectedType == ReminderType.date) {
        if (_selectedDueDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wybierz datę przypomnienia')),
          );
          return;
        }
        dueDate = _selectedDueDate;
      } else {
        if (_dueMileageController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Podaj przebieg przypomnienia')),
          );
          return;
        }
        dueMileage = int.parse(_dueMileageController.text.trim());
      }

      final reminder = Reminder(
        id: widget.id ?? '',
        vehicleId: widget.vehicleId,
        title: _titleController.text.trim(),
        type: _selectedType,
        dueDate: dueDate,
        dueMileage: dueMileage,
        isCompleted: widget.id != null
            ? ref
                    .read(reminderDetailProvider((widget.vehicleId, widget.id!)))
                    .reminder
                    ?.isCompleted ??
                false
            : false,
        completedAt: widget.id != null
            ? ref
                    .read(reminderDetailProvider((widget.vehicleId, widget.id!)))
                    .reminder
                    ?.completedAt
            : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.id != null
            ? ref
                    .read(reminderDetailProvider((widget.vehicleId, widget.id!)))
                    .reminder
                    ?.createdAt ??
                DateTime.now()
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() => _isLoading = true);

      Future(() async {
        try {
          if (widget.id != null) {
            await ref
                .read(reminderDetailNotifierProvider((widget.vehicleId, widget.id!)))
                .updateReminder(reminder);
          } else {
            await ref
                .read(reminderDetailNotifierProvider((widget.vehicleId, 'new')))
                .createReminder(reminder);
          }
          if (mounted) {
            context.pop();
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerKey = widget.id ?? 'new';
    ref.listen<ReminderDetailState>(reminderDetailProvider((widget.vehicleId, providerKey)), (previous, next) {
      if (next.status == ReminderDetailStatus.error && next.errorMessage != null) {
        setState(() {
          _errorMessage = next.errorMessage;
          _isLoading = false;
        });
      } else if (next.status == ReminderDetailStatus.loaded && _isLoading) {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
          context.pop();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id != null ? 'Edytuj przypomnienie' : 'Nowe przypomnienie'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tytuł',
                    prefixIcon: Icon(Icons.label),
                    hintText: 'np. Wymiana oleju',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj tytuł';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<ReminderType>(
                  segments: const [
                    ButtonSegment(
                      value: ReminderType.date,
                      label: Text('Data'),
                      icon: Icon(Icons.event),
                    ),
                    ButtonSegment(
                      value: ReminderType.mileage,
                      label: Text('Przebieg'),
                      icon: Icon(Icons.speed),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<ReminderType> selection) {
                    setState(() {
                      _selectedType = selection.first;
                      _typeController.text = _getTypeLabel(_selectedType);
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedType == ReminderType.date) ...[
                  TextFormField(
                    controller: _dueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Data przypomnienia',
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: 'dd.mm.rrrr',
                    ),
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Wybierz datę';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _dueMileageController,
                    decoration: const InputDecoration(
                      labelText: 'Przebieg (km)',
                      prefixIcon: Icon(Icons.speed),
                      hintText: 'np. 150000',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj przebieg';
                      }
                      final mileage = int.tryParse(value.trim());
                      if (mileage == null || mileage < 0) {
                        return 'Podaj prawidłowy przebieg';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notatki (opcjonalne)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'np. Przygotuj części zamienn wcześniej',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.id != null ? 'Zapisz zmiany' : 'Dodaj przypomnienie'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: const Text('Anuluj'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}