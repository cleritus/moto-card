import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/labeled_field.dart';

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
  final _intervalKmController = TextEditingController();
  final _notesController = TextEditingController();

  ReminderType _selectedType = ReminderType.date;
  DateTime? _selectedDueDate;
  int? _lastDoneMileage;
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
    _intervalKmController.dispose();
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
      if (reminder.intervalKm != null) {
        _intervalKmController.text = reminder.intervalKm.toString();
      }
      _lastDoneMileage = reminder.lastDoneMileage;
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
      int? intervalKm;

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
        final intervalText = _intervalKmController.text.trim();
        if (intervalText.isNotEmpty) {
          intervalKm = int.parse(intervalText);
        }
      }

      final reminder = Reminder(
        id: widget.id ?? '',
        vehicleId: widget.vehicleId,
        title: _titleController.text.trim(),
        type: _selectedType,
        dueDate: dueDate,
        dueMileage: dueMileage,
        intervalKm: intervalKm,
        lastDoneMileage: _selectedType == ReminderType.mileage ? _lastDoneMileage : null,
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
            final state = ref.read(reminderDetailProvider((widget.vehicleId, widget.id!)));
            if (state.status == ReminderDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          } else {
            await ref
                .read(reminderDetailNotifierProvider((widget.vehicleId, 'new')))
                .createReminder(reminder);
            final state = ref.read(reminderDetailProvider((widget.vehicleId, 'new')));
            if (state.status == ReminderDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          }
          if (mounted) {
            ref.read(reminderListProvider((widget.vehicleId, ReminderFilter.active)).notifier).refresh();
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
      }
    });

    final isEdit = widget.id != null;

    return Scaffold(
      appBar: GarageAppBar(
        title: isEdit ? 'EDYTUJ ZLECENIE' : 'NOWE ZLECENIE',
        subtitle: 'FORM 04-A · TABLICA ALERTÓW',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppGeo.screenMargin,
            0,
            AppGeo.screenMargin,
            32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FormSection(title: 'ZLECENIE', code: 'SEKCJA 1'),
                LabeledField(
                  label: 'CZYNNOŚĆ',
                  child: TextFormField(
                    controller: _titleController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. Olej silnikowy',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj tytuł';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'WYZWALACZ',
                  child: SegmentedButton<ReminderType>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ReminderType.date,
                        label: Text('DATA'),
                      ),
                      ButtonSegment(
                        value: ReminderType.mileage,
                        label: Text('PRZEBIEG'),
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
                ),
                if (_selectedType == ReminderType.date)
                  LabeledField(
                    label: 'TERMIN',
                    child: TextFormField(
                      controller: _dueDateController,
                      style: AppText.data(size: 14.5),
                      decoration: const InputDecoration(hintText: 'dd.mm.rrrr'),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Wybierz datę';
                        }
                        return null;
                      },
                    ),
                  )
                else ...[
                  LabeledField(
                    label: 'PRZY PRZEBIEGU / KM',
                    child: TextFormField(
                      controller: _dueMileageController,
                      style: AppText.data(size: 14.5),
                      decoration: const InputDecoration(hintText: 'np. 24000'),
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
                  ),
                  LabeledField(
                    label: 'INTERWAŁ / KM',
                    hint: 'opcjonalne',
                    child: TextFormField(
                      controller: _intervalKmController,
                      style: AppText.data(size: 14.5),
                      decoration: const InputDecoration(hintText: 'np. 5000'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final interval = int.tryParse(value.trim());
                        if (interval == null || interval < 0) {
                          return 'Podaj prawidłowy interwał';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Interwał włącza pasek zużycia na ekranie pojazdu.',
                      style: AppText.body(
                        size: 13,
                        color: AppColors.fadedInk,
                      ),
                    ),
                  ),
                ],
                const FormSection(title: 'SZCZEGÓŁY', code: 'SEKCJA 2'),
                LabeledField(
                  label: 'NOTATKI',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _notesController,
                    style: AppText.body(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. Zamówić części wcześniej.',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null) ...[
                  FaultStrip(message: _errorMessage!),
                  const SizedBox(height: 20),
                ],
                GarageButton(
                  label: isEdit ? 'ZAPISZ ZMIANY' : 'POWIEŚ ZLECENIE',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
                const SizedBox(height: 14),
                GarageButton.ghost(
                  label: 'ANULUJ',
                  onPressed: _isLoading ? null : () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}