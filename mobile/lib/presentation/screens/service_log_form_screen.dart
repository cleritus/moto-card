import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_log.dart';
import '../providers/service_log_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id != null ? 'Edytuj serwis' : 'Nowy serwis'),
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
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Data',
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(
                    labelText: 'Przebieg (km)',
                    prefixIcon: Icon(Icons.speed),
                    hintText: 'np. 15000',
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serviceTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Typ serwisu',
                    prefixIcon: Icon(Icons.build),
                    hintText: 'np. Wymiana oleju, Naprawa hamulców',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj typ serwisu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mechanicController,
                  decoration: const InputDecoration(
                    labelText: 'Mechanik (opcjonalne)',
                    prefixIcon: Icon(Icons.person),
                    hintText: 'np. ASO, Warsztat przy ul....',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalCostController,
                  decoration: const InputDecoration(
                    labelText: 'Koszt (zł)',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'np. 350.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcjonalne)',
                    prefixIcon: Icon(Icons.description),
                    hintText: 'np. Wymiana oleju silnikowego i filtra oleju',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notatki (opcjonalne)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'np. Przegląd wykonany zgodnie z planem',
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
                      : Text(widget.id != null ? 'Zapisz zmiany' : 'Dodaj serwis'),
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