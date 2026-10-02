import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../domain/entities/service_log.dart';
import '../providers/service_log_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/labeled_field.dart';

class ServiceLogFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? id;

  const ServiceLogFormScreen({super.key, required this.vehicleId, this.id});

  @override
  ConsumerState<ServiceLogFormScreen> createState() => _ServiceLogFormScreenState();
}

class _ServiceLogFormScreenState extends ConsumerState<ServiceLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _mileageController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate);
    if (widget.id != null) {
      _loadServiceLog();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _mileageController.dispose();
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _mechanicController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceLog() async {
    final state = ref.read(serviceLogDetailProvider((widget.vehicleId, widget.id!)));
    if (state.serviceLog != null) {
      final serviceLog = state.serviceLog!;
      _selectedDate = serviceLog.date;
      _dateController.text = DateFormat('dd.MM.yyyy').format(serviceLog.date);
      _mileageController.text = serviceLog.mileage.toString();
      _serviceTypeController.text = serviceLog.serviceType;
      if (serviceLog.description != null) {
        _descriptionController.text = serviceLog.description!;
      }
      if (serviceLog.mechanic != null) {
        _mechanicController.text = serviceLog.mechanic!;
      }
      _totalCostController.text = serviceLog.totalCost.toString();
      if (serviceLog.notes != null) {
        _notesController.text = serviceLog.notes!;
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final serviceLog = ServiceLog(
        id: widget.id ?? '',
        vehicleId: widget.vehicleId,
        date: _selectedDate,
        mileage: int.parse(_mileageController.text.trim()),
        serviceType: _serviceTypeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        mechanic: _mechanicController.text.trim().isEmpty ? null : _mechanicController.text.trim(),
        totalCost: double.parse(_totalCostController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.id != null
            ? ref
                    .read(serviceLogDetailProvider((widget.vehicleId, widget.id!)))
                    .serviceLog
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
                .read(serviceLogDetailNotifierProvider((widget.vehicleId, widget.id!)))
                .updateServiceLog(serviceLog);
            final state = ref.read(serviceLogDetailProvider((widget.vehicleId, widget.id!)));
            if (state.status == ServiceLogDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          } else {
            await ref
                .read(serviceLogDetailNotifierProvider((widget.vehicleId, 'new')))
                .createServiceLog(serviceLog);
            final state = ref.read(serviceLogDetailProvider((widget.vehicleId, 'new')));
            if (state.status == ServiceLogDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          }
          if (mounted) {
            ref.read(serviceLogListProvider(widget.vehicleId).notifier).refresh();
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
    ref.listen<ServiceLogDetailState>(serviceLogDetailProvider((widget.vehicleId, providerKey)), (previous, next) {
      if (next.status == ServiceLogDetailStatus.error && next.errorMessage != null) {
        setState(() {
          _errorMessage = next.errorMessage;
          _isLoading = false;
        });
      } else if (next.status == ServiceLogDetailStatus.loaded && _isLoading) {
        if (mounted) {
          setState(() => _errorMessage = null);
          ref.read(serviceLogListProvider(widget.vehicleId).notifier).refresh();
          context.pop();
        }
      }
    });

    final isEdit = widget.id != null;

    return Scaffold(
      appBar: GarageAppBar(
        title: isEdit ? 'EDYTUJ WPIS' : 'NOWY WPIS',
        subtitle: 'FORM 02-A · KSIĄŻKA SERWISOWA',
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
                const FormSection(title: 'DATOWNIK', code: 'SEKCJA 1'),
                LabeledField(
                  label: 'DATA',
                  child: TextFormField(
                    controller: _dateController,
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
                ),
                LabeledField(
                  label: 'PRZEBIEG / KM',
                  child: TextFormField(
                    controller: _mileageController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. 18430'),
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
                const FormSection(title: 'ROBOTA', code: 'SEKCJA 2'),
                LabeledField(
                  label: 'CZYNNOŚĆ',
                  child: TextFormField(
                    controller: _serviceTypeController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. Wymiana oleju + filtr',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj typ serwisu';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'MECHANIK',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _mechanicController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. ASO, Warsztat przy ul....',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                LabeledField(
                  label: 'KOSZT / ZŁ',
                  child: TextFormField(
                    controller: _totalCostController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. 540.00'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj koszt';
                      }
                      final cost = double.tryParse(value.trim());
                      if (cost == null || cost < 0) {
                        return 'Podaj prawidłowy koszt';
                      }
                      return null;
                    },
                  ),
                ),
                const FormSection(title: 'SZCZEGÓŁY', code: 'SEKCJA 3'),
                LabeledField(
                  label: 'CZĘŚCI / ZAKRES',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _descriptionController,
                    style: AppText.body(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. SYN3 20W-50 · 3,4 L · filtr 63731-99A',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                ),
                LabeledField(
                  label: 'NOTATKI',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _notesController,
                    style: AppText.body(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. Lekki wyciek przy lewej pokrywie.',
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
                  label: isEdit ? 'ZAPISZ ZMIANY' : 'ZAPISZ WPIS',
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